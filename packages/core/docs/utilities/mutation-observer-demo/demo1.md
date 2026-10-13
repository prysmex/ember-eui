---
order: 1
---

# Mutation observer

```hbs template
<div>
  <p>
    {{this.lastMutation}}
  </p>
  <EuiSpacer />
  <div
    {{mutation-observer
      observerOptions=(hash subtree=true attributes=true childList=true)
      onMutation=this.onMutation
    }}
  >
    <EuiButton
      @color={{this.buttonColor}}
      @fill={{true}}
      {{on 'click' this.toggleButtonColor}}
    >
      Toggle button color
    </EuiButton>
    <EuiSpacer />
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiPanel @grow={{false}}>
          <ul>
            {{#each this.items as |item|}}
              <li>
                {{item}}
              </li>
            {{/each}}
          </ul>
          <EuiSpacer @size='s' />
          <EuiButtonEmpty {{on 'click' this.addItem}}>
            add item
          </EuiButtonEmpty>
        </EuiPanel>
      </EuiFlexItem>
    </EuiFlexGroup>
  </div>
</div>
```

```javascript component
import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class MutationObserverDemo extends GlimmerComponent {
  @tracked lastMutation = 'no changes detected';
  @tracked buttonColor = 'primary';
  @tracked items = ['Item 1', 'Item 2', 'Item 3'];

  @action
  toggleButtonColor() {
    this.buttonColor = this.buttonColor === 'primary' ? 'warning' : 'primary';
  }

  @action
  addItem() {
    this.items = [...this.items, `Item ${this.items.length + 1}`];
  }

  @action
  onMutation([{ type }]) {
    this.lastMutation =
      type === 'attributes' ? 'button class name changed' : 'DOM tree changed';
  }
}
```
