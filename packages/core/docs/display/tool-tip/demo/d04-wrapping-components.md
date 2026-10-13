---
order: 4
---

# Wrapping components

<EuiText>

`EuiToolTip` wraps its content in a `<span>` element that is `display: inline-block`. If you are wrapping a block-level child (e.g. a `<div>`), you may need to change this by passing `@display="block"` but the resulting DOM may be in violation of the HTML5 spec.

It also links the tooltip to the anchor's focusable element and shows it on focus and blur. If you pass in a custom component, then you'll need to make sure it forwards `...attributes` to its root element.

</EuiText>

```hbs template
<EuiToolTip
  @position='top'
  @content='Works on any kind of element — buttons, inputs, you name it!'
>
  <EuiButton>Hover me</EuiButton>
</EuiToolTip>

<EuiSpacer />

<EuiToolTip
  @position='top'
  @content='Here is some tooltip text.'
  @display='block'
>
  <EuiButton @fullWidth={{true}}>
    I am a block level tooltip, applied to a button with fullWidth
  </EuiButton>
</EuiToolTip>

<EuiSpacer />

<EuiToolTip
  @position='right'
  @content='Tooltip remains visible while the child is focused.'
>
  <EuiFieldText
    placeholder='Focus me'
    aria-label='Example of input wrapped with tooltip'
  />
</EuiToolTip>
```
