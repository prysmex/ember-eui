---
'@ember-eui/sheet': minor
---

Accessibility and fixes after the first release:

- **Screen readers:** read-only cells are marked read-only, a checked row's number says so, checkbox cells read "Checked" / "Not checked", the row-number header is named, the row menu and the field editor have menu and dialog roles and names, and the expanded record's boxes are named by their label and value.
- **Announcements:** a polite live region announces pastes ("12 cells pasted"), undo and redo, rejections, and an edit that leaves its cell invalid. Its texts are messages (`@messages`, `eui-i18n`).
- **Keyboard:** Space or Enter on the row-number header checks every record (or none); PageUp and PageDown on a row number of an ungrouped sheet move a page instead of losing focus.
- **Contrast:** empty rating stars (a new `--euiSheet-starOff` variable), the dark range tint and hovered rows meet WCAG AA in light, dark and high contrast.
- **Row numbers:** the row-number column fits its numbers beside the checkbox and expand icon, on phones and with large record counts (no more "1..").
