---
description: Generate JSON output of new translations from session
---

Review all changes made in this session and extract new translation strings.

Use grep to search the codebase for existing translation keys. Only include translations that are genuinely NEW - exclude any keys that already exist in translation files or are already used elsewhere in the codebase.

Output ONLY a valid JSON object mapping NEW keys to German translations. No explanations, no comments, no markdown - just raw JSON.

Format: {"key1": "German translation 1", "key2": "German translation 2"}

If no new translations, output: {}

After generating the JSON, copy it to the clipboard using `pbcopy` (macOS).
