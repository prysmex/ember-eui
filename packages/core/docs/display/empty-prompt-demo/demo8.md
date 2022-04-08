---
order: 8
---

# Using in a page template

<EuiText>
 When using a <strong>EuiEmptyPrompt</strong> in a <strong>EuiPageTemplate</strong>, pay attention to the template you’re passing. The template will determine which <EuiCode>color</EuiCode> and <EuiCode>hasBorder</EuiCode> prop you should use to ensure consistency across our Elastic products.

 <!-- The following example shows the usage of a <strong>EuiEmptyPrompt</strong> in a page template where the template is set to "empty". -->
</EuiText>

```hbs template
<EuiPageTemplate
  @template='empty'
  @pageContentProps={{hash paddingSize='none'}}
>
  <EuiEmptyPrompt
    @title='Create your first visualization'
    @color='plain'
    @layout='horizontal'
    @actions={{array
      (component 'eui-button-title' title='Create visualization')
    }}
  >
    <:icon>
      <EuiImage @size="fullWidth" @src={{this.illustration}} alt="" />
    </:icon>
    <:body>
      <p>
        There are no visualizations to display. This tool allows you to create a
        wide range of charts, graphs, maps, and other graphics.
      </p>
      <p>
        The visualizations you create can be easily shared with your peers.
      </p>
    </:body>
    <:footer>
      <EuiTitle @size='xxs'>
        <span>Want to learn more?</span>
      </EuiTitle>
      <EuiLink href='#' target='_blank'>
        Read documentation
      </EuiLink>
    </:footer>
  </EuiEmptyPrompt>
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoComponent extends Component {
  @tracked illustration = 'https://source.unsplash.com/64x64/?cat';
}
```
