---
order: 3
---

# Icon

<EuiText>

`EuiButtonIcon` is an **icon-only button**. Use `@display` and `@size` to match standard buttons. The default appearance is `xs`, `empty`. Use it only for common, intuitive actions with **immediately understood icons** (e.g., trash can for delete). `aria-label` is required for accessibility. The icon color is inherited from the button's `@color`, so it does not need to be set separately.

Because the button has no visible text, **wrap every `EuiButtonIcon` in an `EuiToolTip`** so sighted users who don't rely on a screen reader can understand its purpose. Don't use the native `title` attribute for this: browser-native tooltips are unstyled, have no delay control and are not consistently announced across screen readers and browsers.

When the tooltip `@content` duplicates the button's accessible label (e.g. it's the same as the `aria-label`), set `@disableScreenReaderOutput` on the `EuiToolTip` to avoid screen readers announcing the label twice (e.g. "Delete. Delete").

```hbs
{{! Bad: no tooltip for sighted users }}
<EuiButtonIcon aria-label="Delete" @iconType="trash" @color="danger" />

{{! Bad: browser-native tooltip }}
<EuiButtonIcon title="Delete" aria-label="Delete" @iconType="trash" @color="danger" />

{{! Good }}
<EuiToolTip @content="Delete" @disableScreenReaderOutput={{true}}>
  <EuiButtonIcon aria-label="Delete" @iconType="trash" @color="danger" />
</EuiToolTip>
```

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { EuiButtonIcon, EuiFlexGroup, EuiFlexItem, EuiFormLabel, EuiSelect, EuiSpacer, EuiSwitch, EuiText, EuiToolTip } from '@ember-eui/core/components';

const options = (names) => names.map((name) => ({ value: name, text: name }));

export default class DemoComponent extends Component {
  @tracked buttonColor = 'success';
  @tracked displayType = 'empty';
  @tracked displaySize = 'xs';
  @tracked iconSize = 'm';
  @tracked disableButton = false;

  colorOptions = options(['primary', 'accent', 'success', 'warning', 'danger', 'text']);
  displayTypeOptions = options(['empty', 'base', 'fill']);
  displaySizeOptions = options(['xs', 's', 'm']);
  iconSizeOptions = options(['s', 'm', 'l', 'xl', 'xxl', 'original']);

  @action
  onChange(key, e) {
    this[key] = e.target.value;
  }

  @action
  toggleDisabled() {
    this.disableButton = !this.disableButton;
  }

  <template>
    <EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @options={{this.colorOptions}}
          @value={{this.buttonColor}}
          @compressed={{true}}
          aria-label="Button colors"
          {{on "change" (fn this.onChange "buttonColor")}}
        >
          <:prepend as |classes|>
            <EuiFormLabel class={{classes}}>Color</EuiFormLabel>
          </:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @options={{this.displayTypeOptions}}
          @value={{this.displayType}}
          @compressed={{true}}
          aria-label="Button display styles"
          {{on "change" (fn this.onChange "displayType")}}
        >
          <:prepend as |classes|>
            <EuiFormLabel class={{classes}}>Display</EuiFormLabel>
          </:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @options={{this.displaySizeOptions}}
          @value={{this.displaySize}}
          @compressed={{true}}
          aria-label="Button sizes"
          {{on "change" (fn this.onChange "displaySize")}}
        >
          <:prepend as |classes|>
            <EuiFormLabel class={{classes}}>Size</EuiFormLabel>
          </:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect
          @options={{this.iconSizeOptions}}
          @value={{this.iconSize}}
          @compressed={{true}}
          aria-label="Icon in button sizes"
          {{on "change" (fn this.onChange "iconSize")}}
        >
          <:prepend as |classes|>
            <EuiFormLabel class={{classes}}>Icon size</EuiFormLabel>
          </:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @compressed={{true}} @label="Disabled" @checked={{this.disableButton}} @onChange={{this.toggleDisabled}} />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="xl" />
    <EuiToolTip @content="Open documentation" @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon
        @color={{this.buttonColor}}
        @display={{this.displayType}}
        @size={{this.displaySize}}
        @iconSize={{this.iconSize}}
        @isDisabled={{this.disableButton}}
        @iconType="documentation"
        aria-label="Open documentation"
      />
    </EuiToolTip>

    <EuiSpacer @size="xl" />

    <EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="flexStart">
      <EuiFlexItem @grow={{false}}>
        <EuiToolTip @content="Lens" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon @display="base" @iconType="lensApp" @size="m" aria-label="Lens" />
        </EuiToolTip>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiToolTip @content="Warning" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon @display="base" @iconType="warning" @size="s" @color="warning" aria-label="Warning" />
        </EuiToolTip>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiToolTip @content="Dashboard" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon @iconType="dashboardApp" aria-label="Dashboard" @color="text" />
        </EuiToolTip>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiToolTip @content="Delete" @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon @iconType="trash" aria-label="Delete" @color="danger" />
        </EuiToolTip>
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer />

    <EuiText>

    `EuiButtonIcon` requires an `aria-label` to express the meaning to screen readers.

    </EuiText>
  </template>
}
```
