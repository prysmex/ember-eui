---
order: 2
---

# Display and edit headings and titles

<EuiText>

Use `EuiInlineEditTitle` to display and edit titles. Use the `@heading` argument to set the heading level in read mode.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonGroup, EuiSpacer, EuiInlineEditTitle } from '@ember-eui/core/components';

export default class InlineEditTitleDemo extends Component {
  titleSizeButtons = [
    { id: 'xxxs', label: '3X Small' },
    { id: 'xxs', label: '2X Small' },
    { id: 'xs', label: 'Extra small' },
    { id: 's', label: 'Small' },
    { id: 'm', label: 'Medium' },
    { id: 'l', label: 'Large' },
  ];

  @tracked size = 'm';

  @action
  setSize(id) {
    this.size = id;
  }

  <template>
    <EuiButtonGroup
      @legend="Title size"
      @options={{this.titleSizeButtons}}
      @idSelected={{this.size}}
      @onChange={{this.setSize}}
    />
    <EuiSpacer />
    <EuiInlineEditTitle
      @heading="h3"
      @size={{this.size}}
      @inputAriaLabel="Edit title inline"
      @defaultValue="Hello World (but as a title)!"
    />
  </template>
}
```
