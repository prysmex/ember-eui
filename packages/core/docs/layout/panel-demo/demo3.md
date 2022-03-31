---
order: 3
---

# Colors and corners

<EuiText>
  <p>
Use <EuiCode>color</EuiCode> to add background shading to your panel and provide an additional helpful aesthetic to your container in context. Be mindful to use color sparingly. You can also remove the rounded corners depending on the placement of your panel with <EuiCode>borderRadius="none"</EuiCode>

Passing <EuiCode>color="transparent"</EuiCode> can give you a quick empty box simply for adding padding to all sides.

  </p>
</EuiText>

```hbs template
<EuiSpacer @size='l' />
<EuiPanel @color='subdued' @borderRadius='none' @hasShadow={{false}}>
  <p>I am a simple shaded box</p>
</EuiPanel>

<EuiSpacer />

<EuiPanel @color='transparent' @hasBorder={{false}}>
  <p>I am a transparent box simply for padding</p>
</EuiPanel>
```
