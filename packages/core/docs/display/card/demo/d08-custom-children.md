---
order: 9
---

# Custom children

<EuiText>
<p>In the event that you need <strong>more than</strong> just paragraph text for the <EuiCode>description</EuiCode>, you can suppliment with anything you need as the <EuiCode>children</EuiCode> of the component. You can also completely replace the description with custom children, but <strong>EuiCard</strong> at least one of these.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiCard @textAlign='left' @title='Lists' @description='efefefefe'>
      <:body>
        <EuiText @size='s'>

          <ul>
            <li>Bullet 1</li>
            <li>Bullet 2</li>
            <li>Bullet 3</li>
          </ul>
        </EuiText>
      </:body>
    </EuiCard>
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard @textAlign='left' @title='Form controls'>
      <:body>
        <EuiRadioGroup
          @options={{this.radios}}
          @idSelected={{this.selectedRadioId}}
          @onChange={{set this 'selectedRadioId'}}
          @compressed={{true}}
        />
      </:body>
      <:footer>
        <EuiFlexGroup @justifyContent='flexEnd'>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @size='s' @fill={{true}}>
              Send
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:footer>

    </EuiCard>

  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @textAlign='left'
      @title='Just about anything'
      @description='Just be sure not to add any onClick handler to
              the card if the children are also interactable.'
    >
      <:body>
        <EuiCodeBlock @language='html' @paddingSize='s'>
          {'<yoda>Hello, young Skywalker</yoda>'}
        </EuiCodeBlock>
      </:body>
    </EuiCard>
  </EuiFlexItem>

</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCheckableCardomponent extends Component {
  radios = [
    {
      id: 'radio-1',
      label: 'radio 1'
    },
    {
      id: 'radio-2',
      label: 'radio 2'
    },
    {
      id: 'radio-3',
      label: 'radio 3'
    },
    {
      id: 'radio-4',
      label: 'radio 4'
    }
  ];

  @tracked selectedRadioId = null;
}
```
