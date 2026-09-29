---
order: 4
---

# Controlled sizes

<EuiText>

With `@size` on the panels, you keep the sizes: update them from
`@onPanelWidthChange`, e.g. to save them, or to change them from buttons.

</EuiText>

```hbs template
<EuiButton @size="s" {{on "click" this.reset}}>Reset to 50 / 50</EuiButton>
<EuiSpacer @size="s" />
<EuiResizableContainer style="height: 160px;" @onPanelWidthChange={{this.setSizes}} as |c|>
  <c.Panel @id="panel-one" @size={{this.one}} @minSize="30%">
    <EuiText @size="s"><p>{{round this.one}}%</p></EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @id="panel-two" @size={{this.two}} @minSize="30%">
    <EuiText @size="s"><p>{{round this.two}}%</p></EuiText>
  </c.Panel>
</EuiResizableContainer>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ControlledSizes extends Component {
  @tracked one = 60;
  @tracked two = 40;

  round = (value) => Math.round(value);

  @action
  setSizes(sizes) {
    this.one = sizes['panel-one'];
    this.two = sizes['panel-two'];
  }

  @action
  reset() {
    this.one = 50;
    this.two = 50;
  }
}
```
