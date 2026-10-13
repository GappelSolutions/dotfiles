//! `2fa`: TOTP picker on top of cotp's encrypted database.
//!
//! cotp stays the store (`2fa add|edit|delete|...` pass straight through to it); this only replaces
//! its dashboard. The database password is cached in the kernel user keyring for `CACHE_SECS`, the
//! entries are read via `cotp export --otp-uri` into memory and the codes computed here.

use std::{
    io::{self, Write},
    process::{self, Command, Stdio},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use anyhow::{bail, Context, Result};
use crossterm::{
    event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers},
    execute,
    terminal::{disable_raw_mode, LeaveAlternateScreen},
};
use hmac::{digest::KeyInit, Hmac, Mac};
use ratatui::{
    layout::{Constraint, Layout, Rect},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{List, ListItem, ListState, Paragraph},
    DefaultTerminal, Frame,
};
use zeroize::Zeroizing;

const CACHE_SECS: u32 = 12 * 60 * 60;
const MAX_WIDTH: u16 = 72;
const ACCENT: Color = Color::Cyan;
const DIM: Color = Color::DarkGray;

// ── password cache (kernel user keyring via keyctl) ─────────────────────────────────────────────

fn keyctl(args: &[&str], input: Option<&[u8]>) -> Option<Vec<u8>> {
    let mut child = Command::new("keyctl")
        .args(args)
        .stdin(if input.is_some() {
            Stdio::piped()
        } else {
            Stdio::null()
        })
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;
    if let Some(input) = input {
        child.stdin.take()?.write_all(input).ok()?;
    }
    let out = child.wait_with_output().ok()?;
    out.status.success().then_some(out.stdout)
}

/// One cached password per database: "cotp", or "cotp:<path>" for a COTP_DB_PATH override.
fn key_name() -> String {
    match std::env::var("COTP_DB_PATH") {
        Ok(path) if !path.is_empty() => format!("cotp:{path}"),
        _ => "cotp".into(),
    }
}

fn cached_password() -> Option<Zeroizing<String>> {
    let id = keyctl(&["search", "@u", "user", &key_name()], None)?;
    let id = String::from_utf8(id).ok()?;
    let pw = keyctl(&["pipe", id.trim()], None)?;
    String::from_utf8(pw).ok().map(Zeroizing::new)
}

fn cache_password(pw: &str) {
    if let Some(id) = keyctl(&["padd", "user", &key_name(), "@u"], Some(pw.as_bytes())) {
        let id = String::from_utf8_lossy(&id);
        keyctl(&["timeout", id.trim(), &CACHE_SECS.to_string()], None);
    }
}

fn forget_password() {
    keyctl(&["purge", "user", &key_name()], None);
}

fn prompt_password() -> Result<Zeroizing<String>> {
    Ok(Zeroizing::new(rpassword::prompt_password(
        "cotp password: ",
    )?))
}

/// Runs cotp with the cached password (asking and caching it first if needed). A rejected
/// password is forgotten and asked again.
fn with_cotp<T>(run: impl Fn(&str) -> Result<Option<T>>) -> Result<T> {
    let mut cached = true;
    for _ in 0..3 {
        let pw = match cached.then(cached_password).flatten() {
            Some(pw) => pw,
            None => {
                cached = false;
                prompt_password()?
            }
        };
        if let Some(out) = run(&pw)? {
            if !cached {
                cache_password(&pw);
            }
            return Ok(out);
        }
        forget_password();
        if !cached {
            eprintln!("Wrong password");
        }
        cached = false;
    }
    bail!("giving up after 3 attempts")
}

fn cotp(pw: &str, args: &[String], capture: bool) -> Result<(i32, Vec<u8>)> {
    let mut child = Command::new("cotp")
        .arg("--password-stdin")
        .args(args)
        .stdin(Stdio::piped())
        .stdout(if capture {
            Stdio::piped()
        } else {
            Stdio::inherit()
        })
        .spawn()
        .context("running cotp")?;
    {
        let mut stdin = child.stdin.take().unwrap();
        stdin.write_all(pw.as_bytes())?;
        stdin.write_all(b"\n")?;
    }
    let out = child.wait_with_output()?;
    Ok((out.status.code().unwrap_or(1), out.stdout))
}

/// cotp exits 255 (-1) when the database can't be decrypted, before running any subcommand.
const COTP_BAD_PASSWORD: i32 = 255;

fn load_entries() -> Result<Vec<Entry>> {
    let json = with_cotp(|pw| {
        // export writes the JSON to --path, then "Successfully exported ..." to stdout; with both on
        // the same pipe only the first JSON value is the export.
        let args = ["export", "--otp-uri", "--path", "/dev/stdout"].map(String::from);
        let (code, out) = cotp(pw, &args, true)?;
        match code {
            0 => Ok(Some(Zeroizing::new(out))),
            COTP_BAD_PASSWORD => Ok(None),
            _ => Ok(Some(Zeroizing::new(Vec::new()))),
        }
    })?;

    #[derive(serde::Deserialize)]
    struct Export {
        items: Vec<String>,
    }
    let Some(Ok(export)) = serde_json::Deserializer::from_slice(&json)
        .into_iter::<Export>()
        .next()
    else {
        // "No contents to export" -- an empty database
        return Ok(Vec::new());
    };
    Ok(export
        .items
        .iter()
        .filter_map(|uri| Entry::parse(uri))
        .collect())
}

// ── OTP ─────────────────────────────────────────────────────────────────────────────────────────

#[derive(Clone, Copy)]
enum Algorithm {
    Sha1,
    Sha256,
    Sha512,
}

struct Entry {
    issuer: String,
    label: String,
    secret: Zeroizing<Vec<u8>>,
    algorithm: Algorithm,
    digits: u32,
    period: u64,
    /// Not TOTP (HOTP, Steam, Yandex, MOTP): listed, but left to cotp.
    unsupported: Option<String>,
}

impl Entry {
    fn parse(uri: &str) -> Option<Self> {
        let url = url::Url::parse(uri).ok()?;
        let kind = url.host_str().unwrap_or_default().to_lowercase();
        let path = url.path().trim_start_matches('/');
        let name = percent_decode(path);
        let (issuer, label) = match name.split_once(':') {
            Some((i, l)) => (i.trim().to_string(), l.trim().to_string()),
            None => (String::new(), name.trim().to_string()),
        };
        let query = |k: &str| {
            url.query_pairs()
                .find(|(q, _)| q == k)
                .map(|(_, v)| v.into_owned())
        };
        let secret = query("secret")
            .unwrap_or_default()
            .to_uppercase()
            .replace([' ', '='], "");
        let secret = data_encoding::BASE32_NOPAD.decode(secret.as_bytes()).ok()?;
        let algorithm = match query("algorithm")
            .as_deref()
            .map(str::to_uppercase)
            .as_deref()
        {
            Some("SHA256") => Algorithm::Sha256,
            Some("SHA512") => Algorithm::Sha512,
            _ => Algorithm::Sha1,
        };
        Some(Entry {
            issuer,
            label,
            secret: Zeroizing::new(secret),
            algorithm,
            digits: query("digits").and_then(|d| d.parse().ok()).unwrap_or(6),
            period: query("period")
                .and_then(|p| p.parse().ok())
                .filter(|&p| p > 0)
                .unwrap_or(30),
            unsupported: (kind != "totp").then_some(kind),
        })
    }

    fn code_at(&self, unix: u64) -> String {
        let msg = (unix / self.period).to_be_bytes();
        let mac = match self.algorithm {
            Algorithm::Sha1 => hmac::<Hmac<sha1::Sha1>>(&self.secret, &msg),
            Algorithm::Sha256 => hmac::<Hmac<sha2::Sha256>>(&self.secret, &msg),
            Algorithm::Sha512 => hmac::<Hmac<sha2::Sha512>>(&self.secret, &msg),
        };
        let off = (mac[mac.len() - 1] & 0x0f) as usize;
        let bin = u32::from_be_bytes([mac[off] & 0x7f, mac[off + 1], mac[off + 2], mac[off + 3]]);
        let code = bin as u64 % 10u64.pow(self.digits);
        format!("{code:0width$}", width = self.digits as usize)
    }

    fn remaining(&self, unix: u64) -> u64 {
        self.period - unix % self.period
    }

    fn matches(&self, query: &str) -> bool {
        let q = query.to_lowercase();
        self.label.to_lowercase().contains(&q) || self.issuer.to_lowercase().contains(&q)
    }

    fn name(&self) -> &str {
        if self.label.is_empty() {
            &self.issuer
        } else {
            &self.label
        }
    }
}

fn hmac<M: Mac + KeyInit>(key: &[u8], msg: &[u8]) -> Vec<u8> {
    let mut mac = <M as Mac>::new_from_slice(key).expect("HMAC takes any key length");
    mac.update(msg);
    mac.finalize().into_bytes().to_vec()
}

fn percent_decode(s: &str) -> String {
    url::form_urlencoded::parse(format!("x={s}").as_bytes())
        .next()
        .map(|(_, v)| v.into_owned())
        .unwrap_or_default()
}

/// "479918" -> "479 918", "12345678" -> "1234 5678"
fn group(code: &str) -> String {
    let mid = code.len() / 2;
    format!("{} {}", &code[..mid], &code[mid..])
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

// ── clipboard ───────────────────────────────────────────────────────────────────────────────────

/// zellij-copy (nix/scripts) knows every host's clipboard; OSC 52 covers SSH and headless hosts.
fn copy(text: &str) {
    let piped = Command::new("zellij-copy")
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .and_then(|mut child| {
            child.stdin.take().unwrap().write_all(text.as_bytes())?;
            child.wait()
        })
        .map(|status| status.success())
        .unwrap_or(false);
    if !piped {
        let b64 = data_encoding::BASE64.encode(text.as_bytes());
        let _ = write!(io::stdout(), "\x1b]52;c;{b64}\x07");
        let _ = io::stdout().flush();
    }
}

// ── TUI ─────────────────────────────────────────────────────────────────────────────────────────

struct App {
    entries: Vec<Entry>,
    query: String,
    searching: bool,
    list: ListState,
    toast: Option<(String, Instant)>,
}

impl App {
    fn visible(&self) -> Vec<usize> {
        (0..self.entries.len())
            .filter(|&i| self.entries[i].matches(&self.query))
            .collect()
    }

    fn selected(&self) -> Option<usize> {
        let visible = self.visible();
        visible
            .get(self.list.selected().unwrap_or(0))
            .copied()
            .or(visible.first().copied())
    }

    fn clamp(&mut self) {
        let n = self.visible().len();
        let sel = self.list.selected().unwrap_or(0).min(n.saturating_sub(1));
        self.list.select((n > 0).then_some(sel));
    }

    fn move_by(&mut self, delta: isize) {
        let n = self.visible().len() as isize;
        if n == 0 {
            return;
        }
        let sel = self.list.selected().unwrap_or(0) as isize;
        self.list.select(Some((sel + delta).rem_euclid(n) as usize));
    }

    fn copy_selected(&mut self) {
        if let Some(i) = self.selected() {
            let e = &self.entries[i];
            if e.unsupported.is_none() {
                copy(&e.code_at(now()));
                self.toast = Some((format!("copied {}", e.name()), Instant::now()));
            }
        }
    }

    /// Handles one key press; true quits. Only `q` (and Ctrl-C) quit, nothing else does.
    fn key(&mut self, key: KeyEvent) -> bool {
        let ctrl = key.modifiers.contains(KeyModifiers::CONTROL);
        if ctrl && key.code == KeyCode::Char('c') {
            return true;
        }
        if self.searching {
            match key.code {
                KeyCode::Esc => {
                    self.searching = false;
                    self.query.clear();
                }
                KeyCode::Enter => self.copy_selected(),
                KeyCode::Backspace => {
                    if self.query.pop().is_none() {
                        self.searching = false;
                    }
                }
                KeyCode::Up => self.move_by(-1),
                KeyCode::Down | KeyCode::Tab => self.move_by(1),
                KeyCode::Char('n' | 'j') if ctrl => self.move_by(1),
                KeyCode::Char('p' | 'k') if ctrl => self.move_by(-1),
                KeyCode::Char(c) => {
                    self.query.push(c);
                    self.list.select(Some(0));
                }
                _ => {}
            }
            self.clamp();
            return false;
        }
        match key.code {
            KeyCode::Char('q') => return true,
            KeyCode::Char('j') | KeyCode::Down | KeyCode::Tab => self.move_by(1),
            KeyCode::Char('k') | KeyCode::Up | KeyCode::BackTab => self.move_by(-1),
            KeyCode::Char('g') | KeyCode::Home => self.list.select(Some(0)),
            KeyCode::Char('G') | KeyCode::End => self
                .list
                .select(Some(self.visible().len().saturating_sub(1))),
            KeyCode::Char('/') => self.searching = true,
            KeyCode::Char('f') if ctrl => self.searching = true,
            KeyCode::Enter | KeyCode::Char('y' | ' ') => self.copy_selected(),
            KeyCode::Char(c @ '1'..='9') => {
                let row = c as usize - '1' as usize;
                if row < self.visible().len() {
                    self.list.select(Some(row));
                    self.copy_selected();
                }
            }
            _ => {}
        }
        false
    }
}

fn countdown_color(remaining: u64) -> Color {
    match remaining {
        0..=5 => Color::Red,
        6..=10 => Color::Yellow,
        _ => ACCENT,
    }
}

fn draw(frame: &mut Frame, app: &mut App) {
    let t = now();
    let area = frame.area();
    let width = area.width.min(MAX_WIDTH);
    let area = Rect {
        x: area.x + (area.width - width) / 2,
        width,
        ..area
    }
    .inner(ratatui::layout::Margin::new(2, 1));

    let [header, bar, _, list, _, footer] = Layout::vertical([
        Constraint::Length(1),
        Constraint::Length(1),
        Constraint::Length(1),
        Constraint::Min(1),
        Constraint::Length(1),
        Constraint::Length(1),
    ])
    .areas(area);

    let visible = app.visible();
    let current = app.selected().map(|i| &app.entries[i]);
    let period = current.map_or(30, |e| e.period);
    let remaining = period - t % period;
    let color = countdown_color(remaining);

    // header: title (or search field) left, countdown right
    let title = if app.searching || !app.query.is_empty() {
        Line::from(vec![
            Span::styled("/ ", Style::new().fg(ACCENT)),
            Span::raw(app.query.clone()),
            Span::styled(
                if app.searching { "▏" } else { "" },
                Style::new().fg(ACCENT),
            ),
        ])
    } else {
        Line::from(vec![Span::styled("2fa", Style::new().fg(ACCENT).bold())])
    };
    frame.render_widget(Paragraph::new(title), header);
    frame.render_widget(
        Paragraph::new(Span::styled(
            format!("{remaining:>2}s"),
            Style::new().fg(color).bold(),
        ))
        .right_aligned(),
        header,
    );

    // thin countdown bar
    let w = bar.width as u64;
    let filled = (w * remaining).div_ceil(period) as usize;
    frame.render_widget(
        Paragraph::new(Line::from(vec![
            Span::styled("━".repeat(filled), Style::new().fg(color)),
            Span::styled("─".repeat(w as usize - filled), Style::new().fg(DIM)),
        ])),
        bar,
    );

    // entries
    let items: Vec<ListItem> = if visible.is_empty() {
        let msg = if app.entries.is_empty() {
            "no codes yet: 2fa add -l <label>"
        } else {
            "no match"
        };
        vec![ListItem::new(Span::styled(
            format!("  {msg}"),
            Style::new().fg(DIM),
        ))]
    } else {
        let sel = app.list.selected();
        visible
            .iter()
            .enumerate()
            .map(|(row, &i)| {
                let e = &app.entries[i];
                let selected = sel == Some(row);
                let num = if row < 9 {
                    format!("{} ", row + 1)
                } else {
                    "  ".into()
                };
                let mut left = vec![
                    Span::styled(if selected { "▌ " } else { "  " }, Style::new().fg(ACCENT)),
                    Span::styled(num, Style::new().fg(DIM)),
                    Span::styled(
                        e.name().to_string(),
                        if selected {
                            Style::new().bold()
                        } else {
                            Style::new()
                        },
                    ),
                ];
                if !e.issuer.is_empty() && !e.label.is_empty() {
                    left.push(Span::styled(
                        format!("  {}", e.issuer),
                        Style::new().fg(DIM),
                    ));
                }
                let right: Vec<Span> = match &e.unsupported {
                    Some(kind) => vec![Span::styled(
                        format!("{kind}: use cotp"),
                        Style::new().fg(DIM),
                    )],
                    None => {
                        let rem = e.remaining(t);
                        let code_style = Style::new().fg(if selected {
                            countdown_color(rem)
                        } else {
                            Color::Reset
                        });
                        let mut spans = Vec::new();
                        if rem <= 5 {
                            spans.push(Span::styled(
                                format!("{} → ", group(&e.code_at(t + rem))),
                                Style::new().fg(DIM),
                            ));
                        }
                        spans.push(Span::styled(
                            group(&e.code_at(t)),
                            code_style.add_modifier(Modifier::BOLD),
                        ));
                        if e.period != period {
                            spans.push(Span::styled(format!(" {rem:>2}s"), Style::new().fg(DIM)));
                        }
                        spans
                    }
                };
                let used: usize = left.iter().chain(&right).map(|s| s.width()).sum();
                let pad = (list.width as usize).saturating_sub(used + 1);
                left.push(Span::raw(" ".repeat(pad)));
                left.extend(right);
                ListItem::new(Line::from(left))
            })
            .collect()
    };
    frame.render_stateful_widget(List::new(items), list, &mut app.list);

    // footer: toast or key hints
    let toast = app
        .toast
        .as_ref()
        .filter(|(_, at)| at.elapsed() < Duration::from_millis(1500));
    let footer_line = match toast {
        Some((msg, _)) => Line::from(Span::styled(
            format!("✓ {msg}"),
            Style::new().fg(Color::Green),
        )),
        None => {
            let hint = |k: &'static str, d: &'static str| {
                [
                    Span::styled(k, Style::new().fg(ACCENT)),
                    Span::styled(format!(" {d}   "), Style::new().fg(DIM)),
                ]
            };
            let hints = if app.searching {
                [hint("⏎", "copy"), hint("↑↓", "move"), hint("esc", "clear")].concat()
            } else {
                [
                    hint("⏎/1-9", "copy"),
                    hint("/", "search"),
                    hint("q", "quit"),
                ]
                .concat()
            };
            Line::from(hints)
        }
    };
    frame.render_widget(Paragraph::new(footer_line), footer);
}

fn run_tui(terminal: &mut DefaultTerminal, app: &mut App) -> Result<()> {
    loop {
        terminal.draw(|f| draw(f, app))?;
        if !event::poll(Duration::from_millis(250))? {
            continue;
        }
        if let Event::Key(key) = event::read()? {
            if key.kind != KeyEventKind::Press {
                continue;
            }
            if app.key(key) {
                return Ok(());
            }
        }
    }
}

fn tui() -> Result<()> {
    let entries = load_entries()?;
    let mut app = App {
        entries,
        query: String::new(),
        searching: false,
        list: ListState::default(),
        toast: None,
    };
    app.clamp();

    let mut terminal = ratatui::init();
    let result = run_tui(&mut terminal, &mut app);
    ratatui::restore();
    result
}

/// `2fa <cotp subcommand ...>`: cotp with the cached password.
fn passthrough(args: &[String]) -> Result<i32> {
    with_cotp(|pw| {
        let (code, _) = cotp(pw, args, false)?;
        Ok((code != COTP_BAD_PASSWORD).then_some(code))
    })
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let result = match args.first().map(String::as_str) {
        None => tui().map(|()| 0),
        Some("-h" | "--help") => {
            println!(
                "2fa            pick a code (⏎ / 1-9 copy, / search, q quit)\n\
                 2fa lock       forget the cached password\n\
                 2fa <args>     cotp <args> with the cached password (add, edit, delete, list, ...)"
            );
            Ok(0)
        }
        Some("lock") => {
            forget_password();
            Ok(0)
        }
        Some(_) => passthrough(&args),
    };
    match result {
        Ok(code) => process::exit(code),
        Err(e) => {
            // keep the terminal usable if we died inside the TUI
            let _ = disable_raw_mode();
            let _ = execute!(io::stdout(), LeaveAlternateScreen);
            eprintln!("2fa: {e:#}");
            process::exit(1);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // RFC 6238 appendix B, SHA1 seed "12345678901234567890"
    #[test]
    fn rfc6238() {
        let e = Entry::parse("otpauth://totp/x?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&digits=8")
            .unwrap();
        assert_eq!(e.code_at(59), "94287082");
        assert_eq!(e.code_at(1111111109), "07081804");
        assert_eq!(e.code_at(20000000000), "65353130");
    }

    #[test]
    fn label_and_issuer() {
        let e =
            Entry::parse("otpauth://totp/ACME%20Co:me%40x.com?secret=JBSWY3DPEHPK3PXP").unwrap();
        assert_eq!(
            (e.issuer.as_str(), e.label.as_str()),
            ("ACME Co", "me@x.com")
        );
        let e = Entry::parse("otpauth://totp/dev?secret=jbsw%20y3dp%20ehpk%203pxp").unwrap();
        assert_eq!((e.issuer.as_str(), e.label.as_str()), ("", "dev"));
    }
}
