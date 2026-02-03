use crate::app::App;
use ratatui::prelude::*;
use ratatui::widgets::{Block, Borders, Clear, List, ListItem, Paragraph};

pub fn draw_sprint_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let items: Vec<ListItem> = app.sprints.iter()
        .map(|s| {
            let marker = if s.attributes.time_frame.as_deref() == Some("current") { "● " } else { "  " };
            ListItem::new(format!("{}{}", marker, s.name))
        })
        .collect();

    draw_dropdown(f, app, area, " Select Sprint ", items, &mut app.dropdown_list_state.clone());
}

pub fn draw_project_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let items: Vec<ListItem> = app.config.projects.iter()
        .map(|p| ListItem::new(p.name.clone()))
        .collect();

    draw_dropdown(f, app, area, " Select Project ", items, &mut app.dropdown_list_state.clone());
}

pub fn draw_state_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let states = app.filtered_edit_states();
    let filter_input = app.filter_input.clone();

    let items: Vec<ListItem> = states.iter()
        .map(|s| ListItem::new(*s))
        .collect();

    draw_searchable_dropdown(f, app, area, " Change State ", items, &filter_input);
}

pub fn draw_assignee_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let assignees = app.filtered_edit_assignees();
    let filter_input = app.filter_input.clone();
    let items: Vec<ListItem> = assignees.iter()
        .map(|u| ListItem::new(u.display_name.clone()))
        .collect();

    draw_searchable_dropdown(f, app, area, " Change Assignee ", items, &filter_input);
}

fn draw_dropdown(f: &mut Frame, app: &mut App, area: Rect, title: &str, items: Vec<ListItem>, _list_state: &mut ratatui::widgets::ListState) {
    let height = (items.len() + 2).min(15) as u16;
    let inner = super::centered_rect(40, height, area);
    f.render_widget(Clear, inner);

    let block = Block::default()
        .borders(Borders::ALL)
        .title(title);

    let list = List::new(items)
        .block(block)
        .highlight_style(Style::default().bg(app.config.theme.parse_color(&app.config.theme.selected_bg)));

    f.render_stateful_widget(list, inner, &mut app.dropdown_list_state);
}

fn draw_searchable_dropdown(f: &mut Frame, app: &mut App, area: Rect, title: &str, items: Vec<ListItem>, filter_input: &str) {
    // +3 for search input area
    let height = (items.len() + 5).min(18) as u16;
    let inner = super::centered_rect(45, height, area);
    f.render_widget(Clear, inner);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Search input
            Constraint::Min(0),     // List
        ])
        .split(inner);

    // Search input
    let search_block = Block::default()
        .borders(Borders::ALL)
        .title(title);
    let display_text = format!("🔍 {}", filter_input);
    let search_para = Paragraph::new(display_text).block(search_block);
    f.render_widget(search_para, chunks[0]);

    // Show cursor
    f.set_cursor_position(Position::new(
        chunks[0].x + 4 + filter_input.chars().count() as u16,
        chunks[0].y + 1,
    ));

    // List
    let list_block = Block::default()
        .borders(Borders::LEFT | Borders::RIGHT | Borders::BOTTOM);

    let list = List::new(items)
        .block(list_block)
        .highlight_style(Style::default().bg(app.config.theme.parse_color(&app.config.theme.selected_bg)));

    f.render_stateful_widget(list, chunks[1], &mut app.dropdown_list_state);
}

pub fn draw_search_input(f: &mut Frame, app: &App, area: Rect) {
    let inner = Rect::new(area.x, area.y, area.width, 3);
    f.render_widget(Clear, inner);

    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Search ");

    let paragraph = Paragraph::new(app.search_query.as_str()).block(block);
    f.render_widget(paragraph, inner);

    f.set_cursor_position(Position::new(
        inner.x + 1 + app.search_query.len() as u16,
        inner.y + 1,
    ));
}

fn state_icon_and_color(state: &str) -> (&'static str, Color) {
    match state {
        "All" => ("○", Color::White),
        "New" => ("○", Color::Rgb(140, 140, 140)),
        "In Progress" => ("◐", Color::Rgb(200, 180, 60)),
        "Done In Stage" => ("●", Color::Rgb(180, 100, 200)),
        "Done Not Released" => ("●", Color::Rgb(230, 140, 50)),
        "Done" => ("●", Color::Rgb(80, 200, 120)),
        "Tested w/Bugs" => ("●", Color::Rgb(220, 80, 80)),
        "Removed" => ("○", Color::Rgb(100, 100, 100)),
        _ => ("○", Color::Rgb(140, 140, 140)),
    }
}

fn get_initials(name: &str) -> String {
    name.split_whitespace()
        .filter_map(|word| word.chars().next())
        .take(2)
        .collect::<String>()
        .to_uppercase()
}

pub fn draw_filter_state_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let states = app.filtered_states();
    let items: Vec<ListItem> = states.iter()
        .map(|s| {
            let selected = app.filter_state.as_deref() == Some(*s);
            let (icon, color) = state_icon_and_color(s);
            let line = Line::from(vec![
                Span::styled(format!("{} ", icon), Style::default().fg(color)),
                Span::styled(
                    s.to_string(),
                    if selected { Style::default().add_modifier(Modifier::BOLD) } else { Style::default() }
                ),
            ]);
            ListItem::new(line)
        })
        .collect();

    draw_fuzzy_dropdown(f, app, area, " Filter by State ", items, &app.filter_input.clone());
}

pub fn draw_filter_assignee_dropdown(f: &mut Frame, app: &mut App, area: Rect) {
    let assignees = app.filtered_assignees();
    let highlighted_idx = app.dropdown_list_state.selected();
    let items: Vec<ListItem> = assignees.iter()
        .enumerate()
        .map(|(idx, a)| {
            let selected = app.filter_assignee.as_deref() == Some(a.as_str());
            let is_highlighted = highlighted_idx == Some(idx);
            let initials = if a == "All" || a == "Unassigned" {
                "--".to_string()
            } else {
                get_initials(a)
            };
            // Use spaces on highlighted row to avoid powerline artifacts
            let line = if is_highlighted {
                Line::from(vec![
                    Span::styled(" ", Style::default()),
                    Span::styled(format!("{}", initials), Style::default().fg(Color::Rgb(240, 250, 255)).bg(Color::Rgb(60, 90, 100))),
                    Span::styled("  ", Style::default()),
                    Span::styled(
                        a.clone(),
                        if selected { Style::default().add_modifier(Modifier::BOLD) } else { Style::default() }
                    ),
                ])
            } else {
                Line::from(vec![
                    Span::styled("\u{e0b6}", Style::default().fg(Color::Rgb(45, 70, 80))),
                    Span::styled(format!("{}", initials), Style::default().fg(Color::Rgb(200, 220, 230)).bg(Color::Rgb(45, 70, 80))),
                    Span::styled("\u{e0b4} ", Style::default().fg(Color::Rgb(45, 70, 80))),
                    Span::styled(
                        a.clone(),
                        if selected { Style::default().add_modifier(Modifier::BOLD) } else { Style::default() }
                    ),
                ])
            };
            ListItem::new(line)
        })
        .collect();

    draw_fuzzy_dropdown(f, app, area, " Filter by Assignee ", items, &app.filter_input.clone());
}

fn draw_fuzzy_dropdown(f: &mut Frame, app: &mut App, area: Rect, title: &str, items: Vec<ListItem>, filter_input: &str) {
    // +3 for input box, +2 for borders
    let height = (items.len() + 5).min(18) as u16;
    let width = 50_u16;
    let inner = super::centered_rect(width, height, area);
    f.render_widget(Clear, inner);

    // Main block
    let block = Block::default()
        .borders(Borders::ALL)
        .title(title);
    f.render_widget(block, inner);

    // Content area inside the block
    let content = Rect::new(inner.x + 1, inner.y + 1, inner.width - 2, inner.height - 2);

    // Search input area (first 2 lines)
    let search_area = Rect::new(content.x, content.y, content.width, 2);

    // Display text with prompt
    let display_text = format!("🔍 {}", filter_input);
    let search_para = Paragraph::new(display_text.as_str())
        .style(Style::default().fg(Color::White));
    f.render_widget(search_para, search_area);

    // Underline separator
    let separator = "─".repeat(content.width as usize);
    let sep_area = Rect::new(content.x, content.y + 1, content.width, 1);
    f.render_widget(Paragraph::new(separator).style(Style::default().fg(Color::DarkGray)), sep_area);

    // Show cursor after the search icon and text
    f.set_cursor_position(Position::new(
        search_area.x + 2 + filter_input.chars().count() as u16,  // +2 for emoji
        search_area.y,
    ));

    // List area (below separator)
    let list_area = Rect::new(content.x, content.y + 2, content.width, content.height.saturating_sub(2));
    let list = List::new(items)
        .highlight_style(Style::default().bg(app.config.theme.parse_color(&app.config.theme.selected_bg)));
    f.render_stateful_widget(list, list_area, &mut app.dropdown_list_state);
}
