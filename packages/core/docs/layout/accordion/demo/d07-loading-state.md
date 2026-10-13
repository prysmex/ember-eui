---
order: 7
---

# Loading state

<EuiText>
  <p>
    Use the <EuiCode>@isLoading</EuiCode> argument when not all of the
    accordion's content is ready yet. When using <EuiCode>@isLoading</EuiCode>,
    the content of the <EuiCode>&lt;:extraAction&gt;</EuiCode> block is replaced
    with a loading spinner.
  </p>
  <p>
    Manage the content of the accordion using
    <EuiCode>@isLoadingMessage</EuiCode>. By default, it is set to
    <EuiCode>false</EuiCode> and the content will remain unaltered. Set it to
    <EuiCode>true</EuiCode> to show a default loading message or pass a string
    to show a custom loading message.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAccordion, EuiButton, EuiButtonGroup, EuiFormRow, EuiPanel, EuiSpacer } from '@ember-eui/core/components';

export default class AccordionLoadingComponent extends Component {
  @tracked toggleIdSelected = 'loading--0';

  toggleButtons = [
    { id: 'loading--0', label: 'False' },
    { id: 'loading--1', label: 'True' },
    { id: 'loading--2', label: 'Custom' }
  ];

  get isLoadingMessage() {
    switch (this.toggleIdSelected) {
      case 'loading--1':
        return true;
      case 'loading--2':
        return 'This is a custom loading message';
      default:
        return false;
    }
  }

  @action
  onChange(id) {
    this.toggleIdSelected = id;
  }

  <template>
  <EuiFormRow @label="isLoadingMessage:" @display="columnCompressed">
    <EuiButtonGroup
      @buttonSize="s"
      @legend="Accordion loading message group"
      @options={{this.toggleButtons}}
      @idSelected={{this.toggleIdSelected}}
      @onChange={{this.onChange}}
    />
  </EuiFormRow>
  <EuiSpacer @size="m" />
  <EuiAccordion
    @id="isLoadingAccordion"
    @initialIsOpen={{true}}
    @paddingSize={{if this.isLoadingMessage "m" "none"}}
    @isLoading={{true}}
    @isLoadingMessage={{this.isLoadingMessage}}
    @extraAction={{true}}
  >
    <:buttonContent>
      Accordion is loading, click to toggle
    </:buttonContent>
    <:content>
      <EuiPanel @color="subdued">Opened content.</EuiPanel>
    </:content>
    <:extraAction>
      <EuiButton @size="s">Extra action!</EuiButton>
    </:extraAction>
  </EuiAccordion>
  </template>
}
```
