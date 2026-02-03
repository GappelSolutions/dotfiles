use crate::azure::types::*;
use crate::config::ProjectConfig;
use anyhow::{Context, Result};
use tokio::process::Command;
use std::collections::HashMap;
use std::time::Duration;

pub struct AzureCli {
    pub organization: String,
    pub project: String,
    pub team: String,
    pub timeout_secs: u64,
}

impl AzureCli {
    pub fn new(config: &ProjectConfig) -> Self {
        Self {
            organization: config.organization.clone(),
            project: config.project.clone(),
            team: config.team.clone(),
            timeout_secs: 30, // Default timeout
        }
    }

    #[allow(dead_code)] // Public API for custom timeout configuration
    pub fn with_timeout(mut self, timeout_secs: u64) -> Self {
        self.timeout_secs = timeout_secs;
        self
    }

    /// Execute az command and parse JSON output
    async fn exec<T: serde::de::DeserializeOwned>(&self, args: &[&str]) -> Result<T> {
        let timeout = Duration::from_secs(self.timeout_secs);
        let future = Command::new("az")
            .args(args)
            .args(["--org", &self.organization])
            .args(["--project", &self.project])
            .args(["--output", "json"])
            .output();

        let output = tokio::time::timeout(timeout, future)
            .await
            .context("Azure CLI request timed out")?
            .context("Failed to execute az CLI - is Azure CLI installed?")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            // Provide clearer error messages for common issues
            if stderr.contains("login") || stderr.contains("az login") {
                anyhow::bail!("Azure CLI not authenticated. Run: az login");
            }
            if stderr.contains("not found") || stderr.contains("does not exist") {
                anyhow::bail!("Project/team not found. Check config.toml settings.");
            }
            anyhow::bail!("az command failed: {}", stderr.trim());
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        serde_json::from_str(&stdout).context("Failed to parse az output")
    }

    /// Get iterations (sprints) for the team
    pub async fn get_sprints(&self) -> Result<Vec<Sprint>> {
        self.exec(&[
            "boards", "iteration", "team", "list",
            "--team", &self.team,
        ]).await
    }

    /// Get work items for a sprint iteration path
    pub async fn get_sprint_work_items(&self, iteration_path: &str) -> Result<Vec<WorkItem>> {
        let wiql = format!(
            r#"SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.Parent], [System.Description], [System.IterationPath], [System.Tags], [Microsoft.VSTS.Scheduling.RemainingWork], [Microsoft.VSTS.Scheduling.OriginalEstimate], [Microsoft.VSTS.Scheduling.CompletedWork] FROM WorkItems WHERE [System.IterationPath] = '{}' ORDER BY [System.WorkItemType], [System.Title]"#,
            iteration_path
        );

        let items = self.query_work_items(&wiql).await?;
        Ok(Self::build_hierarchy(items))
    }

    /// Execute az command WITHOUT project arg (for work-item show which doesn't accept it)
    #[allow(dead_code)] // Used by test_commands binary
    async fn exec_no_project<T: serde::de::DeserializeOwned>(&self, args: &[&str]) -> Result<T> {
        let timeout = Duration::from_secs(self.timeout_secs);
        let future = Command::new("az")
            .args(args)
            .args(["--org", &self.organization])
            .args(["--output", "json"])
            .output();

        let output = tokio::time::timeout(timeout, future)
            .await
            .context("Azure CLI request timed out")?
            .context("Failed to execute az CLI - is Azure CLI installed?")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            if stderr.contains("login") || stderr.contains("az login") {
                anyhow::bail!("Azure CLI not authenticated. Run: az login");
            }
            anyhow::bail!("az command failed: {}", stderr.trim());
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        serde_json::from_str(&stdout).context("Failed to parse az output")
    }

    /// Get single work item by ID (with relations)
    #[allow(dead_code)]
    pub async fn get_work_item(&self, id: i32) -> Result<WorkItem> {
        self.exec_no_project(&[
            "boards", "work-item", "show",
            "--id", &id.to_string(),
            "--expand", "relations",
        ]).await
    }

    /// Query work items by WIQL - returns full work items directly
    async fn query_work_items(&self, wiql: &str) -> Result<Vec<WorkItem>> {
        // WIQL query returns work items with all requested fields directly
        let items: Vec<WorkItem> = self.exec(&[
            "boards", "query",
            "--wiql", wiql,
        ]).await?;

        Ok(items)
    }

    /// Update a work item field
    pub async fn update_work_item(&self, id: i32, field: &str, value: &str) -> Result<WorkItem> {
        let field_arg = match field {
            "state" => "--state",
            "title" => "--title",
            "assigned-to" => "--assigned-to",
            _ => anyhow::bail!("Unknown field: {}", field),
        };

        // work-item update doesn't accept --project
        self.exec_no_project(&[
            "boards", "work-item", "update",
            "--id", &id.to_string(),
            field_arg, value,
        ]).await
    }

    /// Get team members (kept for API compatibility but users are extracted from work items)
    #[allow(dead_code)]
    pub async fn get_team_members(&self) -> Result<Vec<User>> {
        Ok(vec![]) // Users are now extracted from work items in App
    }

    /// Get current user email from az account
    pub async fn get_current_user() -> Result<String> {
        #[derive(serde::Deserialize)]
        struct Account { user: AccountUser }
        #[derive(serde::Deserialize)]
        struct AccountUser { name: String }

        let timeout = Duration::from_secs(10);
        let future = Command::new("az")
            .args(["account", "show", "--output", "json"])
            .output();

        let output = tokio::time::timeout(timeout, future)
            .await
            .context("Azure CLI request timed out")?
            .context("Failed to get current user")?;

        let account: Account = serde_json::from_slice(&output.stdout)?;
        Ok(account.user.name)
    }

    /// Build parent-child hierarchy from flat list (preserves original order from WIQL)
    pub fn build_hierarchy(items: Vec<WorkItem>) -> Vec<WorkItem> {
        // Track original order from WIQL response (StackRank ordering)
        let order_map: HashMap<i32, usize> = items.iter()
            .enumerate()
            .map(|(idx, item)| (item.id, idx))
            .collect();

        let mut by_id: HashMap<i32, WorkItem> = items.into_iter().map(|i| (i.id, i)).collect();
        let mut children_map: HashMap<i32, Vec<i32>> = HashMap::new();
        let mut root_ids: Vec<i32> = Vec::new();

        for item in by_id.values() {
            if let Some(parent_id) = item.fields.parent_id {
                if by_id.contains_key(&parent_id) {
                    children_map.entry(parent_id).or_default().push(item.id);
                } else {
                    root_ids.push(item.id);
                }
            } else {
                root_ids.push(item.id);
            }
        }

        // Sort by original WIQL order (StackRank)
        root_ids.sort_by_key(|id| order_map.get(id).copied().unwrap_or(usize::MAX));

        // Sort children by original order as well
        for children in children_map.values_mut() {
            children.sort_by_key(|id| order_map.get(id).copied().unwrap_or(usize::MAX));
        }

        fn build_tree(id: i32, by_id: &mut HashMap<i32, WorkItem>, children_map: &HashMap<i32, Vec<i32>>, depth: usize) -> Option<WorkItem> {
            let mut item = by_id.remove(&id)?;
            item.depth = depth;
            if let Some(child_ids) = children_map.get(&id) {
                for &child_id in child_ids {
                    if let Some(child) = build_tree(child_id, by_id, children_map, depth + 1) {
                        item.children.push(child);
                    }
                }
            }
            Some(item)
        }

        root_ids.iter().filter_map(|&id| build_tree(id, &mut by_id, &children_map, 0)).collect()
    }
}
