use crate::app::{App, Focus, PreviewTab};
use ratatui::prelude::*;
use ratatui::widgets::{Block, Borders, List, ListItem, Paragraph, Tabs, Wrap, Scrollbar, ScrollbarOrientation, ScrollbarState};

pub fn draw(f: &mut Frame, app: &mut App, area: Rect) {
    let focused = app.focus == Focus::Preview;

    // Vertical split: tabs (1) + content
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Tab bar
            Constraint::Min(0),     // Content
        ])
        .split(area);

    // Draw tab bar
    draw_tabs(f, app, chunks[0], focused);

    // Draw tab content
    let content_area = chunks[1];

    match app.preview_tab {
        PreviewTab::Details => draw_details(f, app, content_area, focused),
        PreviewTab::References => draw_references(f, app, content_area, focused),
    }
}

fn draw_tabs(f: &mut Frame, app: &App, area: Rect, focused: bool) {
    let titles = vec!["Details", "References"];
    let selected = match app.preview_tab {
        PreviewTab::Details => 0,
        PreviewTab::References => 1,
    };

    let tabs = Tabs::new(titles)
        .select(selected)
        .style(Style::default().fg(app.config.theme.parse_color(&app.config.theme.text_muted)))
        .highlight_style(
            Style::default()
                .fg(app.config.theme.parse_color(&app.config.theme.highlight))
                .add_modifier(Modifier::BOLD)
        )
        .divider("|");

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(
            if focused {
                app.config.theme.parse_color(&app.config.theme.border_active)
            } else {
                app.config.theme.parse_color(&app.config.theme.border)
            }
        ));

    f.render_widget(tabs.block(block), area);
}

fn draw_details(f: &mut Frame, app: &mut App, area: Rect, focused: bool) {
    let block = super::styled_block("", focused, &app.config.theme);
    let inner = block.inner(area);
    f.render_widget(block, area);

    // Clone the selected work item to avoid borrow conflicts
    let Some(vi) = app.selected_work_item().cloned() else {
        let empty = Paragraph::new("Select a work item")
            .style(Style::default().fg(app.config.theme.parse_color(&app.config.theme.text_muted)));
        f.render_widget(empty, inner);
        return;
    };

    let item = &vi.item;
    let theme = &app.config.theme;

    // Type colors (using centralized theme colors)
    let type_color = theme.type_color(&item.fields.work_item_type);
    let (id_fg, id_bg) = theme.type_badge_colors(&item.fields.work_item_type);

    // State color
    let state_color = theme.state_color(&item.fields.state);

    // Build content lines
    let mut lines: Vec<Line> = Vec::new();

    // Header: Type icon + ID badge + Type name
    lines.push(Line::from(vec![
        Span::styled(format!("{} ", item.type_icon()), Style::default().fg(type_color)),
        Span::styled("\u{e0b6}", Style::default().fg(id_bg)),
        Span::styled(format!(" #{} ", item.id), Style::default().fg(id_fg).bg(id_bg).add_modifier(Modifier::BOLD)),
        Span::styled("\u{e0b4} ", Style::default().fg(id_bg)),
        Span::styled(&item.fields.work_item_type, Style::default().fg(type_color)),
    ]));
    lines.push(Line::from(""));

    // Title (bold, full width)
    lines.push(Line::from(vec![
        Span::styled(&item.fields.title, Style::default().add_modifier(Modifier::BOLD).fg(Color::White)),
    ]));
    lines.push(Line::from(""));

    // Metadata section with styled badges
    // State badge
    let state_bg = theme.state_bg_color(&item.fields.state);

    let label_fg = Color::Rgb(220, 220, 225);
    let label_bg = Color::Rgb(50, 50, 55);

    // State row: label badge + value badge
    lines.push(Line::from(vec![
        Span::styled(" State", Style::default().fg(label_fg).bg(label_bg)),
        Span::styled("\u{e0b4} ", Style::default().fg(label_bg)),
        Span::styled("\u{e0b6}", Style::default().fg(state_bg)),
        Span::styled(format!(" {} ", &item.fields.state), Style::default().fg(state_color).bg(state_bg)),
        Span::styled("\u{e0b4}", Style::default().fg(state_bg)),
    ]));

    // Assigned to
    let assigned = item.fields.assigned_to.as_ref()
        .map(|a| a.display_name.clone())
        .unwrap_or_else(|| "Unassigned".into());
    let (assignee_fg, assignee_bg) = if item.fields.assigned_to.is_some() {
        (Color::Rgb(200, 220, 230), Color::Rgb(45, 70, 80))
    } else {
        (Color::Rgb(100, 100, 100), Color::Rgb(40, 40, 40))
    };

    lines.push(Line::from(vec![
        Span::styled(" Assignee", Style::default().fg(label_fg).bg(label_bg)),
        Span::styled("\u{e0b4} ", Style::default().fg(label_bg)),
        Span::styled("\u{e0b6}", Style::default().fg(assignee_bg)),
        Span::styled(format!(" {} ", assigned), Style::default().fg(assignee_fg).bg(assignee_bg)),
        Span::styled("\u{e0b4}", Style::default().fg(assignee_bg)),
    ]));

    // Sprint/Iteration
    if let Some(iteration) = &item.fields.iteration_path {
        let sprint = iteration.split('\\').last().unwrap_or(iteration);
        let sprint_bg = Color::Rgb(35, 45, 65);
        lines.push(Line::from(vec![
            Span::styled(" Sprint", Style::default().fg(label_fg).bg(label_bg)),
            Span::styled("\u{e0b4} ", Style::default().fg(label_bg)),
            Span::styled("\u{e0b6}", Style::default().fg(sprint_bg)),
            Span::styled(format!(" {} ", sprint), Style::default().fg(Color::Rgb(180, 200, 255)).bg(sprint_bg)),
            Span::styled("\u{e0b4}", Style::default().fg(sprint_bg)),
        ]));
    }

    // Remaining work / Hours
    if let Some(hours) = item.fields.remaining_work {
        let estimate_bg = Color::Rgb(55, 45, 25);
        lines.push(Line::from(vec![
            Span::styled(" Estimate", Style::default().fg(label_fg).bg(label_bg)),
            Span::styled("\u{e0b4} ", Style::default().fg(label_bg)),
            Span::styled("\u{e0b6}", Style::default().fg(estimate_bg)),
            Span::styled(format!(" {:.0}h ", hours), Style::default().fg(Color::Rgb(255, 200, 100)).bg(estimate_bg)),
            Span::styled("\u{e0b4}", Style::default().fg(estimate_bg)),
        ]));
    }

    // Tags
    if let Some(tags) = &item.fields.tags {
        let tag_bg = Color::Rgb(50, 40, 60);
        let mut tag_spans = vec![
            Span::styled(" Tags", Style::default().fg(label_fg).bg(label_bg)),
            Span::styled("\u{e0b4} ", Style::default().fg(label_bg)),
        ];
        for tag in tags.split(';').map(|t| t.trim()) {
            if !tag.is_empty() {
                tag_spans.push(Span::styled("\u{e0b6}", Style::default().fg(tag_bg)));
                tag_spans.push(Span::styled(format!(" {} ", tag), Style::default().fg(Color::Rgb(200, 180, 255)).bg(tag_bg)));
                tag_spans.push(Span::styled("\u{e0b4}", Style::default().fg(tag_bg)));
                tag_spans.push(Span::raw(" "));
            }
        }
        lines.push(Line::from(tag_spans));
    }

    // Divider
    lines.push(Line::from(""));
    lines.push(Line::from(vec![
        Span::styled("─".repeat(inner.width.saturating_sub(2) as usize), Style::default().fg(Color::Rgb(60, 60, 60))),
    ]));
    lines.push(Line::from(""));

    // Description header
    let desc_bg = Color::Rgb(45, 45, 50);
    lines.push(Line::from(vec![
        Span::styled(" Description", Style::default().fg(label_fg).bg(desc_bg).add_modifier(Modifier::BOLD)),
        Span::styled("\u{e0b4}", Style::default().fg(desc_bg)),
    ]));
    lines.push(Line::from(""));

    // Description content
    if let Some(desc) = &item.fields.description {
        let plain = html2text::from_read(desc.as_bytes(), inner.width.saturating_sub(4) as usize);
        // Split by newline to preserve empty lines (lines() skips them)
        for line in plain.split('\n') {
            if line.trim().is_empty() {
                lines.push(Line::from(""));
            } else {
                lines.push(Line::from(Span::styled(line.to_string(), Style::default().fg(Color::Rgb(180, 180, 180)))));
            }
        }
    } else {
        lines.push(Line::from(Span::styled(
            "No description",
            Style::default().fg(theme.parse_color(&theme.text_muted)).add_modifier(Modifier::ITALIC)
        )));
    }

    // Calculate scroll
    let total_lines = lines.len() as u16;
    let visible_lines = inner.height;
    app.preview_scroll_max = total_lines.saturating_sub(visible_lines);

    let paragraph = Paragraph::new(lines)
        .scroll((app.preview_scroll, 0))
        .wrap(Wrap { trim: false });

    f.render_widget(paragraph, inner);

    // Scrollbar
    if app.preview_scroll_max > 0 {
        let scrollbar = Scrollbar::new(ScrollbarOrientation::VerticalRight)
            .begin_symbol(Some("↑"))
            .end_symbol(Some("↓"));

        let mut scrollbar_state = ScrollbarState::new(app.preview_scroll_max as usize)
            .position(app.preview_scroll as usize);

        f.render_stateful_widget(scrollbar, area, &mut scrollbar_state);
    }
}

fn draw_references(f: &mut Frame, app: &mut App, area: Rect, focused: bool) {
    let block = super::styled_block("", focused, &app.config.theme);
    let inner = block.inner(area);
    f.render_widget(block, area);

    let Some(vi) = app.selected_work_item() else {
        let empty = Paragraph::new("Select a work item")
            .style(Style::default().fg(app.config.theme.parse_color(&app.config.theme.text_muted)));
        f.render_widget(empty, inner);
        return;
    };

    // Check if relations are still loading
    let is_loaded = app.relations_loaded.contains(&vi.item.id);

    // Use the sorted/grouped relations from app
    let refs = app.selected_relations();

    if refs.is_empty() {
        let msg = if is_loaded {
            "No references"
        } else {
            "Loading..."
        };
        let empty = Paragraph::new(msg)
            .style(Style::default().fg(app.config.theme.parse_color(&app.config.theme.text_muted)));
        f.render_widget(empty, inner);
        return;
    }

    let selected_idx = app.relations_list_state.selected();
    let theme = &app.config.theme;

    // First pass: count items per group
    let mut group_counts: std::collections::HashMap<&str, usize> = std::collections::HashMap::new();
    for r in &refs {
        let name = r.attributes.name.as_deref().unwrap_or("");
        let group = if r.rel == "System.LinkTypes.Hierarchy-Forward" || name == "Child" {
            "Children"
        } else if r.rel == "AttachedFile" {
            "Attachments"
        } else if name == "Pull Request" {
            "Pull Requests"
        } else if name == "Fixed in Commit" {
            "Commits"
        } else if name == "Branch" {
            "Branches"
        } else {
            "Other"
        };
        *group_counts.entry(group).or_insert(0) += 1;
    }

    // Build items with group headers
    let mut items: Vec<ListItem> = Vec::new();
    let mut current_group: Option<&str> = None;
    let mut selectable_idx = 0;

    for r in &refs {
        let name = r.attributes.name.as_deref().unwrap_or("");
        let group = if r.rel == "System.LinkTypes.Hierarchy-Forward" || name == "Child" {
            "Children"
        } else if r.rel == "AttachedFile" {
            "Attachments"
        } else if name == "Pull Request" {
            "Pull Requests"
        } else if name == "Fixed in Commit" {
            "Commits"
        } else if name == "Branch" {
            "Branches"
        } else {
            "Other"
        };

        // Add group header if changed
        if current_group != Some(group) {
            // Add spacing between groups (except first)
            if current_group.is_some() {
                items.push(ListItem::new(Line::from("")));
            }
            current_group = Some(group);

            // Group icon and color
            let (icon, color) = match group {
                "Children" => ("◇", Color::Cyan),
                "Attachments" => ("📎", Color::Rgb(100, 160, 255)),
                "Pull Requests" => ("⎇", Color::Magenta),
                "Commits" => ("●", Color::Green),
                "Branches" => ("⌥", Color::Yellow),
                _ => ("◆", Color::Gray),
            };

            let count = group_counts.get(group).unwrap_or(&0);
            let header = Line::from(vec![
                Span::styled(format!(" {} ", icon), Style::default().fg(color)),
                Span::styled(group, Style::default().fg(color).add_modifier(Modifier::BOLD)),
                Span::styled(format!(" ({})", count), Style::default().fg(Color::DarkGray)),
            ]);
            items.push(ListItem::new(header));
        }

        let parsed = app.parse_relation(r);
        let is_selected = selected_idx == Some(selectable_idx);

        // Get color based on icon type
        let color = match parsed.icon {
            "⎇" => Color::Magenta,   // PR
            "●" => Color::Green,     // Commit
            "⌥" => Color::Yellow,    // Branch
            "◇" => Color::Cyan,      // Child
            "📎" => Color::Rgb(100, 160, 255), // Attachment
            _ => Color::White,       // Other
        };

        let base_style = if is_selected {
            Style::default().bg(theme.parse_color(&theme.selected_bg))
        } else {
            Style::default()
        };

        let text_color = if is_selected { Color::White } else { Color::Rgb(200, 200, 200) };

        let line = Line::from(vec![
            Span::styled("    ", base_style),
            Span::styled(format!("{} ", parsed.icon), base_style.fg(color)),
            Span::styled(parsed.description, base_style.fg(text_color)),
        ]);

        items.push(ListItem::new(line).style(base_style));
        selectable_idx += 1;
    }

    let visible_height = inner.height as usize;
    let total_items = items.len();

    // Find visual row of selected item - traverse items to find it
    let selected_visual_row = if let Some(sel_idx) = selected_idx {
        // Count headers and spacing before selected item
        let mut visual_row = 0;
        let mut item_idx = 0;
        let mut last_group: Option<&str> = None;

        for r in &refs {
            let name = r.attributes.name.as_deref().unwrap_or("");
            let group = if r.rel == "System.LinkTypes.Hierarchy-Forward" || name == "Child" {
                "Children"
            } else if r.rel == "AttachedFile" {
                "Attachments"
            } else if name == "Pull Request" {
                "Pull Requests"
            } else if name == "Fixed in Commit" {
                "Commits"
            } else if name == "Branch" {
                "Branches"
            } else {
                "Other"
            };

            if last_group != Some(group) {
                if last_group.is_some() {
                    visual_row += 1; // spacing line
                }
                visual_row += 1; // header line
                last_group = Some(group);
            }

            if item_idx == sel_idx {
                break;
            }
            visual_row += 1;
            item_idx += 1;
        }
        visual_row
    } else {
        0
    };

    // Auto-scroll to keep selected visible
    let scroll = if visible_height > 0 && selected_visual_row >= app.refs_scroll as usize + visible_height {
        (selected_visual_row - visible_height + 1) as u16
    } else if (app.refs_scroll as usize) > selected_visual_row {
        selected_visual_row as u16
    } else {
        app.refs_scroll
    };
    app.refs_scroll = scroll.min(total_items.saturating_sub(visible_height) as u16);

    // Render only visible items
    let skip = app.refs_scroll as usize;
    let visible_items: Vec<ListItem> = items.into_iter()
        .skip(skip)
        .take(visible_height)
        .collect();

    let list = List::new(visible_items);
    f.render_widget(list, inner);
}
