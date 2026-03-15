---
description: Create visual designs and wireframes using Pencil (.pen files)
---

# Quick Pencil Sketch

Create visual designs, wireframes, and UI mockups on the fly using Pencil.

## Usage Examples

- `/sketch a login page with email, password, and SSO buttons`
- `/sketch dashboard layout with sidebar nav and data cards`
- `/sketch component library: buttons, inputs, dropdowns, modals`
- `/sketch ~/dev/codelayer-vault/myproject/task/sketch.pen - redesign the header`

## Process

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

## Tips

- For iterating on an existing sketch, provide the .pen file path: `/sketch path/to/existing.pen - add a footer`
- Attach plan files for context when sketching planned features
- Multiple .pen files can be created in one run for multi-screen flows
