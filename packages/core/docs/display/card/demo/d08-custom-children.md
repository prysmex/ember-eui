---
order: 8
---

# Custom children

<EuiText>

In the event that you need **more than** just paragraph text for the `@description`, you can supplement with anything you need in the `<:body>` block of the component. You can also completely replace the description with the `<:description>` block, but **EuiCard** needs at least one of these.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l">
  <EuiFlexItem>
    <EuiCard @textAlign="left" @title="Lists">
      <:description>
        <span>
          Wrap a lists with <strong>EuiText size="s"</strong> to match the
          description text.
        </span>
      </:description>
      <:body>
        <EuiText @size="s">
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
    <EuiCard @textAlign="left" @title="Form controls">
      <:body>
        <EuiRadioGroup
          @options={{this.radios}}
          @idSelected="radios0"
          @onChange={{this.noop}}
          @compressed={{true}}
        />
      </:body>
      <:footer>
        <EuiFlexGroup @justifyContent="flexEnd">
          <EuiFlexItem @grow={{false}}>
            <EuiButton @size="s" @fill={{true}}>Send</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard @textAlign="left" @title="Just about anything">
      <:description>
        <span>
          Just be sure not to add any <EuiCode>@onClick</EuiCode> handler to
          the card if the children are also interactive.
        </span>
      </:description>
      <:body>
        <EuiCodeBlock @language="html" @paddingSize="s">
          {{this.snippet}}
        </EuiCodeBlock>
      </:body>
    </EuiCard>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

export default class CardChildrenDemo extends Component {
  radios = [
    { id: 'radios0', label: 'Option one' },
    { id: 'radios1', label: 'Option two' },
    { id: 'radios2', label: 'Option three', disabled: true },
  ];

  snippet = '<yoda>Hello, young Skywalker</yoda>';
  noop = () => {};
}
```
