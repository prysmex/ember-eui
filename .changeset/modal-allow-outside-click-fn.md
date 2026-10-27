---
'@ember-eui/core': patch
---

`EuiModal`: `@focusTrapOptions.allowOutsideClick` accepts a function, `(event: MouseEvent | TouchEvent) => boolean`, as well as a boolean, e.g. `(hash allowOutsideClick=this.allowClick)`. The options already went to focus-trap as they were, which takes either, but the type only allowed a boolean, so Glint rejected a function.
