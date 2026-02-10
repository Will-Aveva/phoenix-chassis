# Specification — Chassis Adopter Theming

*The minimum viable theme contract for consuming applications. Every `--chassis-*` property listed here must be defined by the adopter for a functional layout shell.*

*This is an outward-facing spec. It governs what consuming applications must provide, not how Chassis is built. For framework internals, see `spec_framework.md`.*

---

## Derived From

| Spec Section | Constitutional Article | Vision Pillar | Originating Finding |
|---|---|---|---|
| §T1 — Required Properties | Article III (Theming Discipline) | IV (Theming Without Opinion) | Visionary review of constitution, §3.3 finding |
| §T2 — Optional Properties | Article III | IV | — |
| §T3 — Namespace | Article III (§3.2) | IV | — |
| §T4 — Integration | Article V (The Contract) | V (Frame Stays Silent) | — |

---

## Context

The Chassis constitution (Article III, §3.3) mandates: *"Chassis MUST NOT ship a default theme."* This means a consuming application that provides no `--chassis-*` values will render a layout shell using browser defaults — which may produce unusable layouts (zero-height tab bars, invisible borders, collapsed dock zones).

This spec exists so that adopters know exactly what they must provide. It converts a potential usability failure into a clear, bounded obligation.

---

## §T1 — Required Theme Properties

These properties MUST be defined by the consuming application. They are split into two tiers:
- **§T1-A (Structural)**: The layout shell is geometrically broken without these. Define these first.
- **§T1-B (Visual)**: The layout shell functions but is effectively unusable without these. Define these for a navigable shell.

> [!IMPORTANT]
> This property table is draft. The authoritative property list will be validated by the Builder during implementation. Properties may be added, renamed, or removed before the first stable release. Adopters who build themes before the Builder phase accept that risk.

### §T1-A — Structural Properties

*Without these, the layout shell is geometrically broken — elements collapse, disappear, or cannot be interacted with.*

| Property | Purpose | Consequence If Missing |
|---|---|---|
| `--chassis-tab-height` | Height of the tab bar in a stack | Tab bar collapses to zero height. Stacks become unusable. |
| `--chassis-tab-padding` | Padding inside each tab | Tab labels crowd container edges, may overlap. |
| `--chassis-divider-size` | Width/height of the divider between divisions | Divider has no grabbable area. Resizing divisions becomes impossible. |

### §T1-B — Visual Properties

*Without these, the layout shell functions geometrically but is not visually navigable — elements are invisible, indistinguishable, or lack affordances.*

| Property | Purpose | Consequence If Missing |
|---|---|---|
| `--chassis-shell-bg` | Background color of the entire shell | Shell has no ground color; content floats on browser default. |
| `--chassis-tab-bg` | Background color of the tab bar | Tabs are invisible against the shell background. |
| `--chassis-tab-active-bg` | Background of the active tab | Users cannot distinguish the selected tab. |
| `--chassis-tab-text` | Text color of tab labels | Tab labels render in browser default; may be invisible on dark backgrounds. |
| `--chassis-tab-active-text` | Text color of the active tab label | Active tab label is indistinguishable from inactive. |
| `--chassis-tab-gap` | Gap between tabs | Tabs collapse together with no visual separation. |
| `--chassis-divider-bg` | Color of the divider | Divider is invisible. Users cannot find the resize handle. |
| `--chassis-divider-hover-bg` | Divider color on hover | No affordance indicating the divider is interactive. |
| `--chassis-slot-bg` | Background color of the slot container | Slot boundaries are invisible. |
| `--chassis-slot-border` | Border of the slot container | Adjacent slots have no visual separation. |
| `--chassis-dock-highlight` | Color of the dock zone highlight during drag | Users cannot see where a dragged slot will attach. |
| `--chassis-dock-opacity` | Opacity of the dock zone highlight | Highlight may fully obscure the target area. |

---

## §T2 — Optional Theme Properties

These properties enhance the experience but are not required for a functional layout shell. If omitted, the shell still works — it just lacks polish.

### §T2.1 — Tab Typography & Close Button Properties

| Property | Purpose | Framework Fallback | Required? |
|---|---|---|---|
| `--chassis-tab-font-size` | Font size of tab labels | None | **Yes** — tabs have no text size without it |
| `--chassis-tab-close-size` | Font size of the close button icon | None | **Yes** — close icon has no size without it |
| `--chassis-tab-close-radius` | Border radius of the close button | None | **Yes** — close button has no rounding without it |
| `--chassis-tab-close-hover` | Close button hover color | No hover feedback | No |
| `--chassis-tab-close-hover-opacity` | Opacity of close button on tab hover | `0.6` | No |
| `--chassis-focus-ring` | Color of the focus indicator on the active slot | No focus indicator | No |
| `--chassis-drag-ghost-opacity` | Opacity of the dragged tab ghost | Browser default | No |

### §T2.2 — Transition Properties

| Property | Purpose | Framework Fallback | Required? |
|---|---|---|---|
| `--chassis-transition-speed` | Duration of opacity/reveal transitions | `0.15s` | No |
| `--chassis-resize-transition` | Duration of divider resize transitions | Instant | No |

### §T2.3 — Sidebar Properties

| Property | Purpose | Default If Omitted |
|---|---|---|
| `--chassis-sidebar-width` | Default sidebar width | Browser default |
| `--chassis-sidebar-bg` | Sidebar background | Inherits `--chassis-shell-bg` |
| `--chassis-sidebar-border` | Sidebar border | None |
| `--chassis-activity-bar-width` | Width of the activity bar (icon rail) | Browser default |
| `--chassis-activity-bar-bg` | Activity bar background | Inherits `--chassis-shell-bg` |

---

## §T3 — Namespace Discipline

### §T3.1 — Reserved Namespace

All CSS custom properties defined by Chassis use the `--chassis-` prefix. This namespace is reserved. Consuming applications MUST NOT define their own `--chassis-*` properties. They SET the values Chassis defines; they do not CREATE new ones.

### §T3.2 — Application Namespace

Consuming applications are free to use any other CSS custom property namespace for their own theming. Chassis will never read properties outside `--chassis-*`.

### §T3.3 — No Chassis Property Shadowing

Consuming applications MUST NOT define `--chassis-*` properties on elements inside a slot. The `--chassis-*` properties apply to the shell and its structural elements. Slot content lives in the application's visual domain — it should use the application's own custom properties.

*Rationale*: Setting `--chassis-*` inside a slot would cause that slot's structural chrome (tab bar, dividers) to differ from the rest of the shell, breaking layout coherence. If an application needs per-slot visual variation, it should use its own custom property namespace on slot content, not override Chassis's structural theming.

---

## §T4 — Integration

### §T4.1 — Theme Application Method

A consuming application provides its theme by setting `--chassis-*` properties on the root shell element or any ancestor. The standard method:

```css
:root {
  --chassis-shell-bg: #1e1e2e;
  --chassis-tab-height: 2.25rem;
  --chassis-tab-bg: #181825;
  --chassis-tab-active-bg: #313244;
  --chassis-tab-text: #a6adc8;
  --chassis-tab-active-text: #cdd6f4;
  --chassis-tab-padding: 0 0.75rem;
  --chassis-tab-gap: 0;
  --chassis-divider-size: 4px;
  --chassis-divider-bg: #181825;
  --chassis-divider-hover-bg: #89b4fa;
  --chassis-slot-bg: #1e1e2e;
  --chassis-slot-border: 1px solid #313244;
  --chassis-dock-highlight: rgba(137, 180, 250, 0.3);
  --chassis-dock-opacity: 0.8;
}
```

### §T4.2 — Multiple Themes

An application MAY define multiple themes by scoping `--chassis-*` properties under different selectors (e.g., `[data-theme="dark"]`, `[data-theme="light"]`). Chassis does not participate in theme switching — it reads whatever values are currently in scope.

### §T4.3 — Theme Completeness Validation

A consuming application SHOULD validate that all required `--chassis-*` properties from §T1 are defined. The validation method is application-specific. Chassis does not enforce theme completeness — it renders with whatever values are available, per §3.3 of the constitution.

---

## Test Criteria

| ID | Test | Method |
|---|---|---|
| T-T1 | Required properties are documented | All §T1 properties are listed in Chassis documentation |
| T-T2 | Each required property is referenced in `chassis.css` | Static analysis: every §T1 property appears as `var(--chassis-*)` in the stylesheet |
| T-T3 | No aesthetic fallback values | Aesthetic fallbacks (e.g., `var(--chassis-tab-bg, #1e1e2e)`) are prohibited — Chassis must not encode color, font, or decorative defaults. Structural fallbacks (e.g., `var(--chassis-tab-height, 2rem)`) are permitted but discouraged — the adopter spec exists to make them unnecessary. |
| T-T4 | Optional properties have graceful degradation | Without §T2 properties, the layout shell remains functional (test with empty theme) |
| T-T5 | Namespace is clean | No CSS property outside `--chassis-*` is defined by Chassis |
| T-T6 | Example theme integrates successfully | The §T4.1 example produces a functional, styled layout when applied |

---

## Boundary

This spec governs the **adopter's theming obligation** — what consuming applications must provide to Chassis. It does NOT govern:
- How Chassis implements its CSS (see Framework Spec §F6)
- What the consuming application renders inside slots
- Application-level theming beyond `--chassis-*` properties
- Which specific colors, fonts, or visual choices an application makes

The adopter owns all aesthetic decisions. This spec only tells them which knobs exist and which ones they must turn.
