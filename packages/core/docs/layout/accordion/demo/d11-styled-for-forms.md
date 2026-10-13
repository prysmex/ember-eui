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
    The extra action only appears on hover or focus through a theme function
    passed to its <EuiCode>@css</EuiCode>.
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

// Custom trigger button CSS
const buttonCss = {
  '&:hover': { textDecoration: 'none' },
};

// Custom CSS to make the extra action only appear on hover or focus. Useful
// if there are multiple accordions in a row, to reduce visual overwhelm. A
// theme function: `@css` resolves it against the nearest theme.
const extraActionCss = ({ euiTheme }) => ({
  opacity: 0,
  '&:focus, .euiAccordion:hover &': { opacity: 1 },
  '@media (prefers-reduced-motion: no-preference)': {
    transition: `opacity ${euiTheme.animation.normal} ${euiTheme.animation.resistance}`,
  },
});

export default class AccordionFormsComponent extends Component {
  accordions = ['formAccordion-first', 'formAccordion-second'];
  buttonCss = buttonCss;
  extraActionCss = extraActionCss;

  <template>
  {{#each this.accordions as |accordion|}}
    <EuiAccordion
      @id={{accordion}}
      @element="fieldset"
      @borders="horizontal"
      @buttonProps={{hash paddingSize="m" css=this.buttonCss}}
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
            @css={{this.extraActionCss}}
            aria-label="Delete"
          />
        </EuiToolTip>
      </:extraAction>
    </EuiAccordion>
  {{/each}}
  </template>
}
```
