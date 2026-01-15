# Phase 4: UX Refinement

> Polish the chosen UX approach into a production-ready specification.

---

## Purpose

Take the selected UX approach from Phase 3 and evolve it from a functional concept into a polished, coherent experience with consistent visual systems, hierarchy, and clarity.

---

## Inputs Required

- Selected approach from `ux-approaches.md`
- `prd.md` for reference
- Design system preferences (if any)

---

## Refinement Objectives

Answer these before starting:
1. What is this refinement pass meant to accomplish?
2. Which design system/framework are we following?

---

## Strategic Refinement Checklist

### A. Hierarchy and Clarity

- [ ] Establish hierarchy **without scale** — use font weight and tone, not size alone
- [ ] De-emphasize competing elements using lighter/lower-contrast treatments
- [ ] Treat labels as supporting content unless actively scanned
- [ ] Define clear action hierarchy:
  - **Primary**: Obvious, bold, highest visibility
  - **Secondary**: Visible, but less dominant
  - **Tertiary**: Subtle, often link-style
  - **Destructive**: Red/bold only at confirmation stage

### B. Spacing and Layout Consistency

- [ ] Apply a **non-linear spacing system** (values increase non-proportionally)
- [ ] More space around groups than within groups
- [ ] Limit max-widths for readability
- [ ] Keep rhythm and alignment consistent across sections

### C. Color and Visual Polish

- [ ] Begin in grayscale; color comes after hierarchy is solid
- [ ] Apply colors from a **pre-defined palette** (5-10 shades per color)
- [ ] Use shadows/tonal contrast for depth — not arbitrary decoration
- [ ] Reduce border clutter — prefer spacing or subtle shadows

---

## Component-Level Refinement

### Inputs & Forms

| Component | Refinement Actions |
|-----------|-------------------|
| **Inputs** | Soft background, inset shadow, padding scale, border-radius |
| **Labels** | Position (placeholder-overlap, small uppercase, inline) |
| **Input Groups** | Aligned attachments, consistent spacing |
| **Validation** | Inline contextual feedback, icon + tooltip for details |
| **Multi-section Forms** | Two-column, anchor links, or stepper as needed |

### Action & Status Elements

| Component | Refinement Actions |
|-----------|-------------------|
| **Buttons** | Clear hierarchy via contrast and depth |
| **Badges** | Consistent shape, paired with gradients/borders |
| **Alerts** | Accent borders, text hierarchy, controlled saturation |

### Navigation & Wayfinding

| Component | Refinement Actions |
|-----------|-------------------|
| **Horizontal Nav** | Clear active states, bottom border or raised treatment |
| **Vertical Nav** | Left-border or pill highlight, group separation |
| **Pagination** | Focus indicators, truncation, next/previous clarity |
| **Breadcrumbs** | Standardized separators and spacing |

### Content & Layout Components

| Component | Refinement Actions |
|-----------|-------------------|
| **Tables** | Zebra striping or border rhythm |
| **Cards** | Title/meta hierarchy, image positioning |
| **Modals** | Proper shim opacity, aligned buttons |
| **Empty States** | First-interaction experience, visuals + CTA |

---

## Additional Refinement Passes

### Accessibility
- [ ] Keyboard navigation works for all interactions
- [ ] Focus states are visible and consistent
- [ ] Color contrast meets WCAG AA (4.5:1 for text)
- [ ] Screen reader labels on interactive elements
- [ ] No information conveyed by color alone

### Microcopy & Tone
- [ ] Helper text guides, doesn't decorate
- [ ] CTAs are action-oriented verbs
- [ ] Error messages are human-readable
- [ ] Empty states encourage action

### Responsiveness
- [ ] Mobile breakpoint defined
- [ ] Tablet breakpoint defined
- [ ] Touch targets ≥44px on mobile
- [ ] Hierarchy maintains on all sizes

### Performance & Feedback
- [ ] Loading states defined (skeleton/spinner)
- [ ] Transitions have consistent timing
- [ ] Actions have immediate feedback
- [ ] Progress indicators for long operations

---

## Output Template

```markdown
# UX Specification - [Feature/MVP Name]

## Chosen Direction
> [Brief description of selected approach and why]

## Design System Reference
> [Tailwind / ShadCN / Custom / etc.]

---

## Visual Hierarchy

### Typography Scale
| Use | Size | Weight | Color |
|-----|------|--------|-------|
| H1 | | | |
| H2 | | | |
| Body | | | |
| Caption | | | |

### Spacing Scale
| Token | Value | Use |
|-------|-------|-----|
| xs | 4px | |
| sm | 8px | |
| md | 16px | |
| lg | 24px | |
| xl | 32px | |

### Color Palette
| Name | Value | Use |
|------|-------|-----|
| Primary | | |
| Secondary | | |
| Success | | |
| Error | | |
| Neutral-100 | | |
| Neutral-900 | | |

---

## Component Specifications

### Inputs
- Background: [color/treatment]
- Border: [style]
- Padding: [values]
- Border-radius: [value]
- Focus state: [style]
- Error state: [style]

### Buttons
| Type | Background | Text | Border |
|------|------------|------|--------|
| Primary | | | |
| Secondary | | | |
| Tertiary | | | |
| Destructive | | | |

### Cards
- Background: [color]
- Shadow: [value]
- Padding: [values]
- Border-radius: [value]

### Navigation
- Active indicator: [style]
- Hover state: [style]
- Spacing between items: [value]

---

## States

### Loading
- Skeleton: [where used]
- Spinner: [where used]
- Placeholder: [style]

### Empty
- Visual: [illustration/icon]
- Message: [copy]
- CTA: [action]

### Error
- Inline validation: [style]
- Toast/alert: [style]
- Recovery action: [approach]

---

## Responsive Behavior

### Mobile (<640px)
- [Key adjustments]

### Tablet (640-1024px)
- [Key adjustments]

### Desktop (>1024px)
- [Key adjustments]

---

## Accessibility Checklist

- [ ] All interactive elements keyboard accessible
- [ ] Focus order is logical
- [ ] Color contrast ≥4.5:1
- [ ] ARIA labels where needed
- [ ] Error messages announced to screen readers

---

## Review Summary

**Strengths**: [What's working well]

**Remaining Issues**: [What needs more work]

**Next Iteration**: [What to test or adjust]
```

---

## Output

Save to: `project-documentation/ux-spec.md`
