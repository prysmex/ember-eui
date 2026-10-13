---
order: 6
---

# Progress for charts

<EuiText>

Determinate progress bar can be used as simple bar charts. Use them with the `@label` and `@valueText` arguments to show the data corresponding to each bar.

Setting `@valueText={{true}}` will add a % sign next to the `@value` passed. If you want to display a custom `@valueText`, you can pass a string, or use the `<:valueText>` named block for other content (as in the "Custom valueText" bar, which passes the string).

</EuiText>

```hbs template
<div style="max-width: 160px;">
  {{#each this.data as |item|}}
    <EuiProgress @label={{item.label}} @value={{item.value}} @valueText={{item.valueText}} @max={{100}} @color="success" @size="s" />
    <EuiSpacer @size="s" />
  {{/each}}
</div>
<EuiSpacer @size="m" />
<div style="max-width: 200px;">
  {{#each this.data as |item|}}
    <EuiProgress @label={{item.label}} @value={{item.value}} @valueText={{item.valueText}} @max={{100}} @color="primary" @size="m" />
    <EuiSpacer @size="s" />
  {{/each}}
</div>
```

```js component
import Component from '@glimmer/component';

export default class ProgressChartsDemo extends Component {
  data = [
    { label: 'Basic percentage', value: 80, valueText: true },
    { label: 'Long percentage', value: 60.0703850454546453168415365451354641354684531, valueText: true },
    { label: 'Another basic percent', value: 45, valueText: true },
    { label: 'Custom valueText', value: 40, valueText: '4,005,678' },
    { label: "Women's Accessories", value: 24.0256, valueText: true },
  ];
}
```
