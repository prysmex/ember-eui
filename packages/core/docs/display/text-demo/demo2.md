---
order: 2
---

# Coloring text

<EuiText>
  <p>
There are two ways to color text. Either individually by applying <strong>EuiTextColor</strong> on individual text objects, or by passing the <EuiCode>color</EuiCode> prop directly on <strong>EuiText</strong> for a blanket approach across the entirety of your text.

  </p>
</EuiText>

```hbs template
<div>
  <EuiTitle>
    <h2>
      <EuiTextColor @color='default'>You </EuiTextColor>
      <EuiTextColor @color='success'>use </EuiTextColor>
      <EuiTextColor @color='accent'>it </EuiTextColor>
      <EuiTextColor @color='warning'>on </EuiTextColor>
      <EuiTextColor @color='danger'>anything!</EuiTextColor>
    </h2>
  </EuiTitle>

  <EuiSpacer @size='l' />

  <EuiText>
    <p>
      <EuiTextColor @color='default'>Default text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='subdued'>Subdued text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='success'>Success text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='accent'>Accent text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='warning'>Warning text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='danger'>Danger text color</EuiTextColor>
    </p>
    <p>
      <EuiTextColor @color='#c561dc'>Custom text color</EuiTextColor>
    </p>
    <p>
      <span style='background-color:#222;'>
        <EuiTextColor @color='ghost'>
          Ghost text color is always white regardless of theme.
        </EuiTextColor>
      </span>
    </p>
  </EuiText>

  <EuiSpacer />

  <EuiText @color='danger'>
    <h2>Works on EuiText as well.</h2>
    <p>
      Sometimes you need to color entire blocks of text, no matter what is in
      them. You can always apply color directly (versus using the separated
      component) to make it easy. Links should still{' '}
      <a href='#'>properly color</a>.
    </p>
  </EuiText>
</div>
```
