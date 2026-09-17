---
name: cleanup
description: End-of-session pass over a long chat's changes — find dead ends, mistakes, and loose ends, re-evaluate the chosen path, before calling the work truly done. Use when a big/long session is wrapping up and the user wants a final review pass, not mid-task review.
---

# Cleanup

Goal: catch what a long session leaves behind before calling it finished. Run once, near the end.

1. **Diff the damage** — `git status` + `git diff` (or the relevant file set) for everything touched this session.
2. **Dead ends** — code, files, or comments left over from approaches that were tried then abandoned mid-session. Remove them.
3. **Mistrials** — debug prints, temp scripts, commented-out old code, TODO markers added as reminders during the session that are now resolved. Remove them.
4. **Re-evaluate the path** — with full hindsight, is the final approach still the right one, or did the session pivot late and leave earlier scaffolding behind? Flag anything that should be reworked, don't silently rewrite big decisions without saying so.
5. **Consistency check** — naming, unused imports/vars, leftover config flags, anything that doesn't match the rest of the codebase's conventions.

Report findings as a short list: what was cleaned, what's left for the user to decide (don't unilaterally revert real decisions, only actual debris). Then apply the safe removals.
