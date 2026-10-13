---
order: 6
---

# Layout

<EuiText>

You can supply a `@layout` of either `"horizontal"` or `"vertical"` with the default being `vertical`. When creating empty states we want the content to be short and straight to the point. So most of the time, the `vertical` layout is enough. All the content will be center aligned and this type of text alignment only works with small content.

When you have longer body text with multiple calls to action, you can use the `horizontal` layout. This layout works best when you can provide a larger graphic like an illustration as the icon. For consistency, we recommend providing the illustration using an **EuiImage** with `@size="fullWidth"`. Longer markup goes in the `<:content>` block, which replaces the title, body and actions.

</EuiText>

```hbs template
<EuiEmptyPrompt @layout="horizontal" @color="plain">
  <:icon>
    <EuiImage @size="fullWidth" @src={{this.illustration}} alt="" />
  </:icon>
  <:content>
    <EuiTitle @size="m"><h2>Create your first visualization</h2></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiText @color="subdued">
      <p>
        There are no visualizations to display. This tool allows you to create
        a wide range of charts, graphs, maps, and other graphics.
      </p>
      <p>
        The visualizations you create can be easily shared with your peers.
      </p>
    </EuiText>
    <EuiSpacer @size="l" />
    <EuiButton @color="primary" @fill={{true}}>Create visualization</EuiButton>
  </:content>
  <:footer>
    <EuiTitle @size="xxs"><span>Want to learn more?</span></EuiTitle>
    <EuiLink @href="#" @target="_blank">Read the docs</EuiLink>
  </:footer>
</EuiEmptyPrompt>
```

```js component
import Component from '@glimmer/component';

const svg =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300">' +
  '<rect width="400" height="300" rx="16" fill="#E6F1FA"/>' +
  '<rect x="50" y="150" width="50" height="100" rx="4" fill="#0B64DD"/>' +
  '<rect x="125" y="100" width="50" height="150" rx="4" fill="#1750BA"/>' +
  '<rect x="200" y="60" width="50" height="190" rx="4" fill="#0B64DD"/>' +
  '<circle cx="320" cy="150" r="60" fill="#BFDBFF"/></svg>';

export default class EmptyPromptLayoutDemo extends Component {
  illustration = `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}
```
