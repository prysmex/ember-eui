---
order: 8
---

# Using in a page template

<EuiText>

When using an **EuiEmptyPrompt** in an **EuiPageTemplate**, we recommend using the template's `T.EmptyPrompt` part so the template can determine how to display the empty prompt based on the rest of the template configuration.

The following example shows the usage of the [`T.EmptyPrompt`](/docs/core/docs/templates/page-template#empty-pages-or-content) part (upstream's `EuiPageTemplate.EmptyPrompt`). Its default block is the prompt's body.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiButton, EuiImage, EuiLink, EuiPageTemplate, EuiTitle } from '@ember-eui/core/components';

const svg =
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300">' +
  '<rect width="400" height="300" rx="16" fill="#E6F1FA"/>' +
  '<rect x="50" y="150" width="50" height="100" rx="4" fill="#0B64DD"/>' +
  '<rect x="125" y="100" width="50" height="150" rx="4" fill="#1750BA"/>' +
  '<rect x="200" y="60" width="50" height="190" rx="4" fill="#0B64DD"/>' +
  '<circle cx="320" cy="150" r="60" fill="#BFDBFF"/></svg>';

export default class EmptyPromptTemplateDemo extends Component {
  illustration = `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;

  <template>
    <EuiPageTemplate @minHeight="0" as |T|>
      <T.EmptyPrompt @color="plain" @layout="horizontal">
        <:icon>
          <EuiImage @size="fullWidth" @src={{this.illustration}} alt="" />
        </:icon>
        <:title><h2>Create your first visualization</h2></:title>
        <:default>
          <p>
            There are no visualizations to display. This tool allows you to
            create a wide range of charts, graphs, maps, and other graphics.
          </p>
          <p>
            The visualizations you create can be easily shared with your peers.
          </p>
        </:default>
        <:actions as |Item|>
          <Item><EuiButton @color="primary" @fill={{true}}>Create visualization</EuiButton></Item>
        </:actions>
        <:footer>
          <EuiTitle @size="xxs"><span>Want to learn more?</span></EuiTitle>
          <EuiLink @href="#" @target="_blank">Read the docs</EuiLink>
        </:footer>
      </T.EmptyPrompt>
    </EuiPageTemplate>
  </template>
}
```
