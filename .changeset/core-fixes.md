---
"@ember-eui/core": patch
---

- EuiFormRow points its control's `aria-describedby` at the help text and
  errors, and gives help texts unique ids.
- Labelled icons (header logo, icon tip, links, notifications) are announced
  by screen readers; EuiIcon `@title` and `@aria-label` name the icon.
- EuiContextMenuItem `@layoutAlign` aligns the icon and the text.
- Export the public components missing from `@ember-eui/core/components`.
