use crate::app::App;
use ratatui::prelude::*;
use ratatui::widgets::{Block, Borders, Clear, Paragraph, Wrap};

pub fn draw_popup(f: &mut Frame, _app: &App, area: Rect) {
    let help_text = r#"
NAVIGATION
  j/k ↑/↓       Move up/down
  h/l           Focus left/right panel
  g/G           Go to top/bottom
  Ctrl+d/u      Page down/up
  Tab           Switch preview tabs
  Enter         Expand/collapse item
  t             Toggle expand all

FILTERS
  f             Search by text
  s             Filter by state
  a             Filter by assignee
  c             Clear all filters

ACTIONS
  o             Open in browser
  S             Edit state
  A             Edit assignee
  p             Pin/unpin item
  y             Copy ticket ID

SELECTION
  I             Select sprint
  P             Select project
  R             Refresh data
  ?             Toggle help
  q             Quit
"#;

    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Help - Press ? or Esc to close ");

    let inner = super::centered_rect(50, 24, area);
    f.render_widget(Clear, inner);

    let paragraph = Paragraph::new(help_text)
        .block(block)
        .wrap(Wrap { trim: false });
    f.render_widget(paragraph, inner);
}
