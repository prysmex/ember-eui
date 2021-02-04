# Indefinite Progress

Indefinite progress bar is displayed whenever the component DOES NOT have the `@max` prop. When in indefinite mode, the component will ignore the `@value`, `@valueText`, and `@label` props

> you can still define `@size` and `@color` props.<br>

```hbs template
<EuiProgress @color="accent" @size="s" />
<EuiSpacer @size="m" />
```
