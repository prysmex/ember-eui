---
order: 3
---

# Collapsible panels

<EuiText>

The side panels are `'collapsible'` around a `'main'` one: their toggle
shows when the separator next to them is focused. The buttons above
toggle them from elsewhere with the yielded `togglePanel`.

</EuiText>

```hbs template
<EuiResizableContainer style="height: 240px;" @onToggleCollapsed={{this.onToggle}} as |c|>
  <EuiFlexGroup @gutterSize="s" @responsive={{false}} style="position: absolute; top: -40px;">
    <EuiFlexItem @grow={{false}}>
      <EuiButton @size="s" {{on "click" (fn c.togglePanel "left-panel" (hash direction="left"))}}>
        Toggle left
      </EuiButton>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton @size="s" {{on "click" (fn c.togglePanel "right-panel" (hash direction="right"))}}>
        Toggle right
      </EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>
  <c.Panel @id="left-panel" @mode="collapsible" @initialSize={{20}} @minSize="10%">
    <EuiText @size="s"><p>Navigation</p></EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @mode="main" @initialSize={{60}} @minSize="50px">
    <EuiText @size="s"><p>Main content. Last toggled: {{this.last}}</p></EuiText>
  </c.Panel>
  <c.Button />
  <c.Panel @id="right-panel" @mode={{this.rightMode}} @initialSize={{20}} @minSize="10%">
    <EuiText @size="s"><p>Details</p></EuiText>
  </c.Panel>
</EuiResizableContainer>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class CollapsiblePanels extends Component {
  @tracked last = 'nothing';

  // the toggle of the right panel sits at the top of its edge
  rightMode = ['collapsible', { position: 'top' }];

  @action
  onToggle(panelId) {
    this.last = panelId;
  }
}
```
