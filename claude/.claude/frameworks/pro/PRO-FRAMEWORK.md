# PRO Framework

> **P**lan. **R**efine. **O**rchestrate.
>
> An agentic framework for AI agents to build MVPs from concept to implementation.

---

## Overview

This framework guides you through building a tech app MVP in **6 sequential phases**. Each phase produces artifacts that feed into the next.

```
IDEA → [1. PRD] → [2. PRD Refine] → [3. UX Brainstorm] → [4. UX Refine] → [5. Tech Stack] → [6. Epics] → BUILD
```

**Key Principles:**
- **MVP-only**: No feature creep, no future-proofing
- **Artifacts flow forward**: Each phase builds on the previous
- **Questions over assumptions**: Ask when unclear
- **Minimal surface area**: Fewer tools, less complexity

---

## Phase Overview

| Phase | Input | Output | Duration |
|-------|-------|--------|----------|
| 1. MVP PRD | Raw idea | `prd.md` (~1200 words) | First |
| 2. PRD Refinement | `prd.md` | Refined `prd.md` | After user answers |
| 3. UX Brainstorm | `prd.md` | `ux-approaches.md` (2-3 options) | After PRD locked |
| 4. UX Refinement | Chosen approach | `ux-spec.md` | After approach selected |
| 5. Tech Stack | `prd.md` + `ux-spec.md` | `tech-stack.md` | Before implementation |
| 6. Epics & Stories | All above | `/docs` folder structure | Before build |

---

## How to Use This Framework

### For AI Agents

1. **Read this document first** when starting a new app project
2. **Execute phases in order** - don't skip ahead
3. **Create artifacts in feature-specific folders** (see structure below)
4. **Wait for user approval** before moving to next phase
5. **Reference previous artifacts** in each phase
6. **Maintain the index file** to track all planned features

### Folder Structure

```
your-project/
├── project-documentation/
│   ├── index.md                  # Index of all planned features
│   └── features/
│       ├── user-auth/
│       │   ├── prd.md            # Phase 1-2 output
│       │   ├── ux-approaches.md  # Phase 3 output
│       │   ├── ux-spec.md        # Phase 4 output
│       │   └── tech-stack.md     # Phase 5 output
│       └── dashboard/
│           ├── prd.md
│           └── ...
├── docs/                         # Phase 6 output (epics & stories)
│   ├── README.md
│   ├── features/
│   │   └── [epic-name]/
│   │       ├── epic-spec.md
│   │       └── [story-name]/
│   │           └── story-spec.md
│   └── pm-notes/
│       └── PRD.md
├── src/                          # Implementation
└── ...
```

### Feature Folder Naming

Each feature gets its own folder with a kebab-case name (max 40 chars):
- `user-auth`, `dashboard-charts`, `global-documents`

### Index File (`project-documentation/index.md`)

Tracks all planned features with status:

```markdown
# Project Documentation Index

| Feature | Status | Folder |
|---------|--------|--------|
| Dashboard Analytics | In Development | [link](features/dashboard/) |
| User Authentication | Implemented | [link](features/user-auth/) |
```

**Status progression**: `PRD Draft` → `PRD Complete` → `UX Complete` → `In Development` → `Implemented`

---

## Phase 1: MVP PRD

**Goal**: Transform raw idea into concise, actionable product requirements.

**Trigger**: User describes an app idea

**Process**:
1. Restate the idea in 2-3 sentences
2. Ask max 3 clarifying questions if critical context missing
3. Generate PRD using template below

### PRD Template

```markdown
# [MVP Name] - PRD
Date: [YYYY-MM-DD]

## 1. Executive Summary

**Elevator Pitch** (≤20 words):
> [One sentence describing what this does]

**Problem Statement** (2-3 sentences):
> [What pain point exists]

**Target User**:
> [Who they are, what they struggle with]

**Proposed Solution** (1-2 sentences):
> [How we solve it]

**MVP Success Metric**:
> [One quantifiable measure - activation rate, retention, conversion]

## 2. Key Features (Max 3)

### Feature 1: [Name]
- **User Story**: As a [persona], I want to [action], so that I can [benefit]
- **Acceptance Criteria**: Given [context], when [action], then [outcome]
- **Priority**: P0 / P1 / P2 - [reason]
- **Dependencies/Risks**: [1-2 bullets]

### Feature 2: [Name]
[Same structure]

### Feature 3: [Name]
[Same structure]

## 3. Requirements Overview

### Functional (core flows only)
- [Input → Action → Output]
- [Integration points if any]

### Non-Functional (MVP-critical only)
- Performance: [e.g., loads <2s]
- Security: [e.g., JWT auth]
- Accessibility: [minimums]

### UX Requirements
- Experience goal: [one sentence]
- Must-have principles: [2 items]

## 4. Validation Plan

- **Core Hypothesis**: [What we're testing]
- **Key Assumption**: [What must be true]
- **Next Step**: [prototype/survey/early release]

## 5. Critical Questions

1. What's the ONE thing users must accomplish? [≤2 sentences]
2. How do we know if MVP succeeded? [≤2 sentences]
3. What's explicitly OUT of scope? [≤2 sentences]
4. What's the riskiest assumption? [≤2 sentences]
5. What's the simplest first version? [≤2 sentences]
```

### Output Standards
- ≤1200 words total
- Actionable by developers
- MVP only — no "nice-to-haves"
- Each item traces to user problem or success metric

---

## Phase 2: PRD Refinement

**Goal**: Identify and resolve ambiguities in the PRD.

**Trigger**: After Phase 1 PRD is created

**Process**:
1. Review the PRD for gaps
2. Ask focused follow-up questions about:
   - **Main problem**: Is it clear and specific?
   - **Main personas**: Are they well-defined?
   - **Core features**: Are they truly minimal?
   - **Acceptance criteria**: Are they testable?
3. Update PRD based on answers (keep it spartan)

### Refinement Questions Template

```markdown
## PRD Refinement Questions

Based on the PRD, I have the following clarifying questions:

### Main Problem
- [Question about problem clarity]

### Main Personas
- [Question about user definition]

### Core Features
- [Question about scope/priority]

### Acceptance Criteria
- [Question about testability/clarity]

---
Please answer these, and I'll update the PRD accordingly.
```

---

## Phase 3: UX Brainstorm

**Goal**: Generate 2-3 philosophically different UX approaches.

**Trigger**: After PRD is finalized

**Process**:
1. Review the PRD
2. Map the user journey (Entry → Task → Completion)
3. Generate 2-3 distinct approaches (not cosmetic variations)
4. Present with strengths and tradeoffs

### UX Principles Reference

**User-Centered Foundations**:
- User goals → What's the "job to be done"?
- Mental model alignment → Does it match how users think?
- Progressive disclosure → Complexity unfolds gradually
- Feedback → User knows what's happening
- Error prevention → Avoid and handle mistakes

**Information & Interaction**:
- Information architecture → How is data grouped?
- Hierarchy → What draws focus first?
- Affordances → How do users know what's interactive?
- Consistency → Patterns repeat predictably
- Platform conventions → Familiar expectations respected

**Edge Cases**:
- Empty states → How do we onboard?
- Loading → How do we show progress?
- Offline → What happens without network?
- Power users → Are shortcuts available?

### UX Approaches Template

```markdown
# UX Approaches - [Feature Name]

## User Journey

### Entry Point
> [How user arrives, what context they have]

### Task Execution
> [Steps to accomplish goal, feedback at each step]

### Completion
> [How user knows they succeeded, next options]

---

## Approach 1: [Name]

**Core Idea**: [One line summary]

**Flow**: [How user moves through it]

**Strengths**: [What principles this exemplifies]

**Tradeoffs**: [What might be less ideal]

---

## Approach 2: [Name]

[Same structure]

---

## Approach 3: [Name]

[Same structure]

---

## Recommendation

**Suggested approach**: [Which one and why]

**Validation plan**: [How to test it]

**Open questions**: [What needs user data]
```

---

## Phase 4: UX Refinement

**Goal**: Polish chosen approach into production-ready spec.

**Trigger**: After user selects an approach from Phase 3

**Process**:
1. Take the chosen approach
2. Apply systematic refinement to hierarchy, spacing, color
3. Detail each component
4. Document accessibility, responsiveness, performance

### Refinement Checklist

**Hierarchy & Clarity**:
- [ ] Font weight/tone establishes hierarchy (not just size)
- [ ] Competing elements de-emphasized
- [ ] Action hierarchy defined (Primary → Secondary → Tertiary → Destructive)
- [ ] Labels treated as supporting content

**Spacing & Layout**:
- [ ] Non-linear spacing system applied
- [ ] More space around groups than within
- [ ] Max-widths for readability
- [ ] Consistent rhythm and alignment

**Color & Polish**:
- [ ] Grayscale hierarchy established first
- [ ] Colors from defined palette (5-10 shades)
- [ ] Shadows for depth, not decoration
- [ ] Borders reduced where spacing suffices

### UX Spec Template

```markdown
# UX Specification - [Feature Name]

## Chosen Direction
> [Brief description of selected approach]

## Design System Reference
> [Tailwind scale / ShadCN / Custom tokens]

---

## Component Specifications

### Inputs & Forms
| Component | Specification |
|-----------|--------------|
| Inputs | [Padding, background, border-radius] |
| Labels | [Position, style, size] |
| Validation | [Inline feedback approach] |

### Actions & Status
| Component | Specification |
|-----------|--------------|
| Primary Button | [Style, contrast, depth] |
| Secondary Button | [Style] |
| Badges | [Shape, colors] |
| Alerts | [Accent, hierarchy] |

### Navigation
| Component | Specification |
|-----------|--------------|
| Nav style | [Horizontal/vertical, active states] |
| Pagination | [Style, truncation] |

### Content & Layout
| Component | Specification |
|-----------|--------------|
| Cards | [Layout, spacing, hierarchy] |
| Tables | [Striping, borders] |
| Modals | [Shim, spacing, buttons] |
| Empty States | [Visual, CTA, guidance] |

---

## Accessibility
- [ ] Keyboard navigation
- [ ] Focus states
- [ ] Color contrast (WCAG AA)
- [ ] Screen reader labels

## Responsiveness
- Mobile: [Adjustments]
- Tablet: [Adjustments]
- Desktop: [Adjustments]

## Performance
- Loading states: [Skeleton/spinner]
- Transitions: [Duration, easing]
```

---

## Phase 5: Tech Stack Selection

**Goal**: Choose minimal, coherent tech stack for MVP.

**Trigger**: After UX spec is complete

**Process**:
1. Parse PRD + UX for required capabilities
2. Apply preselected/preferred tools where specified
3. Fill gaps with safe defaults
4. Ask only for decisions that materially affect architecture
5. Mark non-required sections as N/A

### Capability Detection

Determine which capabilities are needed based on PRD/UX:

| Capability | Required If... |
|------------|----------------|
| Media/Camera | PRD mentions photo/video capture, scanning |
| Background Tasks | Scheduled sync, notification batching |
| Realtime | Live presence, chat, collaboration |
| Offline | Journeys mention offline usage |
| Payments | In-app purchases, subscriptions |
| Maps/Location | Geofencing, navigation |
| Deep Linking | Shareable links, auth callbacks |
| Push Notifications | Alerts, reminders, messaging |
| LLM | AI features, chat, content generation |
| File Storage | Media uploads, asset management |

### Decision Domains

**Frontend**:
- Core platform (React Native/Expo, Flutter, Web)
- Routing
- State management
- Forms & validation
- UI/styling system
- Networking (REST vs GraphQL)
- Local storage
- Testing

**Backend**:
- API framework
- Database & ORM
- Auth
- Cache & rate limiting
- Background jobs
- File storage
- Realtime (if needed)
- LLM layer (if needed)

**Cross-cutting**:
- CI/CD
- Crash reporting & observability
- Security & privacy
- Deployment/hosting

### Tech Stack Template

```markdown
# Tech Stack - [MVP Name]

## Summary
- [8-12 bullet points of key decisions]

## Decision Table

| Section | Status | Choice | Reason |
|---------|--------|--------|--------|
| frontend.core | Selected | [tool] | [why] |
| frontend.routing | Selected | [tool] | [why] |
| frontend.state | Selected | [tool] | [why] |
| frontend.ui | Selected | [tool] | [why] |
| frontend.networking | Selected | [tool] | [why] |
| backend.api | Selected | [tool] | [why] |
| backend.database | Selected | [tool] | [why] |
| backend.auth | Selected | [tool] | [why] |
| [capability] | N/A | - | [not in PRD] |

## Open Questions

For each unresolved gap:
- **ID**: [short-name]
- **Why it matters**: [1-2 lines]
- **Options**: [A, B, C]
- **Default**: [sensible MVP default]
- **Tradeoffs**: [speed, complexity, cost]
- **Recommendation**: [pick one with rationale]

## Risks & Mitigations

| Risk | Mitigation | Owner |
|------|------------|-------|
| [risk] | [how to address] | [who] |

## Deployment

- Hosting: [service]
- CI/CD: [service]
- Environments: [dev, staging, prod]
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│              PRO FRAMEWORK (Agentic)                     │
│           Plan · Refine · Orchestrate                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. PRD           → Create prd.md (≤1200 words)         │
│     ↓                                                    │
│  2. PRD Refine    → Ask clarifying questions            │
│     ↓                                                    │
│  3. UX Brainstorm → Generate 2-3 approaches             │
│     ↓                                                    │
│  4. UX Refine     → Polish chosen approach              │
│     ↓                                                    │
│  5. Tech Stack    → Select minimal stack                │
│     ↓                                                    │
│  6. Epics/Stories → Break down into work items          │
│     ↓                                                    │
│  BUILD            → Implement with tests                │
│                                                          │
├─────────────────────────────────────────────────────────┤
│  FILE ORGANIZATION:                                      │
│  • project-documentation/index.md     (feature index)   │
│  • project-documentation/features/                      │
│      └── {feature-slug}/              (per feature)    │
│          ├── prd.md                                     │
│          ├── ux-approaches.md                           │
│          ├── ux-spec.md                                 │
│          └── tech-stack.md                              │
├─────────────────────────────────────────────────────────┤
│  KEY RULES:                                              │
│  • MVP only - no future features                        │
│  • Wait for approval between phases                     │
│  • Max 3 features in PRD                                │
│  • Max 3 UX approaches                                  │
│  • One feature per folder                               │
│  • Update index.md with each feature                    │
└─────────────────────────────────────────────────────────┘
```

---

## When to Use Each Phase

| Situation | Start At |
|-----------|----------|
| "I have an app idea" | Phase 1 |
| "Here's my PRD, now what?" | Phase 3 |
| "I know what I want, pick tech" | Phase 5 |
| "Just build this feature" | Skip framework, just code |

---

## Files in This Framework

- `PRO-FRAMEWORK.md` - This file (main guide)
- `prompts/01-prd.md` - PRD generation prompt
- `prompts/02-prd-refine.md` - PRD refinement prompt
- `prompts/03-ux-brainstorm.md` - UX brainstorming prompt
- `prompts/04-ux-refine.md` - UX refinement prompt
- `prompts/05-tech-stack.md` - Tech stack selection prompt
- `prompts/06-epics-stories.md` - Work breakdown into epics & stories

---

*PRO Framework — Plan. Refine. Orchestrate.*
