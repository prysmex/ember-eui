---
order: 2
---

# Wrapping components

<EuiText>
  <p><strong>EuiToolTip</strong> wraps its children in a <EuiCode>&lt;span&gt;</EuiCode> element that is <<EuiCode>display: inline-block</EuiCode> If you are wrapping a block-level child (e.g. a <EuiCode>&lt;div&gt;</EuiCode>), you may need to change this by passing <EuiCode>display="block"</EuiCode> but the resulting DOM may be in violation of the HTML5 spec.</p>
  <p>It also applies <EuiCode>onFocus</EuiCode> and <EuiCode>onBlur</EuiCode> props the the cloned <EuiCode>children</EuiCode>. If you pass in a custom component, then you’ll need to make sure these props are applied to the root element rendered by your component.</p>
</EuiText>

```hbs template
<EuiToolTip
  @position='top'
  @content='Works on any kind of element &mdash; buttons, inputs, you name it!'
>
  <EuiButton>Hover me</EuiButton>
  <EuiSpacer />
</EuiToolTip>
<p>
  <EuiToolTip
    @position='top'
    @content='Here is some tooltip text'
    @display='block'
  >
    <EuiButton @fullWidth={{true}}>
      I am a block level tooltip, applied to a button with fullWidth
    </EuiButton>
  </EuiToolTip>
</p>
<EuiSpacer />
<EuiToolTip
  @position='right'
  @content='Tooltip remains visible when the child is focused'
>
  <EuiFieldText
    placeholder='Hover over me'
    aria-label='ToolTip appears on hover'
  />
</EuiToolTip>
```
