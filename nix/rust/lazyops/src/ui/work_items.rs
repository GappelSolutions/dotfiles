use crate::app::{App, Focus, VisibleWorkItem};
use ratatui::prelude::*;
use ratatui::widgets::{List, ListItem};

pub fn draw(f: &mut Frame, app: &mut App, area: Rect) {
    let focused = app.focus == Focus::WorkItems;
    let block = super::styled_block("Work Items", focused, &app.config.theme);

    if app.visible_items.is_empty() {
        let empty = ratatui::widgets::Paragraph::new("No work items in this sprint")
            .block(block)
            .style(Style::default().fg(app.config.theme.parse_color(&app.config.theme.text_muted)));
        f.render_widget(empty, area);
        return;
    }

    // Calculate inner width (area minus borders and highlight symbol)
    let inner_width = area.width.saturating_sub(4) as usize; // 2 for borders, 2 for highlight symbol

    let selected_idx = app.work_item_list_state.selected();
    let items: Vec<ListItem> = app.visible_items.iter()
        .enumerate()
        .map(|(idx, vi)| render_work_item(vi, &app.config.theme, selected_idx == Some(idx), inner_width))
        .collect();

    let list = List::new(items)
        .block(block)
        .highlight_style(Style::default().bg(Color::Rgb(35, 55, 85)))
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, area, &mut app.work_item_list_state);
}

fn truncate_str(s: &str, max_chars: usize) -> String {
    let chars: Vec<char> = s.chars().collect();
    if chars.len() > max_chars {
        let truncated: String = chars[..max_chars.saturating_sub(3)].iter().collect();
        format!("{}...", truncated)
    } else {
        s.to_string()
    }
}

fn get_initials(name: &str) -> String {
    name.split_whitespace()
        .filter_map(|word| word.chars().next())
        .take(2)
        .collect::<String>()
        .to_uppercase()
}

fn render_work_item(vi: &VisibleWorkItem, theme: &crate::config::Theme, is_selected: bool, available_width: usize) -> ListItem<'static> {
    let item = &vi.item;

    // Indentation based on depth
    let indent = "  ".repeat(vi.depth);

    // Expand/collapse indicator
    let expand_indicator = if vi.has_children {
        if vi.is_expanded { "▼ " } else { "▶ " }
    } else {
        "  "
    };

    // Type icon with color (using centralized theme colors)
    let type_icon = item.type_icon();
    let type_color = theme.type_color(&item.fields.work_item_type);

    // ID badge with subtle type-colored background
    let (id_fg, id_bg) = theme.type_badge_colors(&item.fields.work_item_type);

    // State icon with color
    let state_icon = item.state_icon();
    let state_color = theme.state_color(&item.fields.state);

    // Get assignee initials
    let initials = item.fields.assigned_to.as_ref()
        .map(|a| get_initials(&a.display_name))
        .unwrap_or_else(|| "--".to_string());

    // Hours display (remaining work)
    let hours = item.fields.remaining_work
        .map(|h| format!("{:.0}h", h))
        .unwrap_or_default();

    // Calculate prefix width: state(2) + indent + expand(2) + type(2) + powerline(1) + id + powerline(2) + initials_badge(4-5) + space(1)
    let id_str = format!("#{}", item.id);
    let prefix_width = 2 + (vi.depth * 2) + 2 + 2 + 1 + id_str.len() + 2 + 4 + 1;
    let hours_width = if hours.is_empty() { 0 } else { hours.len() + 1 };
    let max_title_len = available_width.saturating_sub(prefix_width + hours_width);
    let title = truncate_str(&item.fields.title, max_title_len);

    // Pin icon takes priority over state icon (always shows when pinned)
    let first_icon = if vi.is_pinned {
        Span::styled("⚑ ", Style::default().fg(Color::Rgb(220, 180, 80)))
    } else {
        Span::styled(format!("{} ", state_icon), Style::default().fg(state_color))
    };

    // Build the line with spans - state/pin first, then expand, then content
    let mut spans = vec![
        first_icon,
        Span::raw(indent),
        Span::raw(expand_indicator),
        Span::styled(format!("{} ", type_icon), Style::default().fg(type_color)),
        Span::styled("\u{e0b6}", Style::default().fg(id_bg)),
        Span::styled(
            format!("#{}", item.id),
            Style::default().fg(id_fg).bg(id_bg)
        ),
        Span::styled("\u{e0b4} ", Style::default().fg(id_bg)),
    ];

    // Initials badge - use spaces on selected row to avoid powerline artifacts
    if is_selected {
        spans.push(Span::styled(" ", Style::default()));
        spans.push(Span::styled(format!("{}", initials), Style::default().fg(Color::Rgb(240, 250, 255)).bg(Color::Rgb(60, 90, 100))));
        spans.push(Span::styled(" ", Style::default()));
    } else {
        spans.push(Span::styled("\u{e0b6}", Style::default().fg(Color::Rgb(45, 70, 80))));
        spans.push(Span::styled(format!("{}", initials), Style::default().fg(Color::Rgb(200, 220, 230)).bg(Color::Rgb(45, 70, 80))));
        spans.push(Span::styled("\u{e0b4}", Style::default().fg(Color::Rgb(45, 70, 80))));
    }

    spans.push(Span::raw(" "));
    spans.push(Span::raw(title));

    // Add hours if present
    if !hours.is_empty() {
        spans.push(Span::raw(" "));
        spans.push(Span::styled(hours, Style::default().fg(Color::Rgb(150, 150, 150))));
    }

    // Subtle yellow background for pinned items (will be overwritten by selection highlight)
    let mut list_item = ListItem::new(Line::from(spans));
    if vi.is_pinned && !is_selected {
        list_item = list_item.style(Style::default().bg(Color::Rgb(45, 42, 25)));
    }
    list_item
}
