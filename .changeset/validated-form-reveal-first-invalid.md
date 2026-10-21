---
'@ember-eui/validated-form': minor
---

Submitting a form with errors now takes the user to the first invalid field on the first submit, not the second. After `@onInvalid` runs and the errors render, the form scrolls the first invalid field's row into view and focuses its control. A custom field that reports its validity through a hidden input gets its row scrolled to and its first visible control focused, so the browser doesn't warn "An invalid form control is not focusable". Pass `@revealFirstInvalid={{false}}` to turn this off.
