use crate::app::{App, Focus, InputMode};
use crate::azure::WorkItem;
use crate::ui;
use anyhow::Result;
use arboard::Clipboard;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use ratatui::prelude::*;
use std::time::{Duration, Instant};

/// Format ticket content for clipboard (no names, just content)
fn format_ticket_content(item: &WorkItem) -> String {
    let mut content = String::new();

    // Title
    content.push_str(&format!("# #{} {}\n\n", item.id, item.fields.title));

    // Description
    if let Some(desc) = &item.fields.description {
        let plain = html2text::from_read(desc.as_bytes(), 80);
        content.push_str("## Description\n\n");
        content.push_str(&plain);
        content.push_str("\n\n");
    }

    // Tags
    if let Some(tags) = &item.fields.tags {
        content.push_str(&format!("**Tags:** {}\n", tags));
    }

    content
}

pub async fn run_app<B: Backend>(terminal: &mut Terminal<B>, app: &mut App) -> Result<()> {
    // Try loading from cache first for instant startup
    let has_cache = app.load_from_cache();

    if has_cache {
        // Cache hit: show data immediately, skip blocking refresh
        if let Some(age) = app.cache_age {
            let mins = age / 60;
            if mins > 0 {
                app.set_status(format!("Cached ({}m ago) - press r to refresh", mins));
            } else {
                app.set_status(format!("Cached ({}s ago) - press r to refresh", age));
            }
        }
    } else {
        // No cache: must load from API (blocking)
        app.set_loading(true, "Loading sprints...");
        terminal.draw(|f| ui::draw(f, app))?;

        if let Err(e) = app.load_sprints().await {
            app.set_error(format!("Failed to load sprints: {e}"));
        } else {
            app.set_loading(true, "Loading work items...");
            terminal.draw(|f| ui::draw(f, app))?;

            if let Err(e) = app.load_work_items().await {
                app.set_error(format!("Failed to load work items: {e}"));
            } else {
                let _ = app.load_users().await;
                app.save_to_cache();
                app.cache_age = Some(0);
            }
        }
        app.set_loading(false, "");
    }

    // Start background relation loader (non-blocking)
    app.start_relations_loader();

    let mut last_refresh = Instant::now();
    let mut last_spinner_tick = Instant::now();
    let refresh_interval = Duration::from_secs(300); // Full refresh every 5 minutes
    let spinner_interval = Duration::from_millis(80);

    loop {
        // Tick spinner during loading
        if app.loading && last_spinner_tick.elapsed() >= spinner_interval {
            app.tick_spinner();
            last_spinner_tick = Instant::now();
        }

        // Poll for loaded relations and titles (non-blocking)
        app.poll_relations();
        app.poll_titles();

        // Start titles loader once some relations have been loaded
        if !app.titles_loader_active && !app.relations_loaded.is_empty() {
            app.start_titles_loader();
        }

        terminal.draw(|f| ui::draw(f, app))?;

        // Poll for events with short timeout for responsive UI
        if event::poll(Duration::from_millis(50))? {
            if let Event::Key(key) = event::read()? {
                if handle_key(app, key).await? {
                    return Ok(());
                }
            }
        }

        // Full data refresh every 5 minutes
        if !app.loading && app.input_mode == InputMode::Normal && last_refresh.elapsed() >= refresh_interval {
            background_full_refresh(app).await;
            last_refresh = Instant::now();
        }
    }
}

/// Full refresh - reloads work items and restarts relation loader
async fn background_full_refresh(app: &mut App) {
    // Cache relations before refresh
    let relations_cache = app.cache_relations();

    if let Some(client) = app.client() {
        if let Some(sprint) = app.selected_sprint() {
            let path = sprint.path.clone();
            if let Ok(items) = client.get_sprint_work_items(&path).await {
                let selected_id = app.selected_work_item().map(|w| w.item.id);

                app.work_items = items;
                app.extract_users_from_work_items();
                app.restore_relations(relations_cache);
                app.rebuild_visible_items();

                if let Some(id) = selected_id {
                    if let Some(pos) = app.visible_items.iter().position(|v| v.item.id == id) {
                        app.work_item_list_state.select(Some(pos));
                    }
                }

                app.cache_age = Some(0);

                // Restart relation loader for any new items
                app.relations_loader_active = false;
                app.start_relations_loader();
            }
        }
    }
}

async fn handle_key(app: &mut App, key: KeyEvent) -> Result<bool> {
    // Clear status on any keypress
    app.clear_status();

    // Handle based on input mode
    match app.input_mode {
        InputMode::Help => {
            match key.code {
                KeyCode::Esc | KeyCode::Char('?') | KeyCode::Char('q') => {
                    app.input_mode = InputMode::Normal;
                }
                _ => {}
            }
        }

        InputMode::SprintSelect => {
            match key.code {
                KeyCode::Esc => app.input_mode = InputMode::Normal,
                KeyCode::Char('j') | KeyCode::Down => app.dropdown_next(app.sprints.len()),
                KeyCode::Char('k') | KeyCode::Up => app.dropdown_prev(app.sprints.len()),
                KeyCode::Enter => {
                    if let Some(idx) = app.dropdown_list_state.selected() {
                        app.selected_sprint_idx = idx;
                        app.input_mode = InputMode::Normal;
                        app.set_loading(true, "Loading sprint...");
                        if let Err(e) = app.load_work_items().await {
                            app.set_error(format!("Failed to load: {e}"));
                        }
                        app.set_loading(false, "");
                    }
                }
                _ => {}
            }
        }

        InputMode::ProjectSelect => {
            match key.code {
                KeyCode::Esc => app.input_mode = InputMode::Normal,
                KeyCode::Char('j') | KeyCode::Down => app.dropdown_next(app.config.projects.len()),
                KeyCode::Char('k') | KeyCode::Up => app.dropdown_prev(app.config.projects.len()),
                KeyCode::Enter => {
                    if let Some(idx) = app.dropdown_list_state.selected() {
                        app.current_project_idx = idx;
                        app.input_mode = InputMode::Normal;
                        app.set_loading(true, "Loading project...");
                        let _ = app.load_sprints().await;
                        let _ = app.load_work_items().await;
                        let _ = app.load_users().await;
                        app.set_loading(false, "");
                    }
                }
                _ => {}
            }
        }

        InputMode::EditState => {
            let states = app.filtered_edit_states();
            match key.code {
                KeyCode::Esc => {
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Down => app.dropdown_next(states.len()),
                KeyCode::Up => app.dropdown_prev(states.len()),
                KeyCode::Enter => {
                    if let (Some(idx), Some(work_item)) = (app.dropdown_list_state.selected(), app.selected_work_item()) {
                        if let Some(state) = states.get(idx) {
                            let id = work_item.item.id;
                            if let Some(client) = app.client() {
                                match client.update_work_item(id, "state", state).await {
                                    Ok(_) => {
                                        app.set_status(format!("Updated state to {state}"));
                                        let _ = app.load_work_items().await;
                                    }
                                    Err(e) => app.set_error(format!("Failed: {e}")),
                                }
                            }
                        }
                    }
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Backspace => {
                    app.filter_input.pop();
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char(c) => {
                    app.filter_input.push(c);
                    app.dropdown_list_state.select(Some(0));
                }
                _ => {}
            }
        }

        InputMode::EditAssignee => {
            let assignees = app.filtered_edit_assignees();
            match key.code {
                KeyCode::Esc => {
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Down => app.dropdown_next(assignees.len()),
                KeyCode::Up => app.dropdown_prev(assignees.len()),
                KeyCode::Enter => {
                    if let (Some(idx), Some(work_item)) = (app.dropdown_list_state.selected(), app.selected_work_item()) {
                        if let Some(user) = assignees.get(idx) {
                            let id = work_item.item.id;
                            if let Some(client) = app.client() {
                                match client.update_work_item(id, "assigned-to", &user.unique_name).await {
                                    Ok(_) => {
                                        app.set_status(format!("Assigned to {}", user.display_name));
                                        let _ = app.load_work_items().await;
                                    }
                                    Err(e) => app.set_error(format!("Failed: {e}")),
                                }
                            }
                        }
                    }
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Backspace => {
                    app.filter_input.pop();
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char(c) => {
                    app.filter_input.push(c);
                    app.dropdown_list_state.select(Some(0));
                }
                _ => {}
            }
        }

        InputMode::Search => {
            match key.code {
                KeyCode::Esc => {
                    app.search_query.clear();
                    app.input_mode = InputMode::Normal;
                    app.rebuild_visible_items();
                }
                KeyCode::Enter => {
                    app.input_mode = InputMode::Normal;
                    // Filter is already applied in rebuild_visible_items
                }
                KeyCode::Backspace => {
                    app.search_query.pop();
                    app.rebuild_visible_items();
                }
                KeyCode::Char(c) => {
                    app.search_query.push(c);
                    app.rebuild_visible_items();
                }
                _ => {}
            }
        }

        InputMode::FilterState => {
            let states = app.filtered_states();
            match key.code {
                KeyCode::Esc => {
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Down => app.dropdown_next(states.len()),
                KeyCode::Up => app.dropdown_prev(states.len()),
                KeyCode::Enter => {
                    if let Some(idx) = app.dropdown_list_state.selected() {
                        if let Some(state) = states.get(idx) {
                            if *state == "All" {
                                app.filter_state = None;
                            } else {
                                app.filter_state = Some(state.to_string());
                            }
                        }
                        app.rebuild_visible_items();
                        app.save_to_cache(); // Persist filter
                    }
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Backspace => {
                    app.filter_input.pop();
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char(c) => {
                    app.filter_input.push(c);
                    app.dropdown_list_state.select(Some(0));
                }
                _ => {}
            }
        }

        InputMode::FilterAssignee => {
            let assignees = app.filtered_assignees();
            match key.code {
                KeyCode::Esc => {
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Down => app.dropdown_next(assignees.len()),
                KeyCode::Up => app.dropdown_prev(assignees.len()),
                KeyCode::Enter => {
                    if let Some(idx) = app.dropdown_list_state.selected() {
                        if let Some(assignee) = assignees.get(idx) {
                            if assignee == "All" {
                                app.filter_assignee = None;
                            } else {
                                app.filter_assignee = Some(assignee.clone());
                            }
                        }
                        app.rebuild_visible_items();
                        app.save_to_cache(); // Persist filter
                    }
                    app.filter_input.clear();
                    app.input_mode = InputMode::Normal;
                }
                KeyCode::Backspace => {
                    app.filter_input.pop();
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char(c) => {
                    app.filter_input.push(c);
                    app.dropdown_list_state.select(Some(0));
                }
                _ => {}
            }
        }

        InputMode::Normal => {
            // Check for Ctrl modifiers first
            if key.modifiers.contains(KeyModifiers::CONTROL) {
                match key.code {
                    KeyCode::Char('d') => {
                        match app.focus {
                            Focus::WorkItems => app.list_jump_down(),
                            Focus::Preview => {
                                if app.preview_tab == crate::app::PreviewTab::References {
                                    app.relations_page_down();
                                } else {
                                    app.preview_scroll = app.preview_scroll.saturating_add(20).min(app.preview_scroll_max);
                                }
                            }
                        }
                    }
                    KeyCode::Char('u') => {
                        match app.focus {
                            Focus::WorkItems => app.list_jump_up(),
                            Focus::Preview => {
                                if app.preview_tab == crate::app::PreviewTab::References {
                                    app.relations_page_up();
                                } else {
                                    app.preview_scroll = app.preview_scroll.saturating_sub(20);
                                }
                            }
                        }
                    }
                    KeyCode::Char('c') => return Ok(true), // Ctrl+C to quit
                    _ => {}
                }
                return Ok(false);
            }

            match key.code {
                KeyCode::Char('q') => return Ok(true),
                KeyCode::Char('?') => app.input_mode = InputMode::Help,

                // Navigation
                KeyCode::Char('j') | KeyCode::Down => {
                    match app.focus {
                        Focus::WorkItems => app.list_next(),
                        Focus::Preview => {
                            if app.preview_tab == crate::app::PreviewTab::References {
                                app.relations_next();
                            } else {
                                app.scroll_preview_down();
                            }
                        }
                    }
                }
                KeyCode::Char('k') | KeyCode::Up => {
                    match app.focus {
                        Focus::WorkItems => app.list_prev(),
                        Focus::Preview => {
                            if app.preview_tab == crate::app::PreviewTab::References {
                                app.relations_prev();
                            } else {
                                app.scroll_preview_up();
                            }
                        }
                    }
                }
                KeyCode::Char('g') => app.list_top(),
                KeyCode::Char('G') => app.list_bottom(),

                // Focus switching
                KeyCode::Char('h') => app.focus = Focus::WorkItems,
                KeyCode::Char('l') => app.focus = Focus::Preview,
                KeyCode::Tab => {
                    app.next_tab();
                    // Reset relations selection when switching tabs
                    app.relations_list_state.select(None);
                }
                KeyCode::BackTab => {
                    app.prev_tab();
                    app.relations_list_state.select(None);
                }

                // Actions
                KeyCode::Enter => {
                    match app.focus {
                        Focus::WorkItems => app.toggle_expand(),
                        Focus::Preview => {
                            // Open reference in browser (for References tab)
                        }
                    }
                }

                // Toggle expand/collapse all
                KeyCode::Char('t') => app.toggle_expand_all(),

                // Pin/unpin item (pins parent if child selected)
                KeyCode::Char('p') => app.toggle_pin(),

                // Modes
                KeyCode::Char('I') => {
                    app.input_mode = InputMode::SprintSelect;
                    app.dropdown_list_state.select(Some(app.selected_sprint_idx));
                }
                KeyCode::Char('P') => {
                    app.input_mode = InputMode::ProjectSelect;
                    app.dropdown_list_state.select(Some(app.current_project_idx));
                }
                KeyCode::Char('S') => {
                    if app.selected_work_item().is_some() {
                        app.input_mode = InputMode::EditState;
                        app.dropdown_list_state.select(Some(0));
                    }
                }
                KeyCode::Char('f') => {
                    app.search_query.clear();
                    app.input_mode = InputMode::Search;
                }
                KeyCode::Char('A') => {
                    if app.selected_work_item().is_some() && !app.users.is_empty() {
                        app.input_mode = InputMode::EditAssignee;
                        app.dropdown_list_state.select(Some(0));
                    }
                }

                // Open in browser
                KeyCode::Char('o') => {
                    match app.focus {
                        Focus::WorkItems => {
                            // Always open work item in Azure
                            if let (Some(item), Some(project)) = (app.selected_work_item(), app.current_project()) {
                                let url = format!(
                                    "{}/_workitems/edit/{}",
                                    project.organization.trim_end_matches('/'),
                                    item.item.id
                                );
                                if let Err(e) = open::that(&url) {
                                    app.set_error(format!("Failed to open browser: {e}"));
                                } else {
                                    app.set_status(format!("Opened #{}", item.item.id));
                                }
                            }
                        }
                        Focus::Preview => {
                            // On References tab with selection: open relation
                            // Otherwise: open work item
                            if app.preview_tab == crate::app::PreviewTab::References {
                                if let Some(relation) = app.selected_relation() {
                                    if let Some(url) = app.get_relation_url(relation) {
                                        if let Err(e) = open::that(&url) {
                                            app.set_error(format!("Failed to open browser: {e}"));
                                        } else {
                                            let name = relation.attributes.name.as_deref().unwrap_or("link");
                                            app.set_status(format!("Opened {}", name));
                                        }
                                    }
                                } else if let (Some(item), Some(project)) = (app.selected_work_item(), app.current_project()) {
                                    let url = format!(
                                        "{}/_workitems/edit/{}",
                                        project.organization.trim_end_matches('/'),
                                        item.item.id
                                    );
                                    if let Err(e) = open::that(&url) {
                                        app.set_error(format!("Failed to open browser: {e}"));
                                    } else {
                                        app.set_status(format!("Opened #{}", item.item.id));
                                    }
                                }
                            } else if let (Some(item), Some(project)) = (app.selected_work_item(), app.current_project()) {
                                let url = format!(
                                    "{}/_workitems/edit/{}",
                                    project.organization.trim_end_matches('/'),
                                    item.item.id
                                );
                                if let Err(e) = open::that(&url) {
                                    app.set_error(format!("Failed to open browser: {e}"));
                                } else {
                                    app.set_status(format!("Opened #{}", item.item.id));
                                }
                            }
                        }
                    }
                }

                // Copy to clipboard
                KeyCode::Char('y') => {
                    if let Some(item) = app.selected_work_item() {
                        let id = item.item.id.to_string();
                        if let Ok(mut clipboard) = Clipboard::new() {
                            let _ = clipboard.set_text(&id);
                            app.set_status(format!("Copied #{} to clipboard", id));
                        }
                    }
                }
                KeyCode::Char('Y') => {
                    if let Some(item) = app.selected_work_item() {
                        let content = format_ticket_content(&item.item);
                        if let Ok(mut clipboard) = Clipboard::new() {
                            let _ = clipboard.set_text(&content);
                            app.set_status("Copied ticket content to clipboard");
                        }
                    }
                }

                // Filters
                KeyCode::Char('s') => {
                    app.input_mode = InputMode::FilterState;
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char('a') => {
                    app.input_mode = InputMode::FilterAssignee;
                    app.dropdown_list_state.select(Some(0));
                }
                KeyCode::Char('c') => {
                    if app.has_active_filters() {
                        app.clear_filters();
                        app.save_to_cache(); // Persist cleared filters
                        app.set_status("Filters cleared");
                    }
                }

                // Refresh
                KeyCode::Char('r') => {
                    app.set_loading(true, "Refreshing...");
                    // Cache relations before refresh
                    let relations_cache = app.cache_relations();

                    if let Err(e) = app.load_sprints().await {
                        app.set_error(format!("Failed: {e}"));
                    } else if let Err(e) = app.load_work_items().await {
                        app.set_error(format!("Failed: {e}"));
                    } else {
                        let _ = app.load_users().await;
                        // Restore relations after refresh
                        app.restore_relations(relations_cache);
                        app.save_to_cache();
                        app.set_status("Refreshed & cached");
                        // Restart relation loader for any new items
                        app.relations_loader_active = false;
                        app.start_relations_loader();
                    }
                    app.set_loading(false, "");
                }

                _ => {}
            }
        }
    }

    Ok(false)
}
