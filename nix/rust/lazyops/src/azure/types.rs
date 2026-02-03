use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkItem {
    pub id: i32,
    pub rev: i32,
    pub fields: WorkItemFields,
    #[serde(default)]
    pub relations: Option<Vec<WorkItemRelation>>,
    #[serde(skip)]
    pub children: Vec<WorkItem>,
    #[serde(skip)]
    pub depth: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkItemFields {
    #[serde(rename = "System.Title")]
    pub title: String,
    #[serde(rename = "System.State")]
    pub state: String,
    #[serde(rename = "System.WorkItemType")]
    pub work_item_type: String,
    #[serde(rename = "System.AssignedTo")]
    pub assigned_to: Option<AssignedTo>,
    #[serde(rename = "System.IterationPath")]
    pub iteration_path: Option<String>,
    #[serde(rename = "System.Description")]
    pub description: Option<String>,
    #[serde(rename = "System.Parent")]
    pub parent_id: Option<i32>,
    #[serde(rename = "System.CreatedDate")]
    pub created_date: Option<DateTime<Utc>>,
    #[serde(rename = "System.ChangedDate")]
    pub changed_date: Option<DateTime<Utc>>,
    #[serde(rename = "System.Tags")]
    pub tags: Option<String>,
    #[serde(rename = "Microsoft.VSTS.Scheduling.RemainingWork")]
    pub remaining_work: Option<f64>,
    #[serde(rename = "Microsoft.VSTS.Scheduling.OriginalEstimate")]
    pub original_estimate: Option<f64>,
    #[serde(rename = "Microsoft.VSTS.Scheduling.CompletedWork")]
    pub completed_work: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssignedTo {
    #[serde(rename = "displayName")]
    pub display_name: String,
    #[serde(rename = "uniqueName")]
    pub unique_name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkItemRelation {
    pub rel: String,
    pub url: String,
    #[serde(default)]
    pub attributes: WorkItemRelationAttributes,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct WorkItemRelationAttributes {
    #[serde(rename = "name")]
    pub name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sprint {
    pub id: String,
    pub name: String,
    pub path: String,
    pub attributes: SprintAttributes,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SprintAttributes {
    #[serde(rename = "startDate")]
    pub start_date: Option<DateTime<Utc>>,
    #[serde(rename = "finishDate")]
    pub finish_date: Option<DateTime<Utc>>,
    #[serde(rename = "timeFrame")]
    pub time_frame: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    #[serde(rename = "displayName")]
    pub display_name: String,
    #[serde(rename = "uniqueName")]
    pub unique_name: String,
}

impl WorkItem {
    /// State icons - consistent progression from empty to filled to complete
    pub fn state_icon(&self) -> &'static str {
        match self.fields.state.as_str() {
            "New" => "○",                     // Empty circle - not started
            "In Progress" => "◐",             // Half circle - working on it
            "Done In Stage" => "●",           // Filled - staged
            "Done Not Released" => "●",       // Filled - not released
            "Done" => "●",                    // Filled circle - complete
            "Tested w/Bugs" => "●",           // Red dot - has bugs
            "Removed" => "○",                 // Empty (removed/cancelled)
            _ => "○",
        }
    }

    pub fn type_icon(&self) -> &'static str {
        match self.fields.work_item_type.as_str() {
            "Bug" => "⊗",
            "User Story" => "◈",
            "Task" => "☑",
            "Feature" => "★",
            "Epic" => "⚡",
            "Issue" => "⚠",
            "Test Case" => "◇",
            "Product Backlog Item" => "▣",
            _ => "•",
        }
    }

    pub fn available_states(&self) -> Vec<&'static str> {
        match self.fields.work_item_type.as_str() {
            "Task" => vec!["To Do", "In Progress", "Done", "Removed"],
            "Bug" | "Product Backlog Item" | "User Story" => vec![
                "New", "In Progress", "Done In Stage", "Done Not Released",
                "Done", "Tested w/Bugs"
            ],
            _ => vec!["New", "In Progress", "Done In Stage", "Done Not Released", "Done"],
        }
    }
}
