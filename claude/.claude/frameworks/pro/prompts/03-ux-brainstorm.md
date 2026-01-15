# Phase 3: UX Brainstorming

> Generate 2-3 philosophically different UX approaches for the MVP.

---

## Purpose

Transform the refined PRD into concrete user experience options. The goal is to explore meaningfully different approaches — not cosmetic variations.

---

## Inputs Required

- Finalized `prd.md` from Phase 1-2
- Any additional design constraints or preferences

---

## UX Principles Reference

Use these principles to guide brainstorming:

### A. User-Centered Foundations
- **User goals & tasks**: What's the "job to be done"?
- **Mental model alignment**: Does it match how users think?
- **Progressive disclosure**: How can complexity unfold gradually?
- **Feedback & system status**: How does the user know what's happening?
- **Error prevention & recovery**: How do we avoid and handle mistakes?

### B. Information & Interaction Design
- **Information architecture**: How is data grouped or navigated?
- **Hierarchy & clarity**: What draws focus first?
- **Affordances & signifiers**: How do users know what's interactive?
- **Consistency**: Do patterns repeat predictably?
- **Platform conventions**: Are familiar expectations respected?

### C. Process & Iteration
- Start with functionality, not layout
- Design the smallest useful version
- Don't imply features that don't exist

### D. Accessibility & Inclusivity
- Ensure keyboard/touch/voice compatibility
- Don't rely on color alone for meaning
- Make labels and microcopy actionable

### E. Edge, Loading & Empty States
- **Empty states**: How do we onboard or encourage first use?
- **Loading**: How do we communicate progress?
- **Offline**: What happens when data is missing?
- **Power users**: Are advanced paths available?

---

## Process

### Step 1: Map the User Journey

```markdown
### Entry Point
> How does the user arrive? What context do they have?
> What's visible initially vs. deferred?

### Task Execution
> What are the steps to accomplish the primary task?
> How is progress shown? What feedback occurs?
> How are errors prevented or recovered?

### Completion / Exit
> How do users know they've succeeded?
> What continuation options exist?
> How are failures handled?
```

### Step 2: Generate 2-3 Distinct Approaches

Each approach should be **philosophically different**, not just styled differently.

Examples of different approaches:
- Wizard vs. Single-page vs. Conversational
- List-based vs. Card-based vs. Timeline
- Action-first vs. Content-first vs. Search-first
- Minimal vs. Feature-rich vs. Guided

### Step 3: Document Each Approach

---

## Output Template

```markdown
# UX Approaches - [Feature/MVP Name]

## Feature Overview

**Feature Name**: [from PRD]

**Primary User Goal**: [what user wants to accomplish]

**Success Criteria**: [what success looks like]

**Key Pain Points Solved**: [frustrations addressed]

**Primary Persona**: [who uses this]

---

## User Journey

### Entry Point
> [How user arrives, context, initial view]

### Task Execution
> [Steps, progress indicators, feedback]

### Completion
> [Success confirmation, next steps, failure handling]

---

## Approach 1: [Name/Theme]

**Core Idea**: [One line summary of the UX concept]

**Experience Flow**:
> [How the user moves through it, from entry to success]

**Strengths**:
- [What principles this approach best exemplifies]
- [Why this might work well]

**Risks or Tradeoffs**:
- [What might make this less ideal for certain users]
- [Technical or design complexity]

---

## Approach 2: [Name/Theme]

**Core Idea**: [One line summary]

**Experience Flow**:
> [Step-by-step user experience]

**Strengths**:
- [Benefits]

**Risks or Tradeoffs**:
- [Concerns]

---

## Approach 3: [Name/Theme]

**Core Idea**: [One line summary]

**Experience Flow**:
> [Step-by-step user experience]

**Strengths**:
- [Benefits]

**Risks or Tradeoffs**:
- [Concerns]

---

## Recommendation

**Recommended approach**: [Which one to test first, and why]

**Validation plan**: [How to test - prototype, user feedback, analytics]

**Open questions**: [What's unclear or needs user data before committing]
```

---

## Output

Save to: `project-documentation/ux-approaches.md`

Present to user for selection before proceeding to Phase 4.
