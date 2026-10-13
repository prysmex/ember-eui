---
order: 3
---

# Panel options

<EuiText>

The **EuiEmptyPrompt** is wrapped by **EuiPanel**. By default, the panel is set to `transparent` but you can customize other panel options like `@color`, `@hasBorder` and `@paddingSize`. Changing the `@color` argument will also attempt to adjust the `@iconColor` and footer color.

Read the usage guidelines below to better understand when to use certain panel arguments.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiEmptyPrompt, EuiFormLabel, EuiLink, EuiSelect, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';

const ActionButton1 = <template><EuiButton @color="primary">Add a case</EuiButton></template>;

export default class EmptyPromptPanelDemo extends Component {
  @tracked panelColor = 'transparent';

  colors = [
    'transparent',
    'plain',
    'subdued',
    'accent',
    'primary',
    'success',
    'warning',
    'danger',
  ].map((value) => ({ value, text: value }));

  @action setColor(event) {
    this.panelColor = event.target.value;
  }

  <template>
    <EuiSelect
      @value={{this.panelColor}}
      @options={{this.colors}}
      aria-label="Panel color"
      {{on "change" this.setColor}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>Color</EuiFormLabel>
      </:prepend>
    </EuiSelect>
    <EuiSpacer @size="l" />
    <EuiEmptyPrompt
      @iconType="securityAnalyticsApp"
      @title="Start adding cases"
      @color={{this.panelColor}}
      @body="Add a new case or change your filter settings."
      @actions={{array ActionButton1}}
    >
      <:footer>
        <EuiTitle @size="xxs"><h3>Want to learn more?</h3></EuiTitle>
        <EuiLink @href="#" @target="_blank">Read the docs</EuiLink>
      </:footer>
    </EuiEmptyPrompt>
  </template>
}
```

