---
order: 6
---

# Layout

<EuiText>
 <!-- You can supply a <EuiCode>layout</EuiCode> of either <EuiCode>"horizontal"</EuiCode> or <EuiCode>"vertical"</EuiCode> with the default being <EuiCode>vertical</EuiCode>. When creating empty states we want the content to be short and straight to the point. So most of the time, the <EuiCode>vertical</EuiCode> layout is enough.
  All the content will be center aligned and this type of text alignment only works with small content. When you have longer body text with multiple calls to action, you can use the <EuiCode>horizontal</EuiCode> layout. This layout works best when you can provide a larger graphic like an illustration as the <EuiCode>icon</EuiCode>. For consistency, we recommend providing the illustration using a <strong>EuiImage</strong> with <EuiCode>size="fullWidth"</EuiCode>. -->
</EuiText>

```hbs template
<EuiEmptyPrompt
  @title='Create your first visualization'
  @layout='horizontal'
  @color='plain'
  @body='There are no cases to display. Add a new case or change your filter
          settings.'
  @actions={{array (component 'eui-button-title' title='Create visualization')}}
>
  <:icon>
    <EuiImage @size='fullWidth' @src={{this.illustration}} alt='' />
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
</EuiEmptyPrompt>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoComponent extends Component {
  @tracked illustration = 'https://source.unsplash.com/64x64/?cat';
}
```
