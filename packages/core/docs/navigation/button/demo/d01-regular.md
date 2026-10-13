---
order: 1
---

# Regular

<EuiText>

Buttons enable **user actions** and are crucial for forms, modals, toolbars, and interactive pages. They offer various types, sizes, colors, and properties. The best combination depends on placement, prominence, and state. `EuiButton` is for primary and secondary actions, while `EuiButtonEmpty` is for tertiary or low-prominence actions.

Regular `EuiButton` can be used for two types of actions: primary and secondary. It has `@fill` set to `false` by default, which is typically used for **secondary actions**, striking a balance between visibility and visual noise. They are less prominent than primary actions and can be used alongside them. **Primary actions (CTAs)** should be represented by filled buttons (`@fill={{true}}`).

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
    <EuiSwitch @compressed={{true}} @label="Fill" @checked={{this.fillButton}} @onChange={{fn this.toggle "fillButton"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Full width" @checked={{this.fullButton}} @onChange={{fn this.toggle "fullButton"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Small" @checked={{this.smallButton}} @onChange={{fn this.toggle "smallButton"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="With icon" @checked={{this.withIconButton}} @onChange={{fn this.toggle "withIconButton"}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{fn this.toggle "disableButton"}} />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiButton
  @color={{this.buttonColor}}
  @isDisabled={{this.disableButton}}
  @fill={{this.fillButton}}
  @fullWidth={{this.fullButton}}
  @size={{if this.smallButton "s" "m"}}
  @iconType={{if this.withIconButton "discoverApp"}}
>
  {{if this.withIconButton "Open in Discover" "Button"}}
</EuiButton>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoComponent extends Component {
  @tracked buttonColor = 'success';
  @tracked disableButton = false;
  @tracked fillButton = false;
  @tracked fullButton = false;
  @tracked smallButton = false;
  @tracked withIconButton = false;

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
