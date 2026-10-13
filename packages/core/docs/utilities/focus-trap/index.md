---
title: Focus trap
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Focus trap"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiFocusTrap** prevents keyboard-initiated focus from leaving a defined area. Temporary flows and escapes such as EuiModal and EuiFlyout are prime examples (they already trap focus; use this component for your own).

It is built on [ember-focus-trap](https://github.com/shipshapecode/ember-focus-trap) (focus-trap). Popovers, combo box lists and other portalled surfaces opened from inside the trap count as inside it, so the tab order stays what users expect.

```hbs
<EuiFocusTrap @disabled={{this.isDisabled}} @onEscapeKey={{this.close}}>
  …
</EuiFocusTrap>
```

* `@clickOutsideDisables` disables the trap on the first outside click (until `@disabled` changes).
* `@noIsolation={{false}}` hides the content outside the trap from assistive technology and disables pointer events on it.
* `@crossFrame={{true}}` keeps focus from moving into iframes outside the trap.
* `@scrollLock` locks body scrolling while the trap is active, keeping the scrollbar width (`@gapMode`).
* `@onClickOutside`, with `@closeOnMouseup` to call it on mouseup/touchend, which avoids conflicts with an outside toggle button.
* `@initialFocus` (selector, element or function), a `data-autofocus` attribute, or `@autoFocus={{false}}`.
* `@returnFocus`: `false`, `FocusOptions`, or a function receiving the element focus would return to.
* `@shards`: extra elements (or selectors, or functions returning one) that count as inside the trap.

**Differences from upstream:** the React `as`, `lockProps`, `inert`, `whiteList`, `focusLock`, `allowPinchZoom` and `preventScrollOnFocus` props of react-focus-on are not ported, nor are the `data-focus-guard` sentinels (focus-trap manages the trap edges). `@shards` take elements, selectors or functions instead of React refs. Component defaults (`EuiProvider componentDefaults`) do not exist in Ember EUI.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFocusTrap

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@disabled` | `boolean` | `false` | Turns the trap off. |
| `@returnFocus` |  | `true` | Where focus goes when the trap is deactivated: `true` returns it to the element focused before activation, `false` leaves it, `FocusOptions` return it with those options and a function receives that element and returns any of these. |
| `@initialFocus` | `EuiFocusTarget` |  | The element focused when the trap activates (selector, element or a function). Otherwise the first `[data-autofocus]` element, then the first tabbable one. |
| `@autoFocus` | `boolean` |  | Set to `false` to not move focus into the trap on activation. |
| `@onClickOutside` | `(event: MouseEvent \| TouchEvent) => void` |  | Called on a mouse or touch press outside the trap (and its shards and portalled surfaces). |
| `@closeOnMouseup` | `boolean` |  | Call `@onClickOutside` on mouseup/touchend instead of on press. |
| `@clickOutsideDisables` | `boolean` |  | The first outside click disables the trap until `@disabled` changes. |
| `@onEscapeKey` | `(event: KeyboardEvent) => void` |  | Called when Escape is pressed while focus is inside the trap. |
| `@onActivation` | `(node: HTMLElement) => void` |  | Called with the trap element after activation. |
| `@onDeactivation` | `() => void` |  | Called after deactivation. |
| `@shards` | `EuiFocusTarget[]` |  | Extra containers that count as inside the trap, as elements, selectors or functions returning an element (upstream's ref objects). |
| `@crossFrame` | `boolean` |  | Keep focus trapped inside iframes too. By default (`false`) focus may move into an iframe outside the trap. |
| `@scrollLock` | `boolean` | `false` | Locks body scrolling while the trap is active. |
| `@gapMode` | `'padding' \| 'margin'` | `'padding'` | How the scrollbar width is kept on lock. |
| `@noIsolation` | `boolean` | `true` | `false` hides the content outside the trap from assistive technology and disables pointer events on it. |
| `@css` | `EuiCss` |  | Extra styles composed into the wrapper's class. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
