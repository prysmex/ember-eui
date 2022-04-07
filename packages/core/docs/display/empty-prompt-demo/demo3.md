---
order: 3
---

# Panel options

<EuiText>
 The <strong>EuiEmptyPrompt</strong> is wrapped by <strong>EuiPanel</strong>. By default, the panel is set to <EuiCode>transparent</EuiCode> but you can customize other panel options like <EuiCode>color</EuiCode>, <EuiCode>hasBorder</EuiCode> and <EuiCode>paddingSize</EuiCode>. Changing the <EuiCode>color</EuiCode> prop will also attempt to adjust the <EuiCode>iconColor</EuiCode> and <EuiCode>footer</EuiCode> color.
</EuiText>

```hbs template
{{#let (unique-id) as |selectId|}}
  <EuiFormRow
    @id={{selectId}}
  >
    <EuiSelect
      @value={{this.panelColor}}
      @hasNoInitialSelection={{true}}
      @options={{array
        (hash value='transparent' text='transparent')
        (hash value='plain' text='plain')
        (hash value='subdued' text='subdued')
        (hash value='accent' text='accent')
        (hash value='primary' text='primary')
        (hash value='success' text='success')
        (hash value='warning' text='warning')
        (hash value='danger' text='danger')
      }}
      @id={{selectId}}
      {{on 'change' (pick 'target.value' (set this 'panelColor'))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}} for={{selectId}}>
          Color
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFormRow>
{{/let}}
<EuiSpacer @size="l" />
<EuiEmptyPrompt
  @iconType='securityAnalyticsApp'
  @color={{this.panelColor}}
  @title='Start adding cases'
  @body='There are no cases to display. Add a new case or change your filter
          settings.'
  @actions={{array (component 'eui-button-title' title='Add a case')}}
>
  <:footer>
    <EuiTitle @size='xxs'>
      <h3>Want to learn more?</h3>
    </EuiTitle>
    <EuiLink href='#' target='_blank'>
      Read documentation
    </EuiLink>
  </:footer>
</EuiEmptyPrompt>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoComponent extends Component {
  @tracked panelColor = 'accent';
}
```
