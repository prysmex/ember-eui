---
"@ember-eui/core": patch
---

- Keyboard drags move the item past items of any height (or width), also
  on zoomed pages.
- `settled()` waits for an opening EuiPopover to set its focus, so tests
  can assert the focus right after opening it.
