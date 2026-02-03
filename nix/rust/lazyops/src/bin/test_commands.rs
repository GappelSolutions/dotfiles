//! Test binary to verify Azure CLI commands work correctly
//! Run with: cargo run --bin test_commands

use lazyops::azure::AzureCli;
use lazyops::config::Config;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("=== LazyOps Command Tests ===\n");

    // Load config
    let config = Config::load();
    if config.projects.is_empty() {
        eprintln!("ERROR: No projects configured");
        std::process::exit(1);
    }

    let project = &config.projects[0];
    println!("Project: {} ({})", project.name, project.project);
    println!("Org: {}", project.organization);
    println!("Team: {}\n", project.team);

    let client = AzureCli::new(project);

    // Test 1: Get sprints
    println!("--- Test 1: get_sprints ---");
    match client.get_sprints().await {
        Ok(sprints) => {
            println!("✓ Loaded {} sprints", sprints.len());
            if let Some(current) = sprints.iter().find(|s| s.attributes.time_frame.as_deref() == Some("current")) {
                println!("  Current sprint: {} ({})", current.name, current.path);
            }

            // Test 2: Get work items for current sprint
            if let Some(sprint) = sprints.iter().find(|s| s.attributes.time_frame.as_deref() == Some("current")) {
                println!("\n--- Test 2: get_sprint_work_items (with hierarchy debug) ---");
                match client.get_sprint_work_items(&sprint.path).await {
                    Ok(items) => {
                        println!("✓ Loaded {} top-level work items (after hierarchy)", items.len());

                        // Count total items including children
                        fn count_all(items: &[lazyops::azure::WorkItem]) -> usize {
                            items.iter().map(|i| 1 + count_all(&i.children)).sum()
                        }
                        let total = count_all(&items);
                        println!("  Total items (including children): {}", total);

                        // Show hierarchy
                        fn print_tree(items: &[lazyops::azure::WorkItem], indent: usize) {
                            for item in items {
                                let prefix = "  ".repeat(indent);
                                println!("{}#{} [{}] {} (children: {})",
                                    prefix,
                                    item.id,
                                    item.fields.work_item_type,
                                    truncate(&item.fields.title, 30),
                                    item.children.len()
                                );
                                if !item.children.is_empty() {
                                    print_tree(&item.children, indent + 1);
                                }
                            }
                        }

                        println!("\n  Hierarchy (first 10 roots):");
                        print_tree(&items[..items.len().min(10)], 1);
                    }
                    Err(e) => println!("✗ Failed: {}", e),
                }

            }
        }
        Err(e) => println!("✗ Failed: {}", e),
    }

    println!("\n=== Tests Complete ===");
    Ok(())
}

fn truncate(s: &str, max: usize) -> String {
    if s.len() > max {
        format!("{}...", &s[..max-3])
    } else {
        s.to_string()
    }
}
