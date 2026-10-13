---
order: 1
---

# Text

<EuiText>

Use **EuiSkeletonText** to display a placeholder for multiple lines of text.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center" @justifyContent="spaceBetween">
  <EuiSwitch
    @label="Toggle loaded state"
    @checked={{this.isLoading}}
    @onChange={{this.toggleLoading}}
  />
  <EuiButtonGroup
    @legend="Change text size"
    @idSelected={{this.size}}
    @onChange={{this.changeSize}}
    @options={{this.options}}
  />
</EuiFlexGroup>
<EuiSpacer />
<EuiSkeletonText
  @lines={{3}}
  @size={{this.size}}
  @isLoading={{this.isLoading}}
  @contentAriaLabel="Demo skeleton text"
>
  {{! Trim text to 3 lines to visually match the skeleton lines }}
  <EuiText
    @size={{this.size}}
    style="text-overflow: ellipsis; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 3; line-clamp: 3; -webkit-box-orient: vertical;"
  >
    <p>
      Far out in the uncharted backwaters of the unfashionable end of the
      western spiral arm of the Galaxy lies a small unregarded yellow sun.
      Orbiting this at a distance of roughly ninety-two million miles is an
      utterly insignificant little blue green planet whose ape-descended life
      forms are so amazingly primitive that they still think digital watches are
      a pretty neat idea.
    </p>
  </EuiText>
</EuiSkeletonText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SkeletonTextDemo extends Component {
  @tracked isLoading = true;
  @tracked size = 'm';

  options = [
    { label: 'Medium', id: 'm' },
    { label: 'Small', id: 's' },
    { label: 'Extra small', id: 'xs' },
    { label: 'Relative', id: 'relative' },
  ];

  @action
  toggleLoading() {
    this.isLoading = !this.isLoading;
  }

  @action
  changeSize(optionId) {
    this.size = optionId;
  }
}
```
