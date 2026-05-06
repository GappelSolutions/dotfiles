---
description: Create visual designs and wireframes using Pencil (.pen files) or TUI Studio (.tui files)
---

# Quick Sketch

Create visual designs, wireframes, and UI mockups on the fly.

- **Web/mobile UI**: Use Pencil (.pen files)
- **Terminal UIs (TUIs)**: Use TUI Studio (tui.studio) — open the app, design visually, export Bubble Tea code

## Usage Examples

- `/sketch a login page with email, password, and SSO buttons`
- `/sketch dashboard layout with sidebar nav and data cards`
- `/sketch component library: buttons, inputs, dropdowns, modals`
- `/sketch ~/dev/codelayer-vault/myproject/task/sketch.pen - redesign the header`
- `/sketch a three-pane TUI task manager` (routes to TUI Studio)

## Process

### Step 0: Route by Type

**If the design is a TUI** (terminal app, CLI tool, Bubble Tea, terminal dashboard):
→ Skip to **TUI Design with TUI Studio** section below.

**Otherwise** (web, mobile, dashboard, component library):
→ Continue with Pencil workflow.

### Step 1: Parse the Request

1. **Identify what to design**: UI screens, components, layouts, flows
2. **Check for an existing .pen file path** in the input
3. **Check for file references** to use as context (existing components, screenshots, plan files)

### Step 2: Determine Output Location

- **If a path was provided**: use it directly
- **If in a git repo with a vault task**: `~/dev/codelayer-vault/{project}/TASKNAME/sketch-DESCRIPTION.pen`
- **Otherwise**: `./sketches/DESCRIPTION.pen` in the current directory

Create the output directory if it doesn't exist.

### Step 3: Create the .pen File

1. **Create an empty .pen file** at the determined path:
   - Write `{}` as initial content (Pencil requires pre-created files)
   - If updating an existing .pen file, skip creation

2. **Gather context files** to attach:
   - Any files the user referenced (components, screenshots, plan markdown)
   - If in a project, look for design system files, existing .pen files, or component libraries
   - Keep attachments focused and relevant

### Step 4: Write Pencil Agent Config

Write to `/tmp/pencil-config.json`:

```json
[
  {
    "file": "ABSOLUTE_PATH_TO_PEN_FILE",
    "prompt": "DETAILED_DESIGN_PROMPT",
    "model": "claude-4.6-opus",
    "attachments": ["OPTIONAL_CONTEXT_FILES"]
  }
]
```

**Prompt crafting guidelines:**
- Be specific about layout: grid, sidebar, stack, centered, etc.
- Describe component hierarchy and relationships
- Mention design system/component library if the project uses one (Shadcn, Material, PrimeNG, etc.)
- Include color scheme or theming context if known
- Describe key states: default, hover, active, loading, empty, error
- Mention responsive behavior if relevant
- For wireframes: "Use a clean wireframe style with placeholder content"
- For high-fidelity: reference the project's design tokens or theme

**For multiple views/screens**, create separate entries in the array with separate .pen files.

### Step 5: Launch Pencil

```bash
pencil --agent-config /tmp/pencil-config.json
```

- If `pencil` is not found, inform the user:
  ```
  Pencil CLI not found. Install Pencil from https://pencil.dev (desktop app or VS Code/Cursor extension).
  The empty .pen file has been created at [path] and is ready for when you install it.
  ```

### Step 6: Open & Report

1. **Open the sketch**: `open PATH_TO_PEN_FILE` (opens in Pencil, the default app for .pen files)
2. Tell the user:
   - Where the .pen file(s) were created
   - What design prompt was used
   - Whether Pencil was launched successfully

## TUI Design with TUI Studio

For terminal UIs, use **TUI Studio** instead of Pencil. It's a visual drag-and-drop editor purpose-built for TUI layouts that generates Bubble Tea (Go) code.

### TUI Workflow

1. **Open TUI Studio**: `open -a "TUI Studio"` (installed via nix)
2. **Describe the design** to the user in detail (layout, components, panes, keybindings)
3. **Provide an ASCII wireframe** of each screen in the output — these are the authoritative mockups for character-grid TUIs
4. **Write the design spec** to `~/dev/codelayer-vault/{project}/design.md` with:
   - ASCII wireframes of each screen
   - Color palette (use Iceberg Dark theme in TUI Studio)
   - Component list and keybinding map
   - Link to the plan.md if one exists

### Why Not Pencil for TUIs?

Terminal UIs are character-grid based, not pixel based. Pencil renders text too small to be legible at overview zoom, resulting in unreadable color blocks. ASCII wireframes captured in markdown are the correct representation and can be directly referenced during implementation.

TUI Studio speaks the same language as the implementation (Bubble Tea components, flexbox layout) and can export starter code.

## Tips

- For iterating on an existing sketch, provide the .pen file path: `/sketch path/to/existing.pen - add a footer`
- Attach plan files for context when sketching planned features
- Multiple .pen files can be created in one run for multi-screen flows
- For TUI projects, ASCII wireframes in design.md are the primary deliverable
