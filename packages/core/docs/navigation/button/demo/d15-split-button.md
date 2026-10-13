---
order: 15
---

# Split button

<EuiText>

Split buttons combine a primary and secondary action into a visual button group. The main button performs the most common action, while the secondary button may perform an additional action or open a dropdown popover with related secondary actions. This pattern is ideal when you have one primary action that users perform frequently, along with one or several related alternatives.

`EuiSplitButton` yields two sub-components:

- `ActionPrimary`: the main action button.
- `ActionSecondary`: the secondary action button.

`ActionPrimary` is by default rendered as a standard button with text, but it can be rendered as an icon button by setting `@isIconOnly={{true}}` and passing an `@iconType`. `ActionSecondary` is always rendered as an icon button. `EuiSplitButton` only allows these two as children.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSelect
      @options={{this.colorOptions}}
      @value={{this.buttonColor}}
      @compressed={{true}}
      aria-label="Button colors"
      {{on "change" this.onChangeColor}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>Color</EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Fill" @checked={{this.isFilled}} @onChange={{fn this.toggle "isFilled"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Small" @checked={{this.isSizeSmall}} @onChange={{fn this.toggle "isSizeSmall"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.isDisabled}} @onChange={{fn this.toggle "isDisabled"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="isLoading" @checked={{this.isLoading}} @onChange={{fn this.toggle "isLoading"}} />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer @size="m" />

<EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Primary / isIconOnly" @checked={{this.isPrimaryIconOnly}} @onChange={{fn this.toggle "isPrimaryIconOnly"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Primary / isDisabled" @checked={{this.isPrimaryDisabled}} @onChange={{fn this.toggle "isPrimaryDisabled"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Primary / isLoading" @checked={{this.isPrimaryLoading}} @onChange={{fn this.toggle "isPrimaryLoading"}} />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer @size="m" />

<EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Secondary / isDisabled" @checked={{this.isSecondaryDisabled}} @onChange={{fn this.toggle "isSecondaryDisabled"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Secondary / isLoading" @checked={{this.isSecondaryLoading}} @onChange={{fn this.toggle "isSecondaryLoading"}} />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiSplitButton
  @size={{if this.isSizeSmall "s" "m"}}
  @fill={{this.isFilled}}
  @color={{this.buttonColor}}
  @isDisabled={{this.isDisabled}}
  @isLoading={{this.isLoading}}
  as |split|
>
  <split.ActionPrimary
    @isDisabled={{this.isPrimaryDisabled}}
    @isIconOnly={{this.isPrimaryIconOnly}}
    @iconType="refresh"
    @isLoading={{this.isPrimaryLoading}}
    aria-label="Refresh"
  >
    Refresh
  </split.ActionPrimary>
  <split.ActionSecondary
    @iconType="backgroundTask"
    aria-label="Send to background"
    @isDisabled={{this.isSecondaryDisabled}}
    @isLoading={{this.isSecondaryLoading}}
  />
</EuiSplitButton>

<EuiSpacer />

<EuiText>

Both sub-components accept the same arguments as `EuiButton` and `EuiButtonIcon` respectively. Some specific arguments are however controlled by the parent `EuiSplitButton` component to ensure expected visual output. These common arguments are: `@size`, `@color`, and `@fill`. Additionally, you can control `@isDisabled` and `@isLoading` states for both actions combined as well as individually. The parent argument will always override the sub-component argument when both are provided.

</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoComponent extends Component {
  @tracked buttonColor = 'success';
  @tracked isFilled = false;
  @tracked isSizeSmall = false;
  @tracked isDisabled = false;
  @tracked isPrimaryDisabled = false;
  @tracked isSecondaryDisabled = false;
  @tracked isLoading = false;
  @tracked isPrimaryLoading = false;
  @tracked isSecondaryLoading = false;
  @tracked isPrimaryIconOnly = false;

  colorOptions = ['primary', 'accent', 'success', 'warning', 'danger', 'text'].map(
    (name) => ({ value: name, text: name })
  );

  @action
  toggle(key) {
    this[key] = !this[key];
  }

  @action
  onChangeColor(e) {
    this.buttonColor = e.target.value;
  }
}
```
