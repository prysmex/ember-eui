---
order: 9
---

# Styled for forms

<EuiText>
<p>
  Since accordions are unstyled by default, EUI also provides a few classes you
  can add to parts of the EuiAccordion to give it more style, like when using
  with forms.
  <ul>
    <li><EuiCode>.euiAccordionForm</EuiCode>: Applied to the
      <EuiCode>className</EuiCode>, adds top and bottom borders</li>
    <li><EuiCode>.euiAccordionForm__button</EuiCode> : Applied to the
      <EuiCode>buttonClassName</EuiCode>, adds extra padding to the button for
      better spacing</li>
    <li><EuiCode>.euiAccordionForm__extraAction</EuiCode> : Applied to the button
      passed to
      <EuiCode>extraAction</EuiCode>, will visually hide it until hover or focus</li>
  </ul>
</p>
<p>
  We also recommend creating a fieldset/legend combination for better
  accessibility and DOM structure by passing
  <EuiCode>element="fieldset"</EuiCode>. This will set the entire accordion as a
  <EuiCode>"fieldset"</EuiCode>
  and automatically change the buttonElement to a
  <EuiCode>"legend"</EuiCode>.
</p>
</EuiText>

```hbs template
<EuiAccordion
  @paddingSize='l'
  @element='fieldset'
  @className='euiAccordionForm'
  @buttonClassName='euiAccordionForm__button'
  @extraAction={{true}}
>
  <:buttonContent>
    <EuiText
      @onClick={{this.onClick}}
      @href='#/layout/accordion#interactive-content-in-the-trigger'
      @size='xs'
    >
      <div>
        <EuiFlexGroup
          @gutterSize='s'
          @alignItems='center'
          @responsive={{false}}
        >
          <EuiFlexItem @grow={{false}}>
            <EuiIcon @type='logoWebhook' @size='m' />
          </EuiFlexItem>

          <EuiFlexItem>
            <EuiTitle @size='xs'>
              <h3>Webhook</h3>
            </EuiTitle>
          </EuiFlexItem>
        </EuiFlexGroup>

        <EuiText @size='s'>
          <p>
            <EuiTextColor @color='subdued'>
              Will send a POST request to www.example.com/some/path/
            </EuiTextColor>
          </p>
        </EuiText>
      </div>
    </EuiText>
  </:buttonContent>
  <:content>
    <EuiForm @component='form'>
      <EuiFlexGroup>
        <EuiFlexItem>
          <EuiFormRow @label='Username'>
            <EuiFieldText @icon='user' @placeholder='John' />
          </EuiFormRow>
        </EuiFlexItem>

        <EuiFlexItem>
          <EuiFormRow
            @label='Password'
            @helpText='Must include one number and one symbol'
          >
            <EuiFieldPassword @icon='lock' />
          </EuiFormRow>
        </EuiFlexItem>
      </EuiFlexGroup>

      <EuiSpacer @size='m' />

      <EuiFormRow @label='Body'>
        <EuiTextArea @placeholder='I am a textarea, put some content in me!' />
      </EuiFormRow>
    </EuiForm>
  </:content>
</EuiAccordion>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class AccordionDemo8Component extends Component {
  @action
  onClick(e) {
    e.stopPropagation();
  }
}
```
