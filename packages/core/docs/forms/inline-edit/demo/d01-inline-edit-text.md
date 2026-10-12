---
order: 1
---

# Inline edit text

<EuiText>

`@size` sets the text size (`'xs'`, `'s'` or `'m'`); the smaller sizes also
use a compressed field and smaller buttons. `@placeholder` is shown while
there is no text.

</EuiText>

```hbs template
<EuiInlineEditText
  @inputAriaLabel="Edit text inline"
  @defaultValue="Hello World!"
/>
<EuiSpacer />
<EuiInlineEditText
  @inputAriaLabel="Edit small text inline"
  @size="s"
  @defaultValue="A smaller one"
/>
<EuiSpacer />
<EuiInlineEditText
  @inputAriaLabel="Add a description"
  @placeholder="Add a description"
/>
<EuiSpacer />
<EuiInlineEditText
  @inputAriaLabel="Read only text"
  @defaultValue="This text is read only"
  @isReadOnly={{true}}
/>
```
