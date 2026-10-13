---
order: 5
---

# List item color

<EuiText>

**EuiListGroupItems** will get by default the color `text`. You can enforce a different color of `primary`, `text`, or `subdued` with the `@color` argument. Or provide the argument directly to **EuiListGroup**.

</EuiText>

```hbs template
<EuiListGroup>
  <EuiListGroupItem @href="#" @label="Text by default" />
  <EuiListGroupItem @onClick={{this.noop}} @label="Primary" @color="primary" />
  <EuiListGroupItem @href="#" @label="Text" @color="text" />
  <EuiListGroupItem @href="#" @label="Subdued" @color="subdued" />
</EuiListGroup>

<EuiSpacer @size="s" />

<EuiEmotionProvider @colorMode="dark">
  <EuiPanel @borderRadius="none" @hasShadow={{false}} @color="subdued">
    <EuiListGroup>
      <EuiListGroupItem @href="#" @label="Ghost" />
    </EuiListGroup>
  </EuiPanel>
</EuiEmotionProvider>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class ItemColorDemo extends Component {
  @action
  noop() {}
}
```
