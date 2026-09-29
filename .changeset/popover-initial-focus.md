---
"@ember-eui/core": minor
---

EuiPopover focuses `@initialFocus` (an element, a selector or a function
returning an element) once its panel is positioned and visible, also without
`@ownFocus`, so opening a popover no longer scrolls the page to an element
that was not placed yet.

Behaviour change: a popover with `@ownFocus` and no `@initialFocus` now
focuses the first focusable element in it, as EUI does, instead of the
panel. Pass `@initialFocus` to choose another element.
