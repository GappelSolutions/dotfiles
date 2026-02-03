use anyhow::{Context, Result};
use chrono::Local;
use clap::Parser;
use crossterm::{
    event::{self, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use fuzzy_matcher::FuzzyMatcher;
use fuzzy_matcher::skim::SkimMatcherV2;
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Frame, Terminal,
};
use std::io;
use std::process::Command;

#[derive(Parser, Debug)]
#[command(name = "zellij-welcome")]
#[command(about = "Beautiful Zellij session picker", long_about = None)]
struct Args {
    /// Minimal mode (compact session picker)
    #[arg(short, long)]
    minimal: bool,
}

struct Session {
    name: String,
    description: String,
}

impl Session {
    fn new(name: impl Into<String>, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
        }
    }
}

struct App {
    sessions: Vec<Session>,
    selected: usize,
    minimal: bool,
    search_query: String,
    filtered_indices: Vec<usize>,
}

impl App {
    fn new(minimal: bool) -> Self {
        let sessions = vec![
            Session::new("energyboard", "Energy management portal"),
            Session::new("backoffice", "Admin backend systems"),
            Session::new("easyasset", "Asset tracking platform"),
            Session::new("elixir", "Elixir projects"),
            Session::new("gappel-solutions", "Company solutions"),
            Session::new("decon", "Decon project"),
            Session::new("screensaver", "Screensaver development"),
            Session::new("lazychat", "Lazychat TUI for Claude sessions"),
            Session::new("new", "Start a new session"),
            Session::new("welcome", "Return to this screen"),
        ];

        let filtered_indices: Vec<usize> = (0..sessions.len()).collect();

        Self {
            sessions,
            selected: 0,
            minimal,
            search_query: String::new(),
            filtered_indices,
        }
    }

    fn next(&mut self) {
        if !self.filtered_indices.is_empty() {
            self.selected = (self.selected + 1) % self.filtered_indices.len();
        }
    }

    fn previous(&mut self) {
        if !self.filtered_indices.is_empty() {
            if self.selected > 0 {
                self.selected -= 1;
            } else {
                self.selected = self.filtered_indices.len() - 1;
            }
        }
    }

    fn get_selected_session(&self) -> &str {
        if !self.filtered_indices.is_empty() {
            let actual_idx = self.filtered_indices[self.selected];
            &self.sessions[actual_idx].name
        } else {
            ""
        }
    }

    fn update_search(&mut self, query: String) {
        self.search_query = query;
        self.update_filtered_indices();
        self.selected = 0;
    }

    fn update_filtered_indices(&mut self) {
        if self.search_query.is_empty() {
            self.filtered_indices = (0..self.sessions.len()).collect();
        } else {
            let matcher = SkimMatcherV2::default();
            let mut matches: Vec<(usize, i64)> = self.sessions
                .iter()
                .enumerate()
                .filter_map(|(i, session)| {
                    matcher.fuzzy_match(&session.name, &self.search_query)
                        .map(|score| (i, score))
                })
                .collect();

            // Sort by score (highest first)
            matches.sort_by(|a, b| b.1.cmp(&a.1));

            self.filtered_indices = matches.into_iter().map(|(i, _)| i).collect();
        }
    }
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Clean up old sessions first
    cleanup_old_sessions()?;

    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app and run
    let mut app = App::new(args.minimal);
    let result = run_app(&mut terminal, &mut app);

    // Restore terminal
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    // Handle the result
    if let Ok(Some(session)) = result {
        launch_session(&session)?;
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> Result<Option<String>> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                match key.code {
                    KeyCode::Char('q') => {
                        if app.search_query.is_empty() {
                            return Ok(None);
                        } else {
                            // 'q' in search mode is just a letter
                            let mut new_query = app.search_query.clone();
                            new_query.push('q');
                            app.update_search(new_query);
                        }
                    }
                    KeyCode::Esc => {
                        if app.search_query.is_empty() {
                            return Ok(None);
                        } else {
                            // Clear search
                            app.update_search(String::new());
                        }
                    }
                    KeyCode::Char('j') | KeyCode::Down => app.next(),
                    KeyCode::Char('k') | KeyCode::Up => app.previous(),
                    KeyCode::Enter => {
                        let session = app.get_selected_session().to_string();
                        if !session.is_empty() {
                            return Ok(Some(session));
                        }
                    }
                    KeyCode::Backspace => {
                        if !app.search_query.is_empty() {
                            let mut new_query = app.search_query.clone();
                            new_query.pop();
                            app.update_search(new_query);
                        }
                    }
                    KeyCode::Char(c) => {
                        if c != 'j' && c != 'k' {
                            let mut new_query = app.search_query.clone();
                            new_query.push(c);
                            app.update_search(new_query);
                        }
                    }
                    _ => {}
                }
            }
        }
    }
}

fn ui(f: &mut Frame, app: &App) {
    let size = f.area();

    if app.minimal {
        render_minimal_ui(f, app, size);
    } else {
        render_full_ui(f, app, size);
    }
}

fn render_minimal_ui(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Search input
            Constraint::Min(1),     // Session list
            Constraint::Length(3),  // Footer
        ])
        .split(area);

    // Search input
    let search_text = if app.search_query.is_empty() {
        Line::from(vec![
            Span::styled("> ", Style::default().fg(Color::Blue)),
            Span::styled("Type to search...", Style::default().fg(Color::DarkGray)),
        ])
    } else {
        Line::from(vec![
            Span::styled("> ", Style::default().fg(Color::Blue)),
            Span::styled(&app.search_query, Style::default().fg(Color::White)),
        ])
    };

    let search_widget = Paragraph::new(search_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Blue))
                .title(" Search ")
                .title_style(Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)),
        );

    f.render_widget(search_widget, chunks[0]);

    // Session list (filtered)
    let items: Vec<ListItem> = app
        .filtered_indices
        .iter()
        .enumerate()
        .map(|(display_idx, &actual_idx)| {
            let s = &app.sessions[actual_idx];
            let style = if display_idx == app.selected {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Blue)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::White)
            };

            let content = format!("  {}  {}", s.name, s.description);
            ListItem::new(content).style(style)
        })
        .collect();

    let list = List::new(items).block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::DarkGray))
            .title(format!(" Zellij Sessions ({}/{}) ", app.filtered_indices.len(), app.sessions.len()))
            .title_style(Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)),
    );

    f.render_widget(list, chunks[1]);

    // Footer
    let footer = Paragraph::new("j/k: navigate • Enter: select • Esc: clear search • q: quit")
        .style(Style::default().fg(Color::DarkGray))
        .alignment(Alignment::Center)
        .block(Block::default().borders(Borders::TOP));

    f.render_widget(footer, chunks[2]);
}

fn render_full_ui(f: &mut Frame, app: &App, area: Rect) {
    let height = area.height;

    // Calculate dynamic heights
    let session_count = app.filtered_indices.len() as u16;
    let session_list_height = session_count + 2; // +2 for borders

    // Responsive layout based on terminal height
    if height >= 40 {
        render_full_ui_tall(f, app, area, session_list_height);
    } else {
        render_full_ui_short(f, app, area, session_list_height);
    }
}

fn render_full_ui_tall(f: &mut Frame, app: &App, area: Rect, session_list_height: u16) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),                    // Top padding
            Constraint::Length(6),                    // Logo
            Constraint::Length(1),                    // Spacing
            Constraint::Length(2),                    // Time/Date
            Constraint::Length(1),                    // Spacing
            Constraint::Length(3),                    // Search input with box
            Constraint::Length(1),                    // Spacing
            Constraint::Length(session_list_height), // Session list (dynamic)
            Constraint::Min(1),                       // Flexible space
            Constraint::Length(1),                    // Quote
            Constraint::Length(1),                    // Spacing
            Constraint::Length(1),                    // Help line
        ])
        .split(area);

    // ASCII Art Header - official Zellij logo
    let header = vec![
        "███████╗███████╗██╗     ██╗     ██╗     ██╗",
        "╚══███╔╝██╔════╝██║     ██║     ██║     ██║",
        "  ███╔╝ █████╗  ██║     ██║     ██║     ██║",
        " ███╔╝  ██╔══╝  ██║     ██║     ██║██   ██║",
        "███████╗███████╗███████╗███████╗██║╚█████╔╝",
        "╚══════╝╚══════╝╚══════╝╚══════╝╚═╝ ╚════╝ ",
    ];

    let header_text: Vec<Line> = header
        .iter()
        .map(|&line| Line::from(Span::styled(line, Style::default().fg(Color::Blue))))
        .collect();

    let header_widget = Paragraph::new(header_text).alignment(Alignment::Center);
    f.render_widget(header_widget, chunks[1]);

    // Time and Date
    let now = Local::now();
    let time_str = now.format("%H:%M:%S").to_string();
    let date_str = now.format("%A, %B %d, %Y").to_string();

    let time_date = Paragraph::new(vec![
        Line::from(vec![Span::styled(
            time_str,
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )]),
        Line::from(vec![Span::styled(
            date_str,
            Style::default().fg(Color::DarkGray),
        )]),
    ])
    .alignment(Alignment::Center);

    f.render_widget(time_date, chunks[3]);

    // Search input with box
    let search_text = if app.search_query.is_empty() {
        Line::from(vec![
            Span::styled(" Type to search...", Style::default().fg(Color::DarkGray)),
        ])
    } else {
        Line::from(vec![
            Span::styled(" ", Style::default()),
            Span::styled(&app.search_query, Style::default().fg(Color::White)),
            Span::styled("_", Style::default().fg(Color::Blue).add_modifier(Modifier::SLOW_BLINK)),
        ])
    };

    let search_widget = Paragraph::new(search_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::DarkGray))
                .title(" Search ")
                .title_style(Style::default().fg(Color::Blue)),
        );

    f.render_widget(search_widget, chunks[5]);

    // Session List (filtered)
    let items: Vec<ListItem> = app
        .filtered_indices
        .iter()
        .enumerate()
        .map(|(display_idx, &actual_idx)| {
            let s = &app.sessions[actual_idx];
            let (prefix, style) = if display_idx == app.selected {
                (
                    "▶ ",
                    Style::default()
                        .fg(Color::Black)
                        .bg(Color::Blue)
                        .add_modifier(Modifier::BOLD),
                )
            } else {
                (
                    "  ",
                    Style::default().fg(Color::White),
                )
            };

            let name_style = if display_idx == app.selected {
                style
            } else {
                Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)
            };

            let desc_style = if display_idx == app.selected {
                style
            } else {
                Style::default().fg(Color::DarkGray)
            };

            let line = Line::from(vec![
                Span::styled(prefix, style),
                Span::styled(format!("{:<20}", s.name), name_style),
                Span::styled(format!(" {}", s.description), desc_style),
            ]);

            ListItem::new(line).style(style)
        })
        .collect();

    let list = List::new(items).block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Blue))
            .title(format!(" Select a Session ({}/{}) ", app.filtered_indices.len(), app.sessions.len()))
            .title_style(Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)),
    );

    f.render_widget(list, chunks[7]);

    // Quote
    let quotes = [
        "The best time to plant a tree was 20 years ago. The second best time is now.",
        "Code is like humor. When you have to explain it, it's bad.",
        "First, solve the problem. Then, write the code.",
        "Make it work, make it right, make it fast.",
        "Simplicity is the soul of efficiency.",
    ];
    // Use a simple hash of the current minute to pick a quote (changes every minute)
    let quote_idx = (Local::now().timestamp() / 60) as usize % quotes.len();
    let quote = quotes[quote_idx];

    let quote_widget = Paragraph::new(Line::from(vec![
        Span::styled("« ", Style::default().fg(Color::DarkGray)),
        Span::styled(quote, Style::default().fg(Color::Magenta).add_modifier(Modifier::ITALIC)),
        Span::styled(" »", Style::default().fg(Color::DarkGray)),
    ]))
    .alignment(Alignment::Center);

    f.render_widget(quote_widget, chunks[9]);

    // Help line
    let footer = Paragraph::new(Line::from(vec![
        Span::styled("↑↓", Style::default().fg(Color::DarkGray)),
        Span::styled(" navigate  ", Style::default().fg(Color::DarkGray)),
        Span::styled("⏎", Style::default().fg(Color::Blue)),
        Span::styled(" select  ", Style::default().fg(Color::DarkGray)),
        Span::styled("esc", Style::default().fg(Color::DarkGray)),
        Span::styled(" clear  ", Style::default().fg(Color::DarkGray)),
        Span::styled("q", Style::default().fg(Color::DarkGray)),
        Span::styled(" quit", Style::default().fg(Color::DarkGray)),
    ]))
    .alignment(Alignment::Center);

    f.render_widget(footer, chunks[11]);
}

fn render_full_ui_short(f: &mut Frame, app: &App, area: Rect, session_list_height: u16) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),                    // Top padding
            Constraint::Length(2),                    // Time/Date
            Constraint::Length(1),                    // Spacing
            Constraint::Length(3),                    // Search input with box
            Constraint::Length(session_list_height), // Session list (dynamic)
            Constraint::Min(0),                       // Remaining space
        ])
        .split(area);

    // Time and Date
    let now = Local::now();
    let time_str = now.format("%H:%M:%S").to_string();
    let date_str = now.format("%A, %B %d, %Y").to_string();

    let time_date = Paragraph::new(vec![
        Line::from(vec![Span::styled(
            time_str,
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )]),
        Line::from(vec![Span::styled(
            date_str,
            Style::default().fg(Color::DarkGray),
        )]),
    ])
    .alignment(Alignment::Center);

    f.render_widget(time_date, chunks[1]);

    // Search input with box
    let search_text = if app.search_query.is_empty() {
        Line::from(vec![
            Span::styled(" Type to search...", Style::default().fg(Color::DarkGray)),
        ])
    } else {
        Line::from(vec![
            Span::styled(" ", Style::default()),
            Span::styled(&app.search_query, Style::default().fg(Color::White)),
            Span::styled("_", Style::default().fg(Color::Blue).add_modifier(Modifier::SLOW_BLINK)),
        ])
    };

    let search_widget = Paragraph::new(search_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::DarkGray))
                .title(" Search ")
                .title_style(Style::default().fg(Color::Blue)),
        );

    f.render_widget(search_widget, chunks[3]);

    // Session List (filtered)
    let items: Vec<ListItem> = app
        .filtered_indices
        .iter()
        .enumerate()
        .map(|(display_idx, &actual_idx)| {
            let s = &app.sessions[actual_idx];
            let (prefix, style) = if display_idx == app.selected {
                (
                    "▶ ",
                    Style::default()
                        .fg(Color::Black)
                        .bg(Color::Blue)
                        .add_modifier(Modifier::BOLD),
                )
            } else {
                (
                    "  ",
                    Style::default().fg(Color::White),
                )
            };

            let name_style = if display_idx == app.selected {
                style
            } else {
                Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)
            };

            let desc_style = if display_idx == app.selected {
                style
            } else {
                Style::default().fg(Color::DarkGray)
            };

            let line = Line::from(vec![
                Span::styled(prefix, style),
                Span::styled(format!("{:<20}", s.name), name_style),
                Span::styled(format!(" {}", s.description), desc_style),
            ]);

            ListItem::new(line).style(style)
        })
        .collect();

    let list = List::new(items).block(
        Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Blue))
            .title(format!(" Select a Session ({}/{}) ", app.filtered_indices.len(), app.sessions.len()))
            .title_style(Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)),
    );

    f.render_widget(list, chunks[4]);
}

fn cleanup_old_sessions() -> Result<()> {
    let output = Command::new("zellij")
        .args(["list-sessions"])
        .output()
        .context("Failed to list zellij sessions")?;

    if !output.status.success() {
        return Ok(()); // No sessions to clean up
    }

    let sessions = String::from_utf8_lossy(&output.stdout);

    // Valid session prefixes
    let valid_prefixes = [
        "energyboard-",
        "backoffice-",
        "easyasset-",
        "elixir-",
        "gappel-solutions-",
        "decon-",
        "screensaver-",
        "lazychat-",
    ];

    for line in sessions.lines() {
        // Remove ANSI color codes
        let clean_line = strip_ansi_codes(line);

        // Skip EXITED sessions
        if clean_line.contains("EXITED") {
            continue;
        }

        // Extract session name (first word)
        if let Some(session_name) = clean_line.split_whitespace().next() {
            // Check if it matches any valid prefix
            let is_valid = valid_prefixes.iter().any(|&prefix| session_name.starts_with(prefix));

            if !is_valid {
                // Kill session that doesn't match template
                let _ = Command::new("zellij")
                    .args(["delete-session", session_name])
                    .output();
            }
        }
    }

    Ok(())
}

fn strip_ansi_codes(s: &str) -> String {
    let mut result = String::new();
    let mut in_escape = false;

    for ch in s.chars() {
        if ch == '\x1b' {
            in_escape = true;
        } else if in_escape {
            if ch == 'm' {
                in_escape = false;
            }
        } else {
            result.push(ch);
        }
    }

    result
}

fn launch_session(layout: &str) -> Result<()> {
    use std::fs::OpenOptions;
    use std::io::Write;

    let home = std::env::var("HOME")?;
    let log_path = format!("{}/zellij-welcome.log", home);
    let mut log_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_path)?;

    writeln!(log_file, "\n=== {} ===", Local::now().format("%Y-%m-%d %H:%M:%S"))?;
    writeln!(log_file, "Layout requested: {}", layout)?;

    let plugin_path = format!(
        "{}/dev/dotfiles/zellij/.config/zellij/plugins/zellij-switch.wasm",
        home
    );
    writeln!(log_file, "Plugin path: {}", plugin_path)?;

    // Get existing active session (non-EXITED)
    let output = Command::new("zellij")
        .args(["list-sessions"])
        .output()
        .context("Failed to list sessions")?;

    let sessions = String::from_utf8_lossy(&output.stdout);
    writeln!(log_file, "Sessions output:\n{}", sessions)?;

    let prefix = format!("{}-", layout);

    let existing = sessions
        .lines()
        .map(|line| strip_ansi_codes(line))
        .filter(|line| !line.contains("EXITED"))
        .filter_map(|line| {
            line.split_whitespace()
                .next()
                .map(|s| s.to_string())
        })
        .find(|name| name.starts_with(&prefix));

    writeln!(log_file, "Looking for prefix: {}", prefix)?;
    writeln!(log_file, "Found existing: {:?}", existing)?;

    let session_arg = if let Some(existing_name) = existing {
        // Attach to existing
        format!("-s {}", existing_name)
    } else {
        // Create new with timestamp
        let timestamp = Local::now().format("%Y%m%d-%H%M%S");
        let new_name = format!("{}-{}", layout, timestamp);
        format!("-s {} -l {}", new_name, layout)
    };

    writeln!(log_file, "Session arg: {}", session_arg)?;

    let full_cmd = format!(
        "zellij pipe --plugin file:{} -- {}",
        plugin_path, session_arg
    );
    writeln!(log_file, "Full command: {}", full_cmd)?;

    // Launch via zellij pipe
    let result = Command::new("zellij")
        .args(["pipe", "--plugin", &format!("file:{}", plugin_path), "--", &session_arg])
        .output();

    match &result {
        Ok(output) => {
            writeln!(log_file, "Command succeeded")?;
            writeln!(log_file, "stdout: {}", String::from_utf8_lossy(&output.stdout))?;
            writeln!(log_file, "stderr: {}", String::from_utf8_lossy(&output.stderr))?;
            writeln!(log_file, "status: {}", output.status)?;
        }
        Err(e) => {
            writeln!(log_file, "Command failed: {}", e)?;
        }
    }

    result.context("Failed to launch zellij session")?;

    Ok(())
}
