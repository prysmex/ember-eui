---
order: 11
---

# Styled for forms

<EuiText>
  <p>
    Accordions are unstyled by default, but <strong>EuiAccordion</strong>
    supports several arguments around padding sizes and borders, as well as
    letting you pass in your own custom styles: <EuiCode>@paddingSize</EuiCode>
    for the content, <EuiCode>@borders="horizontal"</EuiCode> for top and bottom
    borders, and <EuiCode>@buttonProps</EuiCode> (e.g.
    <EuiCode>paddingSize</EuiCode>) for the trigger button.
  </p>
  <p>
    We also recommend creating a fieldset/legend combination for better
    accessibility and DOM structure by passing
    <EuiCode>@element="fieldset"</EuiCode>. This will set the entire accordion as
    a <EuiCode>&lt;fieldset&gt;</EuiCode> and automatically change the
    <EuiCode>@buttonElement</EuiCode> to a <EuiCode>&lt;legend&gt;</EuiCode>.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { hash } from '@ember/helper';
import { EuiAccordion, EuiButtonIcon, EuiFieldPassword, EuiFieldText, EuiFlexGroup, EuiFlexItem, EuiForm, EuiFormRow, EuiIcon, EuiSpacer, EuiText, EuiTextArea, EuiTextColor, EuiTitle, EuiToolTip } from '@ember-eui/core/components';

export default class AccordionFormsComponent extends Component {
  accordions = ['formAccordion-first', 'formAccordion-second'];

  <template>
  {{#each this.accordions as |accordion|}}
    <EuiAccordion
      @id={{accordion}}
      @element="fieldset"
      @borders="horizontal"
      @buttonProps={{hash paddingSize="m"}}
      @extraAction={{true}}
      @paddingSize="l"
    >
      <:buttonContent>
        <div>
          <EuiFlexGroup
            @gutterSize="s"
            @alignItems="center"
            @responsive={{false}}
          >
            <EuiFlexItem @grow={{false}}>
              <EuiIcon @type="logoWebhook" @size="m" />
            </EuiFlexItem>

            <EuiFlexItem>
              <EuiTitle @size="xs" @tagName="h3">Webhook</EuiTitle>
            </EuiFlexItem>
          </EuiFlexGroup>

          <EuiText @size="s">
            <p>
              <EuiTextColor @color="subdued">
                Will send a POST request to www.example.com/some/path/
              </EuiTextColor>
            </p>
          </EuiText>
        </div>
      </:buttonContent>
      <:content>
        <EuiForm @component="form">
          <EuiFlexGroup>
            <EuiFlexItem>
              <EuiFormRow @label="Username">
                <EuiFieldText @icon="user" @placeholder="John" />
              </EuiFormRow>
            </EuiFlexItem>

            <EuiFlexItem>
              <EuiFormRow
                @label="Password"
                @helpText="Must include one number and one symbol"
              >
                <EuiFieldPassword @icon="lock" />
              </EuiFormRow>
            </EuiFlexItem>
          </EuiFlexGroup>

          <EuiSpacer @size="m" />

          <EuiFormRow @label="Body">
            <EuiTextArea placeholder="I am a textarea, put some content in me!" />
          </EuiFormRow>
        </EuiForm>
      </:content>
      <:extraAction>
        <EuiToolTip @content="Delete" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon
            @iconType="cross"
            @color="danger"
            aria-label="Delete"
          />
        </EuiToolTip>
      </:extraAction>
    </EuiAccordion>
  {{/each}}
  </template>
}
```
