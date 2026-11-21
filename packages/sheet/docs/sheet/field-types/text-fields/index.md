---
title: Text and long text
order: 31
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: text and long text"/>
<EuiSpacer @size="l" />

<EuiText>

`text`, the default type, stores a string; `longText` a string with line
breaks, edited in a text area that grows with its lines. Both take
`maxLength`; `text` also takes a `pattern`.

- **Long text**: the lines, clamped to the row height. The editor is a
  text area that starts at the cell, at least 240 px wide, and grows with
  its lines (up to 240 px, then it scrolls). Shift+Enter or Alt+Enter adds
  a line; Enter saves and goes down.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Row height](/docs/sheet/docs/sheet/rows/row-height): more lines of long text
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
