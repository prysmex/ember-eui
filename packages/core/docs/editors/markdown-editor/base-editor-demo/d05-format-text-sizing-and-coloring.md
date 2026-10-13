---
order: 5
---

# Format: text sizing and coloring

<EuiText>

<strong>EuiMarkdownFormat</strong> uses <strong>EuiText</strong> as a wrapper to handle all the CSS styling when rendering the HTML. It also gives the ability to control the text size and color with the <EuiCode>@textSize</EuiCode> and <EuiCode>@color</EuiCode> arguments, respectively.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { EuiMarkdownFormat } from '@ember-eui/core/components';

export default class FormatSizing extends Component {
  markdownContent = `This text has the \`textSize\` argument set to \`"s"\`.

The color argument is set to \`"danger"\` and that's why all the text is red! :smile:

| Emoji | Color |
| ------ | ----------- |
| :rose:   | Red |
| :apple: | Red |
| :green_heart:    | Green |
`;

  <template>
    <EuiMarkdownFormat @color='danger' @textSize='s' @value={{this.markdownContent}} />
  </template>
}
```

