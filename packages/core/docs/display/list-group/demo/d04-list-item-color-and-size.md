---
order: 4
---

# List item color and size

 <EuiText>
   <p><strong>EuiListGroupItems</strong> will inherit the color from their element type whether it is a <EuiCode>button</EuiCode>, <EuiCode>anchor</EuiCode>, or <EuiCode>span</EuiCode>. You can enforce a different color of <EuiCode>primary</EuiCode>, <EuiCode>text</EuiCode>, or <EuiCode>subdued</EuiCode> with the <EuiCode>color</EuiCode> prop. Or provide the prop directly to <strong>EuiListGroup</strong>.</p><p>They also accept options for text size; <EuiCode><span class="token string">'xs'</span> <span class="token operator">|</span> <span class="token string">'s'</span> <span class="token operator">|</span> <span class="token string">'m'</span> <span class="token operator">|</span> <span class="token string">'l'</span></EuiCode>.</p>
</EuiText>

```hbs template
<EuiListGroup>
  <EuiListGroupItem @href='#' @label='Inherit by default (xs)' @size='xs' />

  <EuiListGroupItem @label='Primary (s)' @color='primary' @size='s' />

  <EuiListGroupItem @href='#' @label='Text (m)' @color='text' />

  <EuiListGroupItem @href='#' @label='Subdued (l)' @color='subdued' @size='l' />
</EuiListGroup>

<EuiSpacer @size='s' />

<EuiListGroup {{style (inline-styles background='black')}}>
  <EuiListGroupItem @href='#' @label='Ghost' @color='ghost' />
</EuiListGroup>
```
