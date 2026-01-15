# Phase 6: Epics & Stories Breakdown

> Transform a PRD into a lightweight, structured set of epics and stories for implementation.

---

## Purpose

Take the finalized PRD and break it down into implementable chunks organized by feature. This creates the work breakdown structure for development.

---

## Key Concepts

| Term | Definition |
|------|------------|
| **Feature** | User-visible capability or business outcome (e.g., "AI Chat Assistant") |
| **Epic** | Major deliverable or flow realizing that feature (e.g., chat UX, context layer, prompt logic) |
| **Story** | Increment completing an epic's acceptance criteria |

---

## Principles

1. **Lightweight**: No verbose data models or API contracts — just functional requirements
2. **No Duplication**: Clear separation between epics/stories — no overlapping efforts
3. **UX is First-Class**: UX considerations at epic, story, and task level
4. **Reference PRD**: Story details live in PRD — don't duplicate, reference (e.g., "F3")

---

## Output Structure

```
/docs
├── README.md                    # Explains structure to LLMs
├── features/
│   └── [epic-name]/
│       ├── epic-spec.md         # Epic definition
│       ├── epic-images/         # Design reference images
│       └── [story-name]/
│           ├── story-spec.md    # Story definition
│           └── story-images/    # Story-specific designs
└── pm-notes/
    └── PRD.md                   # Original PRD
```

---

## README Template

```markdown
# Project Documentation

This directory contains the feature breakdown for [Project Name].

## Structure

- `features/` - Contains all epics and stories organized by feature
- `pm-notes/` - Contains the original PRD and other PM artifacts

## For LLMs

When implementing features:

1. **Read the PRD first** (`pm-notes/PRD.md`) for full context
2. **Check for design images** in `epic-images/` and `story-images/` folders
3. **If designs exist**: Review them and ask the user for thoughts on the feature's function before building implementation plans
4. **Story references** (like "F3") point to features defined in the PRD

## Design Images

Design snapshots may or may not be included in each epic/story folder.
- If present: Review before implementation
- If absent: Use PRD descriptions and UX spec as guide

## Story Format

Each story-spec.md contains:
- Functional requirements
- Non-functional requirements
- Acceptance criteria
- PRD references
```

---

## Epic Spec Template

```markdown
# Epic: [Epic Name]

**Feature**: [Parent feature name]
**PRD Reference**: [Feature ID, e.g., F1]

## Overview

[1-2 sentence description of what this epic delivers]

## Scope

**In Scope**:
- [Deliverable 1]
- [Deliverable 2]

**Out of Scope**:
- [What's NOT included]

## Stories

| Story | Description | Priority |
|-------|-------------|----------|
| [story-name] | [Brief description] | P0/P1/P2 |

## UX Considerations

- [Key UX requirement 1]
- [Key UX requirement 2]

## Dependencies

- [Other epics or external dependencies]

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

---

## Story Spec Template

```markdown
# Story: [Story Name]

**Epic**: [Parent epic name]
**PRD Reference**: [Feature ID, e.g., F3.2]
**Priority**: P0 / P1 / P2

## Description

[1-2 sentence description of what this story delivers]

## Functional Requirements

- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]

## Non-Functional Requirements

- [ ] [Performance/Security/Accessibility requirement]

## UX Requirements

- [ ] [UX-specific requirement]
- [ ] [Interaction/feedback requirement]

## Acceptance Criteria

Given [context]
When [action]
Then [expected outcome]

## Design References

See `story-images/` for design snapshots (if available).

## Notes

[Any implementation notes or constraints]
```

---

## Process

### Step 1: Identify Features

From the PRD, identify the top-level features (usually 2-4 for MVP).

### Step 2: Break Down to Epics

For each feature, identify the major flows or deliverables:
- What are the distinct parts that could be built independently?
- What has clear boundaries?

### Step 3: Decompose to Stories

For each epic, create stories that:
- Are independently deployable
- Have clear acceptance criteria
- Reference (don't duplicate) PRD details

### Step 4: Check for Overlap

Review all stories and ensure:
- No duplicate work across stories
- Dependencies are clearly marked
- Sequencing makes sense

---

## Example Breakdown

```
Feature: User Authentication
├── Epic: Sign Up Flow
│   ├── Story: Email/Password Registration
│   ├── Story: Email Verification
│   └── Story: Profile Setup
├── Epic: Sign In Flow
│   ├── Story: Email/Password Login
│   ├── Story: Remember Me
│   └── Story: Forgot Password
└── Epic: Session Management
    ├── Story: Token Refresh
    └── Story: Logout
```

---

## Clarifying Questions to Ask

Before breaking down, clarify:

1. **What's the MVP boundary?** (Which features are must-have vs. nice-to-have?)
2. **Are there existing designs?** (If so, where are they?)
3. **What's the deployment model?** (Affects how stories are scoped)
4. **Any technical constraints?** (Existing systems to integrate with?)

---

## Output

Create the folder structure and files as specified above.

Optionally package as a zip file for handoff.

---

## Integration with Framework

This phase can run:
- **After Phase 2** (PRD Refinement) — if you need work breakdown before UX
- **After Phase 5** (Tech Stack) — if you want full context before breakdown

Recommended: Run after Phase 5 so stories can reference tech decisions.
