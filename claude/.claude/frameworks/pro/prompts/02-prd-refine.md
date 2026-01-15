# Phase 2: PRD Refinement

> Identify ambiguities and sharpen the PRD through targeted questions.

---

## Purpose

After the initial PRD is created, review it for gaps and ask follow-up questions to resolve ambiguities. The goal is a PRD that is unambiguous enough to build from.

---

## Process

### Step 1: Review the PRD

Read the existing `prd.md` and identify:
- Vague problem statements
- Unclear user definitions
- Ambiguous feature scope
- Untestable acceptance criteria
- Missing edge cases

### Step 2: Ask Focused Questions

Structure questions around these four areas:

1. **Main Problem**: Is the pain point specific and validated?
2. **Main Personas**: Do we know exactly who this is for?
3. **Core Features**: Are all 3 features truly necessary for MVP?
4. **Acceptance Criteria**: Can we write tests against these?

### Step 3: Update PRD

Based on user answers, update the PRD while keeping it spartan. Don't add complexity — clarify what exists.

---

## Question Template

```markdown
## PRD Refinement - Clarifying Questions

I've reviewed the PRD and have the following questions to sharpen it:

### Main Problem
- [Question about problem specificity]
- [Question about validation/evidence]

### Main Personas
- [Question about user definition]
- [Question about context/environment]

### Core Features
- [Question about feature necessity]
- [Question about scope boundaries]

### Acceptance Criteria
- [Question about testability]
- [Question about edge cases]

---

Please answer these questions, and I'll update the PRD accordingly.
Keep answers brief - 1-2 sentences each is ideal.
```

---

## What Makes a Good Refinement Question

**Good questions:**
- "You mention 'quick access' - does that mean <2 seconds or <5 seconds?"
- "Is the target user using this on mobile, desktop, or both?"
- "Feature 2 says 'export data' - which formats are MVP-critical?"
- "What happens if the user has no data yet? Empty state needed?"

**Bad questions (too broad):**
- "Can you tell me more about the users?"
- "What else should this app do?"
- "How should it look?"

---

## Refinement Principles

1. **Still Spartan**: Answers should tighten scope, not expand it
2. **Max 5-7 Questions**: Don't overwhelm — focus on blockers
3. **Testable Outputs**: Every answer should make something more testable
4. **One Round**: Aim to resolve in one Q&A cycle

---

## Output

Updated `prd.md` with:
- Sharper problem statement
- More specific personas
- Clearer feature boundaries
- Testable acceptance criteria

Mark the PRD as "Refined" with date.
