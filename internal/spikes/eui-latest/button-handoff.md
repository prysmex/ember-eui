# EuiButton migration handoff

Status: implementation complete; core `lint:types` and changed-file ESLint passed. Root agent runs integration suite and records final evidence in `components.md`.

## Files and dependencies

- `packages/core/src/components/eui-button.gts`: migrated public component, preserving existing arguments and native element/block/attribute/modifier contracts.
- `packages/core/src/components/eui-button-content.gts`: removed an obsolete Glint error suppression on spinner size after the spinner signature migration; markup otherwise unchanged.
- `packages/core/tests/integration/components/eui-button-test.gts`: six new substantial cases plus the six existing button/empty-button cases. A matrix covers 32 color/size/fill configurations.
- Uses extracted upstream `euiButtonDisplayStyles`, `euiButtonDisplayContentStyles`, `euiButtonDisplaysColors`, and `euiFocusRing`. Upstream color factory embeds `euiButtonInteractionStyles` for fill and overlay hover/active semantics.
- Depends on migrated `EuiLoadingSpinner`. `EuiIcon` remains legacy globally; button-local sizing/fill styles make its existing inline SVG render without vendor CSS. Icon inventory/design migration is deferred.

## Adapter decisions

- Latest upstream `s`/`m` heights are 32/40px; control radius is 8px, with a 16px base. Typography comes from the resolved Borealis font family and upstream size factory. No global reset or React provider is used.
- Latest-only styling: the stable root class (`euiButton`, or private `@baseClassName`) and content/text DOM selectors remain. Amsterdam color/size/fill/disabled modifier classes and doubled specificity were removed. Migrated styles are not designed to coexist with old vendor rules; the showcase isolates those rules outside its migrated content.
- Reset is scoped to the button and contains the missing React global baseline only: box sizing, border, margin, padding, typography and text decoration. Adds upstream focus ring locally because EUI React normally installs it globally. Compatibility shadow/transform/transition/opacity overrides were removed. Upstream Borealis button interactions do not animate; reduced motion therefore introduces no button transition to disable.
- Existing `ghost` remains accepted but maps to themed `text` tokens: latest upstream no longer supplies ghost. Use a dark provider around a dark surface. This intentionally replaces hard-coded white styling with context-aware contrast.
- Latest `accentSecondary` is accepted. Unsupported arbitrary color names fall back to primary styles instead of yielding a broken unstyled control.
- `@disabled` now participates in link-to-disabled-button conversion (fixes an existing mismatch with `@isDisabled`). Disabled/loading links remove href. Native button remains non-interactive; events use normal Ember modifiers.
- Defined `@isSelected=false` now emits `aria-pressed="false"` (previously only true was emitted); omitted argument still omits the attribute. Loading emits `aria-busy="true"`.
- Existing explicit `@element` remains supported, including label/file-input triggers. Unlike upstream React, an explicit custom tag is honored while disabled; native disabled semantics only exist on button tags. This is an existing Ember API behavior, not a generalized disabled-custom-element feature.
- Existing content/icon/text customization arguments and wrapper DOM are retained. Upstream content flex factory and text padding factory apply to these existing wrappers. Truncation is scoped. Icon placement respects RTL via flex direction; no manual left/right margin is used.
- This does not add upstream React-only props (e.g. `hasAriaDisabled`, `minWidth`, structured contentProps/textProps), nor alter link security API; public `...attributes` remains the native escape hatch.

## Coverage and follow-up

Rendering coverage checks native clicks/modifier persistence during element replacement, disabled/loading transitions, links/target/type/labels, fill/size/colors, full width, custom content/icon/text classes, actual SVG dimensions, focus and keyboard modifiers, nearest-provider light/dark reactivity without replacing DOM, nested token inheritance and override precedence, fixed-light child and outer sibling isolation, preferred contrast borders, disabled color/cursor/opacity, and actual RTL icon position bounds. Core harness does not load legacy CSS, so computed-style assertions exercise independent styling.

Root integration/browser checks must cover actual trusted keyboard activation, hover/active computed styles, reduced-motion emulation, latest-only style isolation, and showcase screenshots; class assertions alone are not visual parity. Extracted factory parity includes light/dark, all contrast modes, and overridden native themes (recorded by root foundation tests).

ButtonGroup delegates to the migrated EuiButton, while its group-specific wrappers/layout remain unmigrated. Audit that component separately before claiming full group parity. Custom icon components and `iconSize=original` are retained, but latest upstream icon-set parity is outside this batch. Whole-catalog accessibility, browser matrix, FastBoot, performance and visual snapshots remain release gates.

## Latest migration showcase

`/docs/eui-latest` is discoverable as **Latest EUI showcase** in the documentation sidebar and introduction. `site/app/components/eui-latest-spike.gts` renders the five migrated public components with real Borealis providers; `docs/eui-latest.md` uses `LatestEuiSpike` (the docfy import mapper interprets names beginning Eui as addon components). The original `/docs/emotion` remains separate and explicitly described as the prototype.

The page offers global mode controls (`data-latest-light`/`dark`), contrast controls (`data-contrast-standard`/`preferred`/`forced`), adjacent fixed-mode islands, native actions/loading controls, all seven latest button colors, and nested panel/control radius overrides. `data-latest-rounded` sets native `border.radius.control` and `panel` to 24px inside the preview only. Three acceptance cases in `site/tests/acceptance/eui-latest-showcase-test.ts` cover discovery, native latest styles plus fixed-mode isolation, and controls/override reactivity. Root runs suite/build/browser checks after core is built.
