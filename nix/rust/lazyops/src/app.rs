use crate::azure::{AzureCli, WorkItem, Sprint, User, WorkItemRelation};
use crate::cache::{self, CacheEntry};
use crate::config::Config;
use anyhow::Result;
use fuzzy_matcher::FuzzyMatcher;
use fuzzy_matcher::skim::SkimMatcherV2;
use ratatui::widgets::ListState;
use std::collections::HashSet;
use tokio::sync::mpsc;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Focus {
    WorkItems,
    Preview,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputMode {
    Normal,
    SprintSelect,
    EditState,
    EditAssignee,
    Search,
    Help,
    ProjectSelect,
    FilterState,
    FilterAssignee,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PreviewTab {
    #[default]
    Details,
    References,
}

impl PreviewTab {
    pub fn next(&self) -> Self {
        match self {
            Self::Details => Self::References,
            Self::References => Self::Details,
        }
    }

    pub fn prev(&self) -> Self {
        match self {
            Self::Details => Self::References,
            Self::References => Self::Details,
        }
    }
}

pub struct App {
    // Config
    pub config: Config,
    pub current_project_idx: usize,

    // UI state
    pub focus: Focus,
    pub input_mode: InputMode,
    pub preview_tab: PreviewTab,

    // Status
    pub status_message: Option<String>,
    pub status_is_error: bool,
    pub loading: bool,

    // Data
    pub sprints: Vec<Sprint>,
    pub selected_sprint_idx: usize,
    pub work_items: Vec<WorkItem>,
    pub users: Vec<User>,
    pub current_user: Option<String>,

    // Selection state
    pub work_item_list_state: ListState,
    pub sprint_list_state: ListState,
    pub dropdown_list_state: ListState,

    // Scroll
    pub preview_scroll: u16,
    pub preview_scroll_max: u16,
    pub refs_scroll: u16,

    // Input
    pub search_query: String,

    // Filters
    pub filter_state: Option<String>,
    pub filter_assignee: Option<String>,

    // Hierarchy
    pub expanded_items: HashSet<i32>,
    pub pinned_items: HashSet<i32>,
    pub force_collapsed: bool, // When true, don't auto-expand during filtering

    // Flattened work items for display
    pub visible_items: Vec<VisibleWorkItem>,

    // Cache
    pub cache_age: Option<u64>,

    // Fuzzy matcher
    pub fuzzy_matcher: SkimMatcherV2,

    // Filter input buffers for fuzzy dropdown filtering
    pub filter_input: String,

    // Loading spinner state (used by ui::draw_loading)
    #[allow(dead_code)]
    pub spinner_frame: usize,

    // Loading message (used by ui::draw_loading)
    #[allow(dead_code)]
    pub loading_message: String,

    // Relations selection (for References tab)
    pub relations_list_state: ListState,

    // IDs of work items with relations already loaded
    pub relations_loaded: HashSet<i32>,

    // Channel for receiving loaded relations from background task
    pub relations_rx: Option<mpsc::Receiver<(i32, Option<Vec<WorkItemRelation>>)>>,
    // Track if background loader is running
    pub relations_loader_active: bool,

    // Cache for PR/commit titles: key is "pr:{id}" or "commit:{hash}"
    pub relation_titles: std::collections::HashMap<String, String>,
    // Channel for receiving titles from background task
    pub titles_rx: Option<mpsc::Receiver<(String, String)>>,
    // Track if title loader is running
    pub titles_loader_active: bool,
}

#[derive(Debug, Clone)]
pub struct VisibleWorkItem {
    pub item: WorkItem,
    pub depth: usize,
    pub has_children: bool,
    pub is_expanded: bool,
    pub is_pinned: bool,
}

/// Parsed relation info for display
pub struct ParsedRelation {
    pub icon: &'static str,
    pub description: String,
    pub url: Option<String>,
}

impl App {
    pub fn new(config: Config) -> Self {
        let default_idx = config.default_project
            .as_ref()
            .and_then(|name| config.projects.iter().position(|p| &p.name == name))
            .unwrap_or(0);

        Self {
            config,
            current_project_idx: default_idx,
            focus: Focus::WorkItems,
            input_mode: InputMode::Normal,
            preview_tab: PreviewTab::default(),
            status_message: None,
            status_is_error: false,
            loading: false,
            sprints: Vec::new(),
            selected_sprint_idx: 0,
            work_items: Vec::new(),
            users: Vec::new(),
            current_user: None,
            work_item_list_state: ListState::default(),
            sprint_list_state: ListState::default(),
            dropdown_list_state: ListState::default(),
            preview_scroll: 0,
            preview_scroll_max: 0,
            refs_scroll: 0,
            search_query: String::new(),
            filter_state: None,
            filter_assignee: None,
            expanded_items: HashSet::new(),
            pinned_items: HashSet::new(),
            force_collapsed: false,
            visible_items: Vec::new(),
            cache_age: None,
            fuzzy_matcher: SkimMatcherV2::default(),
            filter_input: String::new(),
            spinner_frame: 0,
            loading_message: String::new(),
            relations_list_state: ListState::default(),
            relations_loaded: HashSet::new(),
            relations_rx: None,
            relations_loader_active: false,
            relation_titles: std::collections::HashMap::new(),
            titles_rx: None,
            titles_loader_active: false,
        }
    }

    /// Poll for loaded titles from background task (non-blocking)
    pub fn poll_titles(&mut self) {
        let mut results = Vec::new();
        let mut channel_closed = false;

        if let Some(rx) = &mut self.titles_rx {
            loop {
                match rx.try_recv() {
                    Ok(item) => results.push(item),
                    Err(mpsc::error::TryRecvError::Empty) => break,
                    Err(mpsc::error::TryRecvError::Disconnected) => {
                        channel_closed = true;
                        break;
                    }
                }
            }
        }

        for (key, title) in results {
            self.relation_titles.insert(key, title);
        }

        // Reset flag when loader finishes so it can restart for new relations
        if channel_closed {
            self.titles_loader_active = false;
            self.titles_rx = None;
        }
    }

    /// Get cached title for a relation key
    #[allow(dead_code)]
    pub fn get_relation_title(&self, key: &str) -> Option<&String> {
        self.relation_titles.get(key)
    }

    /// Poll for loaded relations from background task (non-blocking)
    pub fn poll_relations(&mut self) {
        // Collect results first to avoid borrow issues
        let mut results = Vec::new();
        if let Some(rx) = &mut self.relations_rx {
            while let Ok(item) = rx.try_recv() {
                results.push(item);
            }
        }
        // Then apply them
        for (id, relations) in results {
            self.update_work_item_relations(id, relations);
        }
    }

    /// Start background title loader for PRs and commits
    pub fn start_titles_loader(&mut self) {
        if self.titles_loader_active {
            return;
        }

        // Collect all PR IDs and commit hashes that need titles
        let mut pr_ids: Vec<String> = Vec::new();
        let mut commits: Vec<(String, String)> = Vec::new(); // (repo_guid, hash)

        fn collect_from_items(items: &[WorkItem], pr_ids: &mut Vec<String>, commits: &mut Vec<(String, String)>, existing: &std::collections::HashMap<String, String>) {
            for item in items {
                if let Some(relations) = &item.relations {
                    for rel in relations {
                        let name = rel.attributes.name.as_deref().unwrap_or("");
                        let parts: Vec<&str> = rel.url.split("%2F").flat_map(|s| s.split("%2f")).collect();

                        match name {
                            "Pull Request" => {
                                if let Some(pr_id) = parts.last() {
                                    let key = format!("pr:{}", pr_id);
                                    if !existing.contains_key(&key) {
                                        pr_ids.push(pr_id.to_string());
                                    }
                                }
                            }
                            "Fixed in Commit" => {
                                if parts.len() >= 2 {
                                    let hash = parts[parts.len() - 1];
                                    let repo = parts[parts.len() - 2];
                                    let key = format!("commit:{}", hash);
                                    if !existing.contains_key(&key) {
                                        commits.push((repo.to_string(), hash.to_string()));
                                    }
                                }
                            }
                            _ => {}
                        }
                    }
                }
                collect_from_items(&item.children, pr_ids, commits, existing);
            }
        }

        collect_from_items(&self.work_items, &mut pr_ids, &mut commits, &self.relation_titles);

        if pr_ids.is_empty() && commits.is_empty() {
            return;
        }

        let (tx, rx) = mpsc::channel(100);
        self.titles_rx = Some(rx);
        self.titles_loader_active = true;

        let client_info = self.current_project().map(|p| (p.organization.clone(), p.project.clone()));

        if let Some((org, project)) = client_info {
            tokio::spawn(async move {
                // Fetch PR titles in parallel
                let pr_futures: Vec<_> = pr_ids.into_iter().map(|pr_id| {
                    let org = org.clone();
                    let tx = tx.clone();
                    async move {
                        let output = tokio::process::Command::new("az")
                            .args(["repos", "pr", "show"])
                            .args(["--id", &pr_id])
                            .args(["--org", &org])
                            .args(["--output", "json"])
                            .output()
                            .await;

                        if let Ok(o) = output {
                            if o.status.success() {
                                if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&o.stdout) {
                                    if let Some(title) = json.get("title").and_then(|t| t.as_str()) {
                                        let key = format!("pr:{}", pr_id);
                                        let _ = tx.send((key, title.to_string())).await;
                                    }
                                }
                            }
                        }
                    }
                }).collect();

                // Fetch commit messages in parallel
                let commit_futures: Vec<_> = commits.into_iter().map(|(repo_guid, hash)| {
                    let org = org.clone();
                    let project = project.clone();
                    let tx = tx.clone();
                    async move {
                        let output = tokio::process::Command::new("az")
                            .args(["devops", "invoke"])
                            .args(["--area", "git"])
                            .args(["--resource", "commits"])
                            .args(["--route-parameters", &format!("project={}", project), &format!("repositoryId={}", repo_guid), &format!("commitId={}", hash)])
                            .args(["--org", &org])
                            .args(["--output", "json"])
                            .output()
                            .await;

                        if let Ok(o) = output {
                            if o.status.success() {
                                if let Ok(json) = serde_json::from_slice::<serde_json::Value>(&o.stdout) {
                                    if let Some(comment) = json.get("comment").and_then(|c| c.as_str()) {
                                        let title = comment.lines().next().unwrap_or(comment);
                                        let key = format!("commit:{}", hash);
                                        let _ = tx.send((key, title.to_string())).await;
                                    }
                                }
                            }
                        }
                    }
                }).collect();

                // Run all requests in parallel
                futures::future::join_all(pr_futures).await;
                futures::future::join_all(commit_futures).await;
            });
        }
    }

    /// Start background relation loader
    pub fn start_relations_loader(&mut self) {
        if self.relations_loader_active {
            return; // Already running
        }

        let ids = self.get_ids_needing_relations();
        if ids.is_empty() {
            return;
        }

        let (tx, rx) = mpsc::channel(100);
        self.relations_rx = Some(rx);
        self.relations_loader_active = true;

        // Clone what we need for the background task
        let client_info = self.current_project().map(|p| (p.organization.clone(), p.project.clone()));

        if let Some((org, _project)) = client_info {
            tokio::spawn(async move {
                for id in ids {
                    // Create a fresh client for each request
                    let output = tokio::process::Command::new("az")
                        .args(["boards", "work-item", "show"])
                        .args(["--id", &id.to_string()])
                        .args(["--expand", "relations"])
                        .args(["--org", &org])
                        .args(["--output", "json"])
                        .output()
                        .await;

                    let relations = output.ok().and_then(|o| {
                        if o.status.success() {
                            serde_json::from_slice::<WorkItem>(&o.stdout)
                                .ok()
                                .and_then(|wi| wi.relations)
                        } else {
                            None
                        }
                    });

                    // Send result back (ignore error if receiver dropped)
                    if tx.send((id, relations)).await.is_err() {
                        break; // Receiver dropped, stop loading
                    }

                    // Small delay between requests to avoid overwhelming API
                    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                }
            });
        }
    }

    #[allow(dead_code)] // Used by events.rs
    pub fn set_loading(&mut self, loading: bool, message: &str) {
        self.loading = loading;
        self.loading_message = message.to_string();
    }

    #[allow(dead_code)] // Used by events.rs
    pub fn tick_spinner(&mut self) {
        self.spinner_frame = (self.spinner_frame + 1) % 10;
    }

    #[allow(dead_code)] // Used by ui::draw_loading
    pub fn spinner_char(&self) -> &'static str {
        const SPINNER: [&str; 10] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
        SPINNER[self.spinner_frame]
    }

    /// Load data from cache if available
    pub fn load_from_cache(&mut self) -> bool {
        let project_name = match self.current_project() {
            Some(p) => p.name.clone(),
            None => return false,
        };

        if let Some(entry) = cache::load(&project_name) {
            let age = entry.age_seconds();
            let sprint_path = entry.sprint_path.clone();
            self.sprints = entry.sprints;
            // Rebuild hierarchy since children field is not serialized
            self.work_items = AzureCli::build_hierarchy(entry.work_items);
            self.cache_age = Some(age);

            // Restore filters and pinned items
            self.filter_state = entry.filter_state;
            self.filter_assignee = entry.filter_assignee;
            self.pinned_items = entry.pinned_items;

            // Extract users from work items
            self.extract_users_from_work_items();

            // Find the sprint that matches cached sprint_path
            self.selected_sprint_idx = self.sprints.iter()
                .position(|s| s.path == sprint_path)
                .or_else(|| self.sprints.iter().position(|s| s.attributes.time_frame.as_deref() == Some("current")))
                .unwrap_or(0);

            self.sprint_list_state.select(Some(self.selected_sprint_idx));
            self.rebuild_visible_items();
            if !self.visible_items.is_empty() {
                self.work_item_list_state.select(Some(0));
            }
            true
        } else {
            false
        }
    }

    /// Save current data to cache
    pub fn save_to_cache(&self) {
        let project_name = match self.current_project() {
            Some(p) => p.name.clone(),
            None => return,
        };
        let sprint_path = self.selected_sprint()
            .map(|s| s.path.as_str())
            .unwrap_or("");

        // Flatten hierarchical work items back to flat list for serialization
        // (children field is #[serde(skip)] so we need flat list with parent_id)
        let flat_items = Self::flatten_work_items(&self.work_items);

        let entry = CacheEntry::new(
            self.sprints.clone(),
            flat_items,
            self.users.clone(),
            sprint_path,
            self.filter_state.clone(),
            self.filter_assignee.clone(),
            self.pinned_items.clone(),
        );
        let _ = cache::save(&project_name, &entry);
    }

    /// Flatten hierarchical work items back to a flat list
    fn flatten_work_items(items: &[WorkItem]) -> Vec<WorkItem> {
        let mut result = Vec::new();
        fn collect(items: &[WorkItem], result: &mut Vec<WorkItem>) {
            for item in items {
                // Clone item without children (they'll be added separately)
                let mut flat_item = item.clone();
                flat_item.children.clear();
                result.push(flat_item);
                // Recursively collect children
                collect(&item.children, result);
            }
        }
        collect(items, &mut result);
        result
    }

    pub fn current_project(&self) -> Option<&crate::config::ProjectConfig> {
        self.config.projects.get(self.current_project_idx)
    }

    pub fn client(&self) -> Option<AzureCli> {
        self.current_project().map(AzureCli::new)
    }

    pub fn set_status(&mut self, msg: impl Into<String>) {
        self.status_message = Some(msg.into());
        self.status_is_error = false;
    }

    pub fn set_error(&mut self, msg: impl Into<String>) {
        self.status_message = Some(msg.into());
        self.status_is_error = true;
    }

    pub fn clear_status(&mut self) {
        self.status_message = None;
        self.status_is_error = false;
    }

    // Data loading
    pub async fn load_sprints(&mut self) -> Result<()> {
        let client = self.client().ok_or_else(|| anyhow::anyhow!("No project configured"))?;
        self.sprints = client.get_sprints().await?;

        // Select current sprint by default
        self.selected_sprint_idx = self.sprints.iter()
            .position(|s| s.attributes.time_frame.as_deref() == Some("current"))
            .unwrap_or(0);

        self.sprint_list_state.select(Some(self.selected_sprint_idx));
        Ok(())
    }

    pub async fn load_work_items(&mut self) -> Result<()> {
        let client = self.client().ok_or_else(|| anyhow::anyhow!("No project configured"))?;
        let sprint = self.sprints.get(self.selected_sprint_idx);

        if let Some(sprint) = sprint {
            self.work_items = client.get_sprint_work_items(&sprint.path).await?;
            self.extract_users_from_work_items();
            self.rebuild_visible_items();
            if !self.visible_items.is_empty() {
                self.work_item_list_state.select(Some(0));
            }
        }

        Ok(())
    }

    pub async fn load_users(&mut self) -> Result<()> {
        self.current_user = AzureCli::get_current_user().await.ok();
        Ok(())
    }

    /// Extract unique assignees from work items
    pub fn extract_users_from_work_items(&mut self) {
        let mut seen = std::collections::HashSet::new();
        self.users.clear();

        fn collect_users(items: &[WorkItem], users: &mut Vec<User>, seen: &mut std::collections::HashSet<String>) {
            for item in items {
                if let Some(assignee) = &item.fields.assigned_to {
                    if seen.insert(assignee.unique_name.clone()) {
                        users.push(User {
                            display_name: assignee.display_name.clone(),
                            unique_name: assignee.unique_name.clone(),
                        });
                    }
                }
                collect_users(&item.children, users, seen);
            }
        }

        collect_users(&self.work_items, &mut self.users, &mut seen);
        // Sort by display name
        self.users.sort_by(|a, b| a.display_name.cmp(&b.display_name));
    }

    // Flatten hierarchy for display with filters
    pub fn rebuild_visible_items(&mut self) {
        self.visible_items.clear();

        let query = self.search_query.to_lowercase();
        let filter_state = self.filter_state.clone();
        let filter_assignee = self.filter_assignee.clone();
        let matcher = &self.fuzzy_matcher;
        let pinned = &self.pinned_items;
        let force_collapsed = self.force_collapsed;

        fn flatten(
            items: &[WorkItem],
            visible: &mut Vec<VisibleWorkItem>,
            expanded: &HashSet<i32>,
            pinned: &HashSet<i32>,
            depth: usize,
            query: &str,
            filter_state: &Option<String>,
            filter_assignee: &Option<String>,
            matcher: &SkimMatcherV2,
            force_collapsed: bool,
        ) -> bool {
            let mut has_match = false;

            for item in items {
                // Apply filters
                let state_match = filter_state.as_ref()
                    .map(|s| item.fields.state.eq_ignore_ascii_case(s))
                    .unwrap_or(true);
                let assignee_match = filter_assignee.as_ref()
                    .map(|a| {
                        if a == "Unassigned" {
                            item.fields.assigned_to.is_none()
                        } else {
                            item.fields.assigned_to.as_ref()
                                .map(|at| at.display_name.eq_ignore_ascii_case(a))
                                .unwrap_or(false)
                        }
                    })
                    .unwrap_or(true);

                let has_children = !item.children.is_empty();
                let is_expanded = expanded.contains(&item.id);
                let is_pinned = depth == 0 && pinned.contains(&item.id);

                // Check if any filters/search are active
                let has_active_filter = !query.is_empty() || filter_state.is_some() || filter_assignee.is_some();

                // Only check child matches when filters are active
                let mut child_matches = false;
                if has_children && has_active_filter {
                    let mut temp = Vec::new();
                    child_matches = flatten(&item.children, &mut temp, expanded, pinned, depth + 1, query, filter_state, filter_assignee, matcher, force_collapsed);
                }

                let passes_filter = state_match && assignee_match;

                // Fuzzy search on title and ID
                let passes_search = if query.is_empty() {
                    true
                } else {
                    let title_match = matcher.fuzzy_match(&item.fields.title, query).is_some();
                    let id_match = item.id.to_string().contains(query);
                    let type_match = matcher.fuzzy_match(&item.fields.work_item_type, query).is_some();
                    title_match || id_match || type_match
                };

                // Show if passes all filters, OR if a child matches (during filter mode)
                let should_show = (passes_filter && passes_search) || child_matches;

                if should_show {
                    has_match = true;
                    // Only auto-expand when a child matches during filtering (unless force_collapsed)
                    let show_expanded = is_expanded || (has_active_filter && child_matches && !force_collapsed);
                    visible.push(VisibleWorkItem {
                        item: item.clone(),
                        depth,
                        has_children,
                        is_expanded: show_expanded,
                        is_pinned,
                    });

                    // Only show children if explicitly expanded OR child matches filter
                    if show_expanded && has_children {
                        flatten(&item.children, visible, expanded, pinned, depth + 1, query, filter_state, filter_assignee, matcher, force_collapsed);
                    }
                }
            }

            has_match
        }

        // Process pinned root items first, then non-pinned (keeps children with parents)
        // Collect indices to avoid borrowing issues
        let pinned_indices: Vec<usize> = self.work_items.iter()
            .enumerate()
            .filter(|(_, i)| pinned.contains(&i.id))
            .map(|(idx, _)| idx)
            .collect();
        let non_pinned_indices: Vec<usize> = self.work_items.iter()
            .enumerate()
            .filter(|(_, i)| !pinned.contains(&i.id))
            .map(|(idx, _)| idx)
            .collect();

        // Flatten pinned items first
        for idx in pinned_indices {
            flatten(&self.work_items[idx..idx+1], &mut self.visible_items, &self.expanded_items, pinned, 0, &query, &filter_state, &filter_assignee, matcher, force_collapsed);
        }

        // Then flatten non-pinned items
        for idx in non_pinned_indices {
            flatten(&self.work_items[idx..idx+1], &mut self.visible_items, &self.expanded_items, pinned, 0, &query, &filter_state, &filter_assignee, matcher, force_collapsed);
        }

        // Reset selection if out of bounds
        if let Some(selected) = self.work_item_list_state.selected() {
            if selected >= self.visible_items.len() {
                self.work_item_list_state.select(if self.visible_items.is_empty() { None } else { Some(0) });
            }
        }
    }

    pub fn selected_work_item(&self) -> Option<&VisibleWorkItem> {
        self.work_item_list_state.selected().and_then(|i| self.visible_items.get(i))
    }

    pub fn selected_sprint(&self) -> Option<&Sprint> {
        self.sprints.get(self.selected_sprint_idx)
    }

    /// Toggle pin on currently selected item (or its parent if it's a child)
    pub fn toggle_pin(&mut self) {
        if let Some(vi) = self.selected_work_item() {
            // If it's a child, find and pin/unpin its parent instead
            let id = if vi.depth > 0 {
                vi.item.fields.parent_id.unwrap_or(vi.item.id)
            } else {
                vi.item.id
            };

            if self.pinned_items.contains(&id) {
                self.pinned_items.remove(&id);
            } else {
                self.pinned_items.insert(id);
            }
            self.rebuild_visible_items();
            self.save_to_cache();
        }
    }

    // Navigation
    pub fn list_next(&mut self) {
        let len = self.visible_items.len();
        if len == 0 { return; }
        // Stop at bottom, don't wrap
        let i = self.work_item_list_state.selected()
            .map(|i| (i + 1).min(len - 1))
            .unwrap_or(0);
        self.work_item_list_state.select(Some(i));
        self.preview_scroll = 0;
    }

    pub fn list_prev(&mut self) {
        let len = self.visible_items.len();
        if len == 0 { return; }
        // Stop at top, don't wrap
        let i = self.work_item_list_state.selected()
            .map(|i| i.saturating_sub(1))
            .unwrap_or(0);
        self.work_item_list_state.select(Some(i));
        self.preview_scroll = 0;
    }

    pub fn list_top(&mut self) {
        if !self.visible_items.is_empty() {
            self.work_item_list_state.select(Some(0));
            self.preview_scroll = 0;
        }
    }

    pub fn list_bottom(&mut self) {
        if !self.visible_items.is_empty() {
            self.work_item_list_state.select(Some(self.visible_items.len() - 1));
            self.preview_scroll = 0;
        }
    }

    pub fn list_jump_down(&mut self) {
        let len = self.visible_items.len();
        if len == 0 { return; }
        let jump = 10; // Jump 10 items
        let i = self.work_item_list_state.selected()
            .map(|i| (i + jump).min(len - 1))
            .unwrap_or(0);
        self.work_item_list_state.select(Some(i));
        self.preview_scroll = 0;
    }

    pub fn list_jump_up(&mut self) {
        let len = self.visible_items.len();
        if len == 0 { return; }
        let jump = 10; // Jump 10 items
        let i = self.work_item_list_state.selected()
            .map(|i| i.saturating_sub(jump))
            .unwrap_or(0);
        self.work_item_list_state.select(Some(i));
        self.preview_scroll = 0;
    }

    pub fn toggle_expand(&mut self) {
        if let Some(item) = self.selected_work_item() {
            let id = item.item.id;
            if item.has_children {
                if self.expanded_items.contains(&id) {
                    self.expanded_items.remove(&id);
                } else {
                    self.expanded_items.insert(id);
                }
                self.rebuild_visible_items();
            }
        }
    }

    /// Expand all items with children
    pub fn expand_all(&mut self) {
        // Remember current selection
        let selected_id = self.selected_work_item().map(|w| w.item.id);

        fn collect_ids(items: &[WorkItem], ids: &mut HashSet<i32>) {
            for item in items {
                if !item.children.is_empty() {
                    ids.insert(item.id);
                    collect_ids(&item.children, ids);
                }
            }
        }
        collect_ids(&self.work_items, &mut self.expanded_items);
        self.rebuild_visible_items();

        // Restore selection
        if let Some(id) = selected_id {
            if let Some(pos) = self.visible_items.iter().position(|v| v.item.id == id) {
                self.work_item_list_state.select(Some(pos));
            }
        }
    }

    /// Collapse all items
    pub fn collapse_all(&mut self) {
        // Remember current selection
        let selected_id = self.selected_work_item().map(|w| w.item.id);

        self.expanded_items.clear();
        self.rebuild_visible_items();

        // Restore selection
        if let Some(id) = selected_id {
            if let Some(pos) = self.visible_items.iter().position(|v| v.item.id == id) {
                self.work_item_list_state.select(Some(pos));
            }
        }
    }

    /// Toggle between all expanded and all collapsed
    pub fn toggle_expand_all(&mut self) {
        // If currently force-collapsed or all collapsed, expand
        // Otherwise collapse
        if self.force_collapsed || self.expanded_items.is_empty() {
            self.force_collapsed = false;
            self.expand_all();
        } else {
            self.force_collapsed = true;
            self.collapse_all();
        }
    }

    pub fn scroll_preview_down(&mut self) {
        self.preview_scroll = self.preview_scroll.saturating_add(10).min(self.preview_scroll_max);
    }

    pub fn scroll_preview_up(&mut self) {
        self.preview_scroll = self.preview_scroll.saturating_sub(10);
    }

    pub fn next_tab(&mut self) {
        self.preview_tab = self.preview_tab.next();
        self.preview_scroll = 0;
    }

    pub fn prev_tab(&mut self) {
        self.preview_tab = self.preview_tab.prev();
        self.preview_scroll = 0;
    }

    /// Update relations for a work item by ID (in both work_items tree and visible_items)
    pub fn update_work_item_relations(&mut self, id: i32, relations: Option<Vec<crate::azure::WorkItemRelation>>) {
        // Update in hierarchical work_items
        fn update_in_tree(items: &mut [WorkItem], id: i32, relations: &Option<Vec<crate::azure::WorkItemRelation>>) -> bool {
            for item in items.iter_mut() {
                if item.id == id {
                    item.relations = relations.clone();
                    return true;
                }
                if update_in_tree(&mut item.children, id, relations) {
                    return true;
                }
            }
            false
        }
        update_in_tree(&mut self.work_items, id, &relations);

        // Update in visible_items
        for vi in &mut self.visible_items {
            if vi.item.id == id {
                vi.item.relations = relations.clone();
                break;
            }
        }

        // Mark as loaded
        self.relations_loaded.insert(id);
    }

    /// Get all work item IDs that need relations loaded
    pub fn get_ids_needing_relations(&self) -> Vec<i32> {
        fn collect_ids(items: &[WorkItem], loaded: &HashSet<i32>, result: &mut Vec<i32>) {
            for item in items {
                if !loaded.contains(&item.id) {
                    result.push(item.id);
                }
                collect_ids(&item.children, loaded, result);
            }
        }
        let mut ids = Vec::new();
        collect_ids(&self.work_items, &self.relations_loaded, &mut ids);
        ids
    }

    /// Cache all loaded relations before refresh
    pub fn cache_relations(&self) -> std::collections::HashMap<i32, Vec<crate::azure::WorkItemRelation>> {
        fn collect(items: &[WorkItem], cache: &mut std::collections::HashMap<i32, Vec<crate::azure::WorkItemRelation>>) {
            for item in items {
                if let Some(relations) = &item.relations {
                    cache.insert(item.id, relations.clone());
                }
                collect(&item.children, cache);
            }
        }
        let mut cache = std::collections::HashMap::new();
        collect(&self.work_items, &mut cache);
        cache
    }

    /// Restore cached relations after refresh
    pub fn restore_relations(&mut self, cache: std::collections::HashMap<i32, Vec<crate::azure::WorkItemRelation>>) {
        fn restore(items: &mut [WorkItem], cache: &std::collections::HashMap<i32, Vec<crate::azure::WorkItemRelation>>) {
            for item in items.iter_mut() {
                if let Some(relations) = cache.get(&item.id) {
                    item.relations = Some(relations.clone());
                }
                restore(&mut item.children, cache);
            }
        }
        restore(&mut self.work_items, &cache);
        // Also update visible items
        for vi in &mut self.visible_items {
            if let Some(relations) = cache.get(&vi.item.id) {
                vi.item.relations = Some(relations.clone());
            }
        }
    }

    /// Get relations for the selected work item, grouped and sorted
    /// Order: Children, Attachments, PRs, Commits, Other
    pub fn selected_relations(&self) -> Vec<&crate::azure::WorkItemRelation> {
        let Some(vi) = self.selected_work_item() else {
            return Vec::new();
        };
        let Some(relations) = vi.item.relations.as_ref() else {
            return Vec::new();
        };

        // Filter out parent links (Hierarchy-Reverse) only
        let mut refs: Vec<&crate::azure::WorkItemRelation> = relations.iter()
            .filter(|r| r.rel != "System.LinkTypes.Hierarchy-Reverse")
            .collect();

        // Sort by type priority
        refs.sort_by_key(|r| {
            // Check rel type first for special cases
            if r.rel == "System.LinkTypes.Hierarchy-Forward" {
                return 0; // Children
            }
            if r.rel == "AttachedFile" {
                return 1; // Attachments
            }

            let name = r.attributes.name.as_deref().unwrap_or("");
            match name {
                "Child" => 0,
                "Pull Request" => 2,
                "Fixed in Commit" => 3,
                "Branch" => 4,
                _ => 5, // Other
            }
        });

        refs
    }

    /// Navigate relations list
    pub fn relations_next(&mut self) {
        let len = self.selected_relations().len();
        if len == 0 { return; }
        let i = self.relations_list_state.selected()
            .map(|i| (i + 1).min(len - 1))
            .unwrap_or(0);
        self.relations_list_state.select(Some(i));
    }

    pub fn relations_prev(&mut self) {
        let len = self.selected_relations().len();
        if len == 0 { return; }
        let i = self.relations_list_state.selected()
            .map(|i| i.saturating_sub(1))
            .unwrap_or(0);
        self.relations_list_state.select(Some(i));
    }

    pub fn relations_page_down(&mut self) {
        let len = self.selected_relations().len();
        if len == 0 { return; }
        let i = self.relations_list_state.selected()
            .map(|i| (i + 10).min(len - 1))
            .unwrap_or(0);
        self.relations_list_state.select(Some(i));
    }

    pub fn relations_page_up(&mut self) {
        let len = self.selected_relations().len();
        if len == 0 { return; }
        let i = self.relations_list_state.selected()
            .map(|i| i.saturating_sub(10))
            .unwrap_or(0);
        self.relations_list_state.select(Some(i));
    }

    /// Get the selected relation
    pub fn selected_relation(&self) -> Option<&crate::azure::WorkItemRelation> {
        let refs = self.selected_relations();
        self.relations_list_state.selected().and_then(|i| refs.get(i).copied())
    }

    /// Parse a relation into display-friendly format
    pub fn parse_relation(&self, relation: &crate::azure::WorkItemRelation) -> ParsedRelation {
        let project_config = self.current_project();
        let base = project_config.map(|p| p.organization.trim_end_matches('/').to_string());
        let project_name = project_config.map(|p| p.project.replace(' ', "%20"));

        let name = relation.attributes.name.as_deref().unwrap_or("");

        // Parse artifact URL: vstfs:///Git/{Type}/{projectGuid}%2F{repoGuid}%2F{id}
        // We need to extract repoGuid for proper URLs
        let parts: Vec<&str> = relation.url
            .split("%2F")
            .flat_map(|s| s.split("%2f"))
            .collect();

        match name {
            "Pull Request" => {
                // parts: ["vstfs:", "", "", "Git", "PullRequestId", "{projectGuid}", "{repoGuid}", "{prId}"]
                let pr_id = parts.last().unwrap_or(&"?");
                let repo_guid = if parts.len() >= 3 { parts[parts.len() - 2] } else { "" };

                let url = match (&base, &project_name) {
                    (Some(b), Some(p)) if !repo_guid.is_empty() => {
                        Some(format!("{}/{}/_git/{}/pullrequest/{}", b, p, repo_guid, pr_id))
                    }
                    (Some(b), Some(p)) => {
                        Some(format!("{}/{}/_git/pullrequest/{}", b, p, pr_id))
                    }
                    _ => None,
                };

                // Use cached title if available
                let key = format!("pr:{}", pr_id);
                let description = if let Some(title) = self.relation_titles.get(&key) {
                    format!("#{} {}", pr_id, title)
                } else {
                    format!("PR #{}", pr_id)
                };

                ParsedRelation {
                    icon: "⎇",
                    description,
                    url,
                }
            }
            "Fixed in Commit" => {
                // parts: ["vstfs:", "", "", "Git", "Commit", "{projectGuid}", "{repoGuid}", "{commitHash}"]
                let hash = parts.last().unwrap_or(&"?");
                let repo_guid = if parts.len() >= 3 { parts[parts.len() - 2] } else { "" };
                let short_hash = if hash.len() > 7 { &hash[..7] } else { hash };

                let url = match (&base, &project_name) {
                    (Some(b), Some(p)) if !repo_guid.is_empty() => {
                        Some(format!("{}/{}/_git/{}/commit/{}", b, p, repo_guid, hash))
                    }
                    (Some(b), Some(p)) => {
                        Some(format!("{}/{}/_git/commit/{}", b, p, hash))
                    }
                    _ => None,
                };

                // Use cached title if available
                let key = format!("commit:{}", hash);
                let description = if let Some(title) = self.relation_titles.get(&key) {
                    format!("{} {}", short_hash, title)
                } else {
                    format!("{}", short_hash)
                };

                ParsedRelation {
                    icon: "●",
                    description,
                    url,
                }
            }
            "Branch" => {
                let branch = parts.last().unwrap_or(&"?");

                ParsedRelation {
                    icon: "⌥",
                    description: format!("Branch {}", branch),
                    url: None,
                }
            }
            "Child" | "" if relation.rel == "System.LinkTypes.Hierarchy-Forward" => {
                // Child work item - extract ID from URL
                let id = relation.url.split('/').last().unwrap_or("?");
                let url = match (&base, &project_name) {
                    (Some(b), Some(p)) => Some(format!("{}/{}/_workitems/edit/{}", b, p, id)),
                    (Some(b), None) => Some(format!("{}/_workitems/edit/{}", b, id)),
                    _ => None,
                };

                // Try to find title from our work items
                let title = self.find_work_item_title(id.parse().unwrap_or(0));
                let description = if let Some(t) = title {
                    format!("#{} {}", id, t)
                } else {
                    format!("#{}", id)
                };

                ParsedRelation {
                    icon: "◇",
                    description,
                    url,
                }
            }
            _ if relation.rel == "AttachedFile" => {
                // For attachments, attributes.name contains the filename (not "AttachedFile")
                // The relation type is identified by rel="AttachedFile"
                let filename = relation.attributes.name.as_deref().unwrap_or("attachment");

                // Build URL: {base_url}?fileName={filename}&download=false
                // URL encode the filename for the query parameter
                let encoded_filename = filename.replace(' ', "%20");
                let url = if relation.url.contains("?") {
                    Some(format!("{}&fileName={}&download=false", relation.url, encoded_filename))
                } else {
                    Some(format!("{}?fileName={}&download=false", relation.url, encoded_filename))
                };

                ParsedRelation {
                    icon: "📎",
                    description: filename.to_string(),
                    url,
                }
            }
            _ => {
                // Work item link - extract ID from URL (last path segment)
                let id = relation.url.split('/').last().unwrap_or("?");
                let url = match (&base, &project_name) {
                    (Some(b), Some(p)) => Some(format!("{}/{}/_workitems/edit/{}", b, p, id)),
                    (Some(b), None) => Some(format!("{}/_workitems/edit/{}", b, id)),
                    _ => None,
                };

                // Try to find title
                let title = self.find_work_item_title(id.parse().unwrap_or(0));
                let description = if let Some(t) = title {
                    format!("#{} {}", id, t)
                } else {
                    format!("#{}", id)
                };

                ParsedRelation {
                    icon: "◆",
                    description,
                    url,
                }
            }
        }
    }

    /// Find title for a work item by ID (from loaded work items)
    fn find_work_item_title(&self, id: i32) -> Option<String> {
        fn search(items: &[WorkItem], id: i32) -> Option<String> {
            for item in items {
                if item.id == id {
                    return Some(item.fields.title.clone());
                }
                if let Some(t) = search(&item.children, id) {
                    return Some(t);
                }
            }
            None
        }
        search(&self.work_items, id)
    }

    /// Get URL for opening a relation in Azure DevOps
    pub fn get_relation_url(&self, relation: &crate::azure::WorkItemRelation) -> Option<String> {
        self.parse_relation(relation).url
    }

    // Dropdown navigation (for sprints, states, users)
    pub fn dropdown_next(&mut self, max: usize) {
        if max == 0 { return; }
        let i = self.dropdown_list_state.selected().map(|i| (i + 1) % max).unwrap_or(0);
        self.dropdown_list_state.select(Some(i));
    }

    pub fn dropdown_prev(&mut self, max: usize) {
        if max == 0 { return; }
        let i = self.dropdown_list_state.selected().map(|i| if i == 0 { max - 1 } else { i - 1 }).unwrap_or(0);
        self.dropdown_list_state.select(Some(i));
    }

    // Filter helpers
    pub fn available_filter_states(&self) -> Vec<&'static str> {
        vec!["All", "New", "In Progress", "Done In Stage", "Done Not Released", "Done", "Tested w/Bugs", "Removed"]
    }

    /// Get filtered states based on fuzzy input
    pub fn filtered_states(&self) -> Vec<&'static str> {
        let states = self.available_filter_states();
        if self.filter_input.is_empty() {
            return states;
        }
        states.into_iter()
            .filter(|s| self.fuzzy_matcher.fuzzy_match(s, &self.filter_input).is_some())
            .collect()
    }

    pub fn available_filter_assignees(&self) -> Vec<String> {
        let mut assignees: Vec<String> = vec!["All".to_string(), "Unassigned".to_string()];
        for user in &self.users {
            if !assignees.contains(&user.display_name) {
                assignees.push(user.display_name.clone());
            }
        }
        assignees
    }

    /// Get filtered assignees based on fuzzy input
    pub fn filtered_assignees(&self) -> Vec<String> {
        let assignees = self.available_filter_assignees();
        if self.filter_input.is_empty() {
            return assignees;
        }
        assignees.into_iter()
            .filter(|a| self.fuzzy_matcher.fuzzy_match(a, &self.filter_input).is_some())
            .collect()
    }

    pub fn clear_filters(&mut self) {
        self.filter_state = None;
        self.filter_assignee = None;
        self.force_collapsed = false;
        self.rebuild_visible_items();
    }

    pub fn has_active_filters(&self) -> bool {
        self.filter_state.is_some() || self.filter_assignee.is_some()
    }

    /// Get filtered edit states based on fuzzy input (for changing state)
    pub fn filtered_edit_states(&self) -> Vec<&'static str> {
        let states = self.selected_work_item()
            .map(|w| w.item.available_states())
            .unwrap_or_default();
        if self.filter_input.is_empty() {
            return states;
        }
        states.into_iter()
            .filter(|s| self.fuzzy_matcher.fuzzy_match(s, &self.filter_input).is_some())
            .collect()
    }

    /// Get filtered edit assignees based on fuzzy input (for changing assignee)
    pub fn filtered_edit_assignees(&self) -> Vec<&crate::azure::User> {
        if self.filter_input.is_empty() {
            return self.users.iter().collect();
        }
        self.users.iter()
            .filter(|u| self.fuzzy_matcher.fuzzy_match(&u.display_name, &self.filter_input).is_some())
            .collect()
    }
}
