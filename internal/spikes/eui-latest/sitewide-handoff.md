# EuiSelectableTemplateSitewide gaps: handoff

Branch `eui-wave/sitewide`. Verified against EUI 123.1.0 (`selectable_template_sitewide*.tsx`).

## Closed
- `@searchProps`: the `EuiSelectable` options plus `className`, `prepend`, `append` (string = label, or a component), `onKeyUpCapture` (capture-phase keyup) and `onInput`. These were added to `EuiSelectable`/`EuiSelectableSearch` (all `EuiSelectable` users get them). The template composes `onFocus`/`onBlur`/`onKeyDown`/`onSearch` with its own handling; `@placeholder` and `@onSearch` keep working.
- `@listProps` (defaults `rowHeight 52`, `showIcons false`, "Go to" badge; the consumer's win, as upstream) plus `className`.
- `@popoverProps`: forwards the `EuiPopover` args, plus `width` and `className`; `closePopover`/`panelRef` run after the template's own. Defaults: `panelPaddingSize s`, `anchorPosition downCenter`, `ownFocus`/`display` by whether the button shows. The panel gets upstream's `textParagraph` color style.
- `@popoverButtonBreakpoints` (via `CurrentBreakPointHelper`, resize-aware).
- `@colorModes` `{ search, popover }` with `light|dark|inverse|default|global`.
- Meta: `className` and `data-test-subj` added; the `--[type]` class hook (e.g. `--PINK`) was already correct (verified: type class, base, custom, same order as upstream).
- Extras found by comparing: `icon.size`/`title`, all `avatar` args (size, imageUrl, initials, iconType...), `option.prepend`/`append` fallback when there is no icon/avatar, forwarded `EuiSelectable` args (`onActiveOptionChange`, `optionMatcher`, `height`, `errorMessage`, `allowExclusions`, `selectableScreenReaderText`, `singleSelection`), and `@loadingMessage`/`@emptyMessage`/`@noMatchesMessage`.
- Blur now tests the popover's own panel (via `panelRef`) instead of any `.euiPopover__panel` in the document; Enter in the search opens the popover (upstream).

## Ember choices
- `popoverTitle`, `popoverFooter`, `popoverButton` stay blocks (not node props). `popoverButton` still yields `toggle`.
- `popoverWidth` stays as a shortcut; `popoverProps.width` wins.
- `searchProps.className` etc. apply to the `<input>`, like upstream.
- Color modes use nested `EuiEmotionProvider`s (`@wrapper={{false}}` unless the search mode is set), rendered only when the mode differs from the one in effect. Upstream's `cloneElement` color class on the popover root is not reproduced: the popover panel already sets its own text color.
- `global` = the outermost provider's mode. Ember has no "body color"/`hasDifferentColorFromGlobalTheme`, so the template walks `EuiThemeContext`'s (private) `parent` chain (root provider = third from the end, before the system and service contexts). A public `globalColorMode` on `EuiThemeContext` would be cleaner (shared file, not touched).

## Not done
- Upstream's `...rest` spread of every `EuiSelectable` prop, and every `EuiFieldSearch` prop in `searchProps` (only those listed above are forwarded).
- `popoverProps.panelProps` is not forwarded (upstream overrides it as well).

## Tests
- 12 new integration tests (sitewide file: 15 total); no existing assertion changed.
- Full core suite: 1765/1765. `ember-tsc` and eslint clean.

## Docs
Basic setup demo mirrors upstream's (Cmd+K shortcut, `append`, `onKeyUpCapture`, `inputRef`, PINK `listProps.css`, Mobile toggle at `xs`/`s`); ColorModes demo uses `inverse`; API tables regenerated; the five rows removed from `docs-audit-gaps.md`.
