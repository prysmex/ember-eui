# EuiPanel migration handoff

Implementation: `packages/core/src/components/eui-panel.gts`. Tests: `packages/core/tests/integration/components/eui-panel-test.gts`.

## Upstream reference and deliberate API decisions

EUI 123.1.0 `es/components/panel/panel.js` and `panel.styles.js`; native Borealis 8.1.0 theme. The component composes the extracted upstream `euiPanelStyles` factory with upstream `euiBackgroundColor`, `euiPaddingSize`, and `euiBorderColor`. It adds local box-sizing/font/reset rules because the Ember application does not install React EUI's global reset. It emits ordinary Emotion classes with no specificity escalation, vendor resets, or Amsterdam compatibility shims. The root is `euiPanelBorealis`/`data-eui-panel`; color variant classes match current upstream's high-contrast transparent check. Legacy decoration/padding/radius modifier classes are removed.

Defaults now match latest EUI: **hasShadow=false, hasBorder=true** (formerly true/unspecified). Shadows require plain color, no border, and normal contrast. Border only applies to plain/transparent colors in normal contrast; native high contrast supplies semantic borders for colored panels and suppresses shadows. Normal borders intentionally use upstream's `::after` pseudo element, so inspecting only the root border width is insufficient.

Preserved Ember API: padding `none/s/m/l`, radius `none/m`, all original eight colors, grow default true, `@isClickable` opt-out, forwarded attributes/modifiers/yield. Upstream's additional severity/highlighted colors and xs/xl padding are not exposed in this batch.

Clickable panels remain a `div role=button tabindex=0`, preserving the Ember contract and allowing nested interactive content rather than introducing an invalid nested native button. Click, Enter and Space activate; unrelated keys and keys from descendants are ignored; Space prevents scrolling. `@isClickable=false` disables hover decoration without disabling activation. Local logical text alignment (`start`) preserves RTL; a local focus-visible outline compensates for the absence of React's button reset/global focus styles.

## Coverage implemented (root validates the shared suite)

- Actual computed default background, padding, panel radius, growth and pseudo border without legacy CSS.
- All eight colors in light/dark, shadow eligibility, no unwanted root border (16 cases).
- Tracked updates across all padding values, radius/growth, shadow/border/color transitions, removing stale pseudo borders.
- Forwarded custom classes, aria/data attributes and an Ember element event modifier.
- Mouse/keyboard behavior, focusability, Space scroll prevention, descendant input events, RTL alignment, isClickable opt-out.
- Nearest nested provider inheritance, mode and override updates, explicit nested light mode, sibling isolation.
- Preferred/forced contrast across plain/transparent/primary colors, semantic border colors and shadow suppression (6 cases).

Page integration: `EuiPageContent` now inherits latest Panel defaults (shadow=false, border=true). Centered content explicitly sets grow=false unless overridden to preserve layout behavior. Existing page-template assertions now check computed latest padding, growth, radius, border pseudo element and shadow rather than removed modifier classes. Page body panel presence uses `data-eui-panel`; explicit false removes the `::after` border; default no-header panels remain borderless through their explicit layout argument. No vendor stylesheet coexistence guarantee or corresponding tests remain for migrated Panel.

Validation status: implementation and coverage written; full shared type/lint/build/rendering checks are owned by the coordinating agent. Do not mark this component `Migrated` until those pass. No React rendering or pixel-perfect screenshot comparison for Panel has been claimed. Further work: additional latest upstream color API, explicit pixel/visual review of pseudo border and hover states, interactive contrast filter browser review, and downstream migration notes for changed defaults.
