---
name: docx
description: Edit or add content to an existing .docx while preserving its actual Word template — custom heading styles, tables, live TOC fields, headers/footers, fonts, theme — using only pandoc + a scripting language for raw OOXML surgery (no python-docx, no LibreOffice/soffice required). Use when asked to update a Word document (ADR, spec, report) and "keep the formatting"/"use our template", or when python-docx/LibreOffice aren't available in the environment.
---

# Editing templated .docx files with pandoc + raw OOXML surgery

Word's `.docx` is a zip of XML (OOXML). Pandoc round-trips it, but a naive
`pandoc old.docx -o new.docx` full round-trip is lossy for anything beyond
plain paragraphs/headings (live TOC fields collapse to static links, custom
paragraph styles fall back to generic Heading N, section/header/footer wiring
can shift). The reliable approach: generate **only the new content** as a
small standalone docx via pandoc, then splice its raw XML into the original
document, leaving everything else byte-for-byte untouched.

This works with just `pandoc`, `unzip`/`zip`, and `node` (or any language) —
no `python-docx`, no `soffice`/LibreOffice, no `xmllint`. Verified against
pandoc 3.7.

## 1. Inspect the source template first

```bash
mkdir unzipped && cd unzipped && unzip -o -q ../original.docx
grep -o 'w:pStyle w:val="[^"]*"' word/document.xml | sort -u   # styles actually used
```

Also convert to markdown for a readable snapshot of current structure and to
see how pandoc represents things you'll need to reproduce:

```bash
pandoc original.docx -t markdown --wrap=none -o original.md
```

Custom paragraph styles show up on headings as `# Heading {#anchor
.Style-Name-With-Spaces-As-Hyphens}` — that `.Style-Name` is the style's
**display name** (`w:name`), not its `w:styleId`. Cross-reference against
`word/styles.xml` to get the real `styleId`:

```bash
grep -B1 -A2 'w:name w:val="Semax Überschrift 1"' word/styles.xml
# -> w:customStyle="1" w:styleId="Semaxberschrift1" w:basedOn="Heading1"
```

A custom style `w:basedOn` a built-in one (e.g. `Heading1`) inherits its
outline level, so it still populates a `TOC \o "1-3"` field correctly even
though the `styleId` differs from `Heading1`.

## 2. Write the new content as plain pandoc markdown

Use plain heading levels (`#`, `##`), not a custom-style attribute on the
heading. **`# Heading {custom-style="MyStyle"}` does not work** — this is a
real limitation in pandoc's docx writer: the custom-style silently gets
applied to the *next* `Para` block instead of the heading itself (verified
reproducible, not a one-off fluke). Fix this afterward with a plain
string-replace once the fragment is generated (step 4) — safe because within
one fragment you know exactly which `Heading1`s are your intended
custom-style targets.

Inline code spans (`` `like this` ``) are fine to write normally — see the
Emphasis-style caveat in step 4.

## 3. Generate the new content as a standalone fragment

```bash
pandoc fragment.md --reference-doc=original.docx -o fragment.docx
```

`--reference-doc` matters even though you're not keeping this file directly:
it supplies fonts/theme/existing style definitions, and — critically —
pandoc computes new **numbering IDs** (`abstractNumId`/`numId` for bullet/
numbered lists) that don't collide with the reference doc's existing ones
(typically starts fresh at 1000+ for numIds, similarly offset for
abstractNumIds). This is what makes the numbering.xml merge in step 5 safe.

## 4. Extract and patch the fragment's body XML

```js
const xml = fs.readFileSync('fragment_unzip/word/document.xml', 'utf8');
const bodyStart = xml.indexOf('<w:body>') + '<w:body>'.length;
const sectIdx = xml.indexOf('<w:sectPr');
let body = xml.slice(bodyStart, sectIdx); // drop the fragment's own sectPr

// swap generic Heading1 -> the real custom chapter style, now that we have
// concrete XML and know every Heading1 here is one of our chapters
body = body.split('w:pStyle w:val="Heading1"').join('w:pStyle w:val="Semaxberschrift1"');
```

**Inline code / "Verbatim" character style gap:** pandoc's default reference
styles.xml assigns inline code an `rStyle="VerbatimChar"`, but does not
actually *define* a `<w:style w:styleId="VerbatimChar">` block anywhere —
only other styles `w:link`/`w:basedOn` reference it. This is a genuine gap in
pandoc's own generated output (confirmed: not present even in `fragment`'s
own `styles.xml`), so the target document silently falls back to plain text
for inline code with no visual distinction. Fix by rerouting to a character
style that **does** exist in the target template (e.g. the standard built-in
`Emphasis` style — check with `grep 'styleId="Emphasis"' styles.xml` first):

```js
body = body.split('w:rStyle w:val="VerbatimChar"').join('w:rStyle w:val="Emphasis"');
```

## 5. Splice into the original document.xml

Find an unambiguous anchor (a unique custom pStyle marker, a known heading
text) to determine the exact byte range being replaced, keep any trailing
boilerplate paragraphs that sit before `<w:sectPr>`, and write the result:

```js
const orig = fs.readFileSync('unzipped/word/document.xml', 'utf8');
const anchor = orig.indexOf('w:pStyle w:val="Semaxberschrift1"'); // first occurrence = insertion point
const paraStart = orig.lastIndexOf('<w:p ', anchor);
const sectStart = orig.indexOf('<w:sectPr', paraStart);
const newDoc = orig.slice(0, paraStart) + body + orig.slice(sectStart);
```

Drop any old `<w:bookmarkStart>`/`<w:bookmarkEnd>` in the replaced range —
don't try to preserve them. A live Word TOC field regenerates its own
bookmarks entirely on Update Field; stale ones are harmless dead weight, not
something the TOC depends on.

**Bookmark ID collisions:** pandoc auto-numbers `<w:bookmarkStart w:id="N">`
per heading starting near 0. Before splicing, check the target's existing
max bookmark id **across every part**, not just document.xml:

```bash
grep -oh 'w:bookmarkStart w:id="[0-9]*"' word/*.xml | sed 's/[^0-9]//g' | sort -n | tail -1
```

(headers/footers/footnotes/endnotes can hold bookmarks too). If the
fragment's range overlaps, offset all its ids up by e.g. +1000 before
splicing; if it's already clear of the max, no action needed.

## 6. Merge numbering.xml (only if the new content has lists)

`w:numbering.xml` requires all `<w:abstractNum>` elements before any
`<w:num>` elements — order matters for schema validity, so insert into
each group separately:

```js
const numIds = [...new Set([...body.matchAll(/w:numId w:val="(\d+)"/g)].map(m => m[1]))];
// fragment's numbering.xml: for each numId, find its abstractNumId + that abstractNum's full block
// insert the abstractNum block(s) right before the target's first <w:num>,
// insert the <w:num> block(s) right before the target's closing </w:numbering>
```

Multiple separate bullet lists in one fragment each get their own `numId`
even when they share one `abstractNumId` — normal, not a bug; just dedupe
the abstractNum blocks you copy over.

## 7. Rezip and validate

```bash
cd final_build && zip -q -r -X ../final.docx . && cd ..
```

Run this from *inside* the extracted tree with `.` as the target so stored
paths don't get a `./` prefix baked in.

With no `xmllint`/`python-docx`/LibreOffice available, the practical
validation is: **round-trip the final docx back through pandoc**.

```bash
pandoc final.docx -t markdown --wrap=none -o check.md
```

Pandoc's docx reader fails loudly on malformed XML or schema violations,
and a clean, structurally-correct `check.md` (right headings, right lists,
right emphasis) is strong evidence the splice is well-formed. Read it back
and manually diff against intent — don't just check the exit code.

## Things that don't need touching

- **Live TOC fields** (`TOC \o "1-3" \h \z \u`) don't need hand-editing —
  they show stale cached text until the user opens the doc in Word and hits
  Update Field (right-click → Update Field, or Ctrl+A then F9). Say this
  explicitly rather than trying to patch the field's cached text.
- Headers, footers, theme, fontTable, settings.xml — leave the whole
  directory tree as-is except the 1–2 files you're actually patching
  (`document.xml`, optionally `numbering.xml`).

## Workflow hygiene

- Never overwrite the user's actual file mid-iteration. Write output to a
  new filename, let them review, only replace the original on explicit
  confirmation.
- When the user asks for wording/content changes, **edit the markdown
  source and rerun the whole pipeline** (steps 3–7) rather than hand-patching
  the already-merged document.xml — far less error-prone, and numbering IDs
  are usually stable/reproducible across reruns when list count doesn't
  change, so the numbering-merge code rarely needs adjustment between
  iterations.
