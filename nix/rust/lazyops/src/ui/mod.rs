mod help;
mod input;
mod preview;
mod sprint_bar;
mod work_items;

use crate::app::{App, InputMode};
use ratatui::{
    prelude::*,
    widgets::{Block, Borders, Clear, Paragraph},
};

pub fn draw(f: &mut Frame, app: &mut App) {
    let size = f.area();

    // Main vertical layout: header (3) + content + status bar (1)
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Sprint/project bar
            Constraint::Min(0),     // Main content
            Constraint::Length(1),  // Status/help bar
        ])
        .split(size);

    // Header bar with sprint and project selectors
    sprint_bar::draw(f, app, chunks[0]);

    // Main content: 50/50 horizontal split
    let content = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(50),
            Constraint::Percentage(50),
        ])
        .split(chunks[1]);

    // Left: Work items list
    work_items::draw(f, app, content[0]);

    // Right: Preview pane
    preview::draw(f, app, content[1]);

    // Bottom: Status/help bar
    draw_status_bar(f, app, chunks[2]);

    // Overlays (modals, dropdowns, help)
    match app.input_mode {
        InputMode::Help => help::draw_popup(f, app, size),
        InputMode::SprintSelect => input::draw_sprint_dropdown(f, app, size),
        InputMode::ProjectSelect => input::draw_project_dropdown(f, app, size),
        InputMode::EditState => input::draw_state_dropdown(f, app, size),
        InputMode::EditAssignee => input::draw_assignee_dropdown(f, app, size),
        InputMode::Search => input::draw_search_input(f, app, size),
        InputMode::FilterState => input::draw_filter_state_dropdown(f, app, size),
        InputMode::FilterAssignee => input::draw_filter_assignee_dropdown(f, app, size),
        InputMode::Normal => {}
    }

    // Loading overlay
    if app.loading {
        draw_loading(f, app, size);
    }
}

fn draw_status_bar(f: &mut Frame, app: &App, area: Rect) {
    let style = if app.status_is_error {
        Style::default().fg(Color::Red)
    } else {
        Style::default().fg(Color::DarkGray)
    };

    let content = if let Some(msg) = &app.status_message {
        msg.clone()
    } else {
        // Show active filters or keybindings
        let mut parts: Vec<String> = Vec::new();

        if let Some(state) = &app.filter_state {
            parts.push(format!("State:{}", state));
        }
        if let Some(assignee) = &app.filter_assignee {
            parts.push(format!("Assignee:{}", assignee));
        }
        if !app.search_query.is_empty() {
            parts.push(format!("Search:\"{}\"", app.search_query));
        }

        if !parts.is_empty() {
            format!("Filters: {}  │  c:clear  s:state  a:user  f:search", parts.join("  "))
        } else {
            match app.input_mode {
                InputMode::Normal => {
                    match app.focus {
                        crate::app::Focus::WorkItems => {
                            "j/k:nav  Enter:expand  t:toggle  o:open  s:state  a:user  S:edit  A:assign  f:search  I:sprint  l:preview  ?:help  q:quit".into()
                        }
                        crate::app::Focus::Preview => {
                            match app.preview_tab {
                                crate::app::PreviewTab::Details => {
                                    "j/k:scroll  Tab:refs  h:back  o:open  ?:help  q:quit".into()
                                }
                                crate::app::PreviewTab::References => {
                                    "j/k:select  ^d/^u:page  Tab:details  h:back  o:open  ?:help  q:quit".into()
                                }
                            }
                        }
                    }
                }
                InputMode::Search => "Enter:confirm  Esc:cancel".into(),
                _ => "j/k:select  Enter:confirm  Esc:cancel".into(),
            }
        }
    };

    let paragraph = Paragraph::new(content).style(style);
    f.render_widget(paragraph, area);
}

fn draw_loading(f: &mut Frame, app: &App, area: Rect) {
    let spinner = app.spinner_char();
    let message = if app.loading_message.is_empty() {
        "Loading..."
    } else {
        &app.loading_message
    };

    let text = format!(" {} {} ", spinner, message);
    let width = (text.len() as u16).max(20).min(50);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::Cyan))
        .style(Style::default().bg(Color::Black));

    let inner = centered_rect(width, 3, area);
    f.render_widget(Clear, inner);
    f.render_widget(block.clone(), inner);

    let text_area = Rect::new(inner.x + 1, inner.y + 1, inner.width - 2, 1);
    let paragraph = Paragraph::new(text)
        .style(Style::default().fg(Color::Cyan))
        .alignment(Alignment::Center);
    f.render_widget(paragraph, text_area);
}

// Helper: create a centered rect
pub fn centered_rect(width: u16, height: u16, area: Rect) -> Rect {
    let x = area.x + (area.width.saturating_sub(width)) / 2;
    let y = area.y + (area.height.saturating_sub(height)) / 2;
    Rect::new(x, y, width.min(area.width), height.min(area.height))
}

// Helper: styled block with focus indicator
pub fn styled_block<'a>(title: &'a str, focused: bool, theme: &'a crate::config::Theme) -> Block<'a> {
    let border_color = if focused {
        theme.parse_color(&theme.border_active)
    } else {
        theme.parse_color(&theme.border)
    };

    Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(border_color))
        .title(format!(" {title} "))
}
