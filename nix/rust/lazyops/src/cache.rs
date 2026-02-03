use crate::azure::{Sprint, WorkItem, User};
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Serialize, Deserialize)]
pub struct CacheEntry {
    pub timestamp: u64,
    pub sprints: Vec<Sprint>,
    pub work_items: Vec<WorkItem>,
    pub users: Vec<User>,
    pub sprint_path: String,
    #[serde(default)]
    pub filter_state: Option<String>,
    #[serde(default)]
    pub filter_assignee: Option<String>,
    #[serde(default)]
    pub pinned_items: HashSet<i32>,
}

impl CacheEntry {
    pub fn new(
        sprints: Vec<Sprint>,
        work_items: Vec<WorkItem>,
        users: Vec<User>,
        sprint_path: &str,
        filter_state: Option<String>,
        filter_assignee: Option<String>,
        pinned_items: HashSet<i32>,
    ) -> Self {
        Self {
            timestamp: SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|d| d.as_secs())
                .unwrap_or(0),
            sprints,
            work_items,
            users,
            sprint_path: sprint_path.to_string(),
            filter_state,
            filter_assignee,
            pinned_items,
        }
    }

    pub fn age_seconds(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_secs().saturating_sub(self.timestamp))
            .unwrap_or(0)
    }
}

fn cache_dir() -> Option<PathBuf> {
    dirs::cache_dir().map(|d| d.join("lazyops"))
}

fn cache_path(project: &str) -> Option<PathBuf> {
    cache_dir().map(|d| d.join(format!("{}.json", sanitize_filename(project))))
}

fn sanitize_filename(s: &str) -> String {
    s.chars()
        .map(|c| if c.is_alphanumeric() || c == '-' || c == '_' { c } else { '_' })
        .collect()
}

pub fn load(project: &str) -> Option<CacheEntry> {
    let path = cache_path(project)?;
    let contents = std::fs::read_to_string(&path).ok()?;
    serde_json::from_str(&contents).ok()
}

pub fn save(project: &str, entry: &CacheEntry) -> Result<()> {
    let dir = cache_dir().ok_or_else(|| anyhow::anyhow!("No cache directory"))?;
    std::fs::create_dir_all(&dir)?;
    let path = cache_path(project).ok_or_else(|| anyhow::anyhow!("No cache path"))?;
    let contents = serde_json::to_string_pretty(entry)?;
    std::fs::write(path, contents)?;
    Ok(())
}
