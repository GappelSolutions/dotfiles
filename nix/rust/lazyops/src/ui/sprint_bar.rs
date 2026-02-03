use crate::app::App;
use ratatui::prelude::*;
use ratatui::widgets::{Block, Borders, Paragraph};

pub fn draw(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(50),
            Constraint::Percentage(50),
        ])
        .split(area);

    // Sprint selector
    let sprint_name = app.selected_sprint()
        .map(|s| s.name.clone())
        .unwrap_or_else(|| "No sprint".into());

    let sprint_block = Block::default()
        .borders(Borders::ALL)
        .title(" Sprint [I] ");
    let sprint_text = Paragraph::new(sprint_name).block(sprint_block);
    f.render_widget(sprint_text, chunks[0]);

    // Project selector
    let project_name = app.current_project()
        .map(|p| p.name.clone())
        .unwrap_or_else(|| "No project".into());

    let project_block = Block::default()
        .borders(Borders::ALL)
        .title(" Project [P] ");
    let project_text = Paragraph::new(project_name).block(project_block);
    f.render_widget(project_text, chunks[1]);
}
