---
name: handover
description: Produce a handover summary + continuation instructions when context is filling up, so work can resume cleanly (new session, new agent, or after /clear). Use when the user says context is getting full, asks for a handover/handoff, or wants to continue this later.
---

# Handover

Goal: let a fresh agent (or future you) pick up exactly where this session left off, with zero re-derivation.

Produce one message with these sections:

1. **Task** — original goal, 1-2 sentences. What "done" looks like.
2. **State** — what's actually done vs in-progress vs not started. Be concrete: file paths, function names, commit/branch state (`git status`, `git log -1` if relevant).
3. **Decisions made** — choices taken and why, especially ones not obvious from the code (rejected alternatives, constraints discovered mid-task).
4. **Open threads** — dead ends tried and why they failed (so they aren't retried), open questions, anything blocked on the user.
5. **Next step** — the single next concrete action to take, first.

Rules:
- No filler, no re-explaining things derivable from reading the code.
- If the user has an in-progress Plan or Task list, reference it instead of re-summarizing it.
- End by asking whether to paste this into a fresh session/agent now, or keep working.
