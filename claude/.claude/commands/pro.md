# PRO Framework - Feature Planning

Plan a new feature using the PRO Framework (Plan, Refine, Orchestrate).

## Framework Location

The full framework documentation is at: `~/.claude/frameworks/pro/PRO-FRAMEWORK.md`

## File Organization

All PRD artifacts are organized by feature in named folders:

```
project-documentation/
├── index.md                           # Index of all planned features
└── features/
    ├── user-authentication/
    │   ├── prd.md
    │   ├── ux-approaches.md
    │   ├── ux-spec.md
    │   └── tech-stack.md
    └── dashboard-analytics/
        ├── prd.md
        └── ...
```

### Folder Naming Convention

Kebab-case feature name (max 40 chars), e.g., `user-auth`, `dashboard-charts`, `global-documents`

### Index File

Create/update `project-documentation/index.md` with each new feature:

```markdown
# Project Documentation Index

| Feature | Status | Folder |
|---------|--------|--------|
| Dashboard Analytics | PRD Complete | [link](features/dashboard-analytics/) |
| User Authentication | Implemented | [link](features/user-authentication/) |
```

Status values: `PRD Draft`, `PRD Complete`, `UX Complete`, `In Development`, `Implemented`

## Workflow

Execute phases sequentially. Wait for user approval before moving to next phase.

### Phase 1: MVP PRD

**Input**: User's feature description (provided as argument or ask for it)

**Process**:
1. Restate the idea in 2-3 sentences to confirm understanding
2. Ask max 3 clarifying questions if critical context is missing
3. Generate a slug from the feature name (kebab-case, concise, max 40 chars)
4. Create folder: `project-documentation/features/{slug}/`
5. Generate PRD using the template below
6. Save to `project-documentation/features/{slug}/prd.md`
7. Update `project-documentation/index.md` (create if doesn't exist)

**PRD Template** (≤1200 words):

```markdown
# [Feature Name] - Product Requirements Document
Date: YYYY-MM-DD

## 1. Executive Summary

**Elevator Pitch** (≤20 words):
> [One sentence]

**Problem Statement** (2-3 sentences):
> [What pain exists]

**Target User**:
> [Who, what they struggle with]

**Proposed Solution** (1-2 sentences):
> [How we solve it]

**MVP Success Metric**:
> [One quantifiable measure]

## 2. Key Features (Max 3)

### Feature 1: [Name]
- **User Story**: As a [persona], I want to [action], so that [benefit]
- **Acceptance Criteria**: Given [context], when [action], then [outcome]
- **Priority**: P0/P1/P2 - [reason]
- **Dependencies/Risks**: [bullets]

[Repeat for Features 2-3]

## 3. Requirements Overview

### Functional
- [Core flows only]

### Non-Functional
- Performance: [target]
- Security: [if applicable]

### UX Requirements
- [Experience goal]
- [Must-have principles]

## 4. Validation Plan
- **Core Hypothesis**: [What we're testing]
- **Key Assumption**: [What must be true]
- **Next Step**: [How to validate]

## 5. Critical Questions
1. What's the ONE thing users must accomplish?
2. How do we know if MVP succeeded?
3. What's explicitly OUT of scope?
4. What's the riskiest assumption?
5. What's the simplest first version?
```

### Phase 2: PRD Refinement

After PRD is created, ask focused questions about:
- **Main problem**: Is it clear and specific?
- **Main personas**: Well-defined?
- **Core features**: Truly minimal?
- **Acceptance criteria**: Testable?

Update PRD based on answers.

### Phase 3: UX Brainstorm

Generate 2-3 philosophically different UX approaches:
1. Map user journey (Entry → Task → Completion)
2. Present each approach with strengths and tradeoffs
3. Save to the feature folder: `{feature-folder}/ux-approaches.md`

### Phase 4: UX Refinement

After user selects approach:
1. Detail components, interactions, states
2. Document accessibility, responsiveness
3. Save to the feature folder: `{feature-folder}/ux-spec.md`
4. Update index.md status to "UX Complete"

### Phase 5: Tech Stack (if needed)

Only if new tech decisions required. Otherwise skip.

### Phase 6: Implementation

Break into epics/stories or proceed directly to code.

## Key Rules

- **MVP only** - No feature creep, no "nice-to-haves"
- **Wait for approval** between phases
- **Ask questions** rather than assume
- **Keep it minimal** - Fewer features, less complexity
- **One feature per folder** - Never mix artifacts from different features

## Output Location

All artifacts go in `project-documentation/features/{slug}/` within the project.

## Resuming Work on Existing Features

If the user wants to continue work on an existing feature:
1. Check `project-documentation/index.md` to find the feature folder
2. Read the existing PRD and any other artifacts
3. Resume from the appropriate phase based on what exists

## Starting the Flow

1. If the user provided a feature description as argument, begin Phase 1 immediately
2. If no description provided, first check if `project-documentation/index.md` exists
   - If it exists, show the user the list of existing features and ask:
     "Would you like to continue an existing feature or start a new one?"
   - If it doesn't exist, ask: "What feature would you like to plan?"
