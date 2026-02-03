use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
pub struct Config {
    pub projects: Vec<ProjectConfig>,
    pub theme: Theme,
    pub settings: Settings,
    pub keybindings: Keybindings,
    pub default_project: Option<String>,
}

/// General application settings
#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
pub struct Settings {
    /// Auto-refresh interval in seconds (0 to disable)
    pub refresh_interval: u64,
    /// Number of items to jump with Ctrl+D/U
    pub page_jump: usize,
    /// API request timeout in seconds
    pub api_timeout: u64,
    /// Delay between parallel API requests (ms) to avoid rate limiting
    pub api_delay_ms: u64,
    /// Cache expiry in seconds (default 1 hour)
    pub cache_expiry: u64,
    /// Custom work item states (leave empty for defaults)
    pub states: Vec<String>,
}

/// Customizable keybindings (single character keys)
#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
pub struct Keybindings {
    // Navigation
    pub down: char,
    pub up: char,
    pub left: char,
    pub right: char,
    pub top: char,
    pub bottom: char,
    // Actions
    pub open: char,
    pub expand: char,
    pub toggle_all: char,
    pub pin: char,
    pub copy_id: char,
    // Filters
    pub search: char,
    pub filter_state: char,
    pub filter_assignee: char,
    pub clear_filters: char,
    // Editing
    pub edit_state: char,
    pub edit_assignee: char,
    // Selection
    pub select_sprint: char,
    pub select_project: char,
    pub refresh: char,
    pub help: char,
    pub quit: char,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ProjectConfig {
    pub name: String,
    pub organization: String,
    pub project: String,
    pub team: String,
    #[serde(default)]
    #[allow(dead_code)]
    pub repository: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(default)]
pub struct Theme {
    pub border: String,
    pub border_active: String,
    pub selected_bg: String,
    pub text: String,
    pub text_muted: String,
    pub highlight: String,
    pub state_new: String,
    pub state_active: String,
    pub state_resolved: String,
    pub state_closed: String,
    pub type_bug: String,
    pub type_story: String,
    pub type_task: String,
    pub type_feature: String,
    pub type_epic: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            projects: vec![],
            theme: Theme::default(),
            settings: Settings::default(),
            keybindings: Keybindings::default(),
            default_project: None,
        }
    }
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            refresh_interval: 300,  // 5 minutes
            page_jump: 10,
            api_timeout: 30,
            api_delay_ms: 50,
            cache_expiry: 3600,     // 1 hour
            states: vec![],         // Use defaults
        }
    }
}

impl Default for Keybindings {
    fn default() -> Self {
        Self {
            // Navigation (vim-style)
            down: 'j',
            up: 'k',
            left: 'h',
            right: 'l',
            top: 'g',
            bottom: 'G',
            // Actions
            open: 'o',
            expand: '\n',  // Enter (handled separately)
            toggle_all: 't',
            pin: 'p',
            copy_id: 'y',
            // Filters
            search: 'f',
            filter_state: 's',
            filter_assignee: 'a',
            clear_filters: 'c',
            // Editing
            edit_state: 'S',
            edit_assignee: 'A',
            // Selection
            select_sprint: 'I',
            select_project: 'P',
            refresh: 'R',
            help: '?',
            quit: 'q',
        }
    }
}

impl Settings {
    /// Get work item states (custom or defaults)
    #[allow(dead_code)] // Public API for custom states configuration
    pub fn get_states(&self) -> Vec<&str> {
        if self.states.is_empty() {
            vec!["All", "New", "In Progress", "Done In Stage", "Done Not Released", "Done", "Tested w/Bugs", "Removed"]
        } else {
            self.states.iter().map(|s| s.as_str()).collect()
        }
    }
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            // One Dark color scheme
            border: "#5c6370".to_string(),           // Gray
            border_active: "#61afef".to_string(),    // Blue
            selected_bg: "#2c323c".to_string(),      // Dark gray
            text: "#abb2bf".to_string(),             // Light gray
            text_muted: "#5c6370".to_string(),       // Muted gray
            highlight: "#61afef".to_string(),        // Blue
            state_new: "#61afef".to_string(),        // Blue
            state_active: "#e5c07b".to_string(),     // Yellow
            state_resolved: "#98c379".to_string(),   // Green
            state_closed: "#5c6370".to_string(),     // Gray
            type_bug: "#e06c75".to_string(),         // Red
            type_story: "#c678dd".to_string(),       // Purple
            type_task: "#61afef".to_string(),        // Blue
            type_feature: "#56b6c2".to_string(),     // Cyan
            type_epic: "#d19a66".to_string(),        // Orange
        }
    }
}

impl Config {
    pub fn load() -> Self {
        // 1. Try XDG config path first (~/.config/lazyops/config.toml)
        // This is the standard on Linux and commonly used on macOS too
        if let Some(home_dir) = dirs::home_dir() {
            let xdg_path = home_dir.join(".config").join("lazyops").join("config.toml");
            if let Ok(contents) = std::fs::read_to_string(&xdg_path) {
                if let Ok(config) = toml::from_str::<Config>(&contents) {
                    if !config.projects.is_empty() {
                        return config;
                    }
                }
            }
        }

        // 2. Try platform-specific config dir (~/Library/Application Support/ on macOS)
        if let Some(config_dir) = dirs::config_dir() {
            let config_path = config_dir.join("lazyops").join("config.toml");
            if let Ok(contents) = std::fs::read_to_string(&config_path) {
                if let Ok(config) = toml::from_str::<Config>(&contents) {
                    if !config.projects.is_empty() {
                        return config;
                    }
                }
            }
        }

        // 3. Try ~/.lazyops.toml
        if let Some(home_dir) = dirs::home_dir() {
            let config_path = home_dir.join(".lazyops.toml");
            if let Ok(contents) = std::fs::read_to_string(&config_path) {
                if let Ok(config) = toml::from_str::<Config>(&contents) {
                    if !config.projects.is_empty() {
                        return config;
                    }
                }
            }
        }

        // Fall back to default (empty)
        Config::default()
    }
}

impl Theme {
    pub fn parse_color(&self, hex: &str) -> ratatui::style::Color {
        // Parse hex color string (e.g., "#61afef")
        if hex.starts_with('#') && hex.len() == 7 {
            if let (Ok(r), Ok(g), Ok(b)) = (
                u8::from_str_radix(&hex[1..3], 16),
                u8::from_str_radix(&hex[3..5], 16),
                u8::from_str_radix(&hex[5..7], 16),
            ) {
                return ratatui::style::Color::Rgb(r, g, b);
            }
        }
        // Fallback to white if parsing fails
        ratatui::style::Color::White
    }

    /// Get color for work item type
    pub fn type_color(&self, work_item_type: &str) -> ratatui::style::Color {
        match work_item_type {
            "Bug" => self.parse_color(&self.type_bug),
            "User Story" | "Product Backlog Item" => self.parse_color(&self.type_story),
            "Task" => self.parse_color(&self.type_task),
            "Feature" => self.parse_color(&self.type_feature),
            "Epic" => self.parse_color(&self.type_epic),
            _ => self.parse_color(&self.text),
        }
    }

    /// Get foreground and background colors for work item type badge
    pub fn type_badge_colors(&self, work_item_type: &str) -> (ratatui::style::Color, ratatui::style::Color) {
        use ratatui::style::Color;
        match work_item_type {
            "Bug" => (Color::Rgb(255, 180, 180), Color::Rgb(80, 30, 30)),
            "User Story" | "Product Backlog Item" => (Color::Rgb(180, 210, 255), Color::Rgb(30, 45, 70)),
            "Task" => (Color::Rgb(255, 230, 150), Color::Rgb(60, 50, 20)),
            "Feature" => (Color::Rgb(180, 240, 240), Color::Rgb(25, 55, 55)),
            "Epic" => (Color::Rgb(230, 180, 255), Color::Rgb(55, 30, 65)),
            _ => (Color::White, Color::DarkGray),
        }
    }

    /// Get color for work item state
    pub fn state_color(&self, state: &str) -> ratatui::style::Color {
        use ratatui::style::Color;
        match state {
            "New" => Color::Rgb(140, 140, 140),
            "In Progress" => Color::Rgb(200, 180, 60),
            "Done In Stage" => Color::Rgb(180, 100, 200),
            "Done Not Released" => Color::Rgb(230, 140, 50),
            "Done" => Color::Rgb(80, 200, 120),
            "Tested w/Bugs" => Color::Rgb(220, 80, 80),
            "Removed" => Color::Rgb(100, 100, 100),
            _ => Color::Rgb(140, 140, 140),
        }
    }

    /// Get background color for state badge
    pub fn state_bg_color(&self, state: &str) -> ratatui::style::Color {
        use ratatui::style::Color;
        match state {
            "New" => Color::Rgb(50, 50, 50),
            "In Progress" => Color::Rgb(60, 55, 20),
            "Done In Stage" => Color::Rgb(55, 30, 60),
            "Done Not Released" => Color::Rgb(65, 45, 20),
            "Done" => Color::Rgb(25, 55, 35),
            "Tested w/Bugs" => Color::Rgb(65, 25, 25),
            "Removed" => Color::Rgb(35, 35, 35),
            _ => Color::Rgb(40, 40, 40),
        }
    }
}
