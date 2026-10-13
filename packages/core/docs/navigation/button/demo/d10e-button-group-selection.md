---
order: 10.5
---

# Button group: Selection

<EuiText>

Use `@variant="selection"` to give the buttons toggle behavior: clicks call `@onChange` with the button's `@id`, and the selected state is reflected with `aria-pressed` on each button. Every yielded button **must** have a unique `@id` so the group can track and communicate the selection.

- **Single selection** (`@type="single"`, the default): at most one button is selected at a time. Pass the selected button's id as `@idSelected`.
- **Multi selection** (`@type="multi"`): any number of buttons can be selected. Pass a map of id to boolean as `@idToSelectedMap`.

Use `@display` to alter the visual style:

- `"regular"` (default): a subdued toggle state on a light background.
- `"highlighted"`: a prominent toggle state on a light background. Use it when you have more than one segmented control and want to highlight one over the others.
- `"inverse"`: a light toggle state on a subdued background.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import {
  EuiButtonGroup,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormPrepend,
  EuiSelect,
  EuiSpacer,
  EuiToolTip
} from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked type = 'single';
  @tracked display = 'regular';
  @tracked actionsIdSelected = 'edit';
  @tracked idToSelectedMap = { edit: true };
  @tracked viewIdSelected = 'grid';

  types = [
    { value: 'single', text: 'single' },
    { value: 'multi', text: 'multi' }
  ];
  displays = [
    { value: 'regular', text: 'regular' },
    { value: 'highlighted', text: 'highlighted' },
    { value: 'inverse', text: 'inverse' }
  ];

  @action
  setType(event) {
    this.type = event.target.value;
  }

  @action
  setDisplay(event) {
    this.display = event.target.value;
  }

  @action
  onChangeSingle(id) {
    this.actionsIdSelected = id;
  }

  @action
  onChangeMulti(id) {
    this.idToSelectedMap = { ...this.idToSelectedMap, [id]: !this.idToSelectedMap[id] };
  }

  @action
  onChangeView(id) {
    this.viewIdSelected = id;
  }

  <template>
    <EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect @compressed={{true}} @options={{this.types}} @value={{this.type}} aria-label="Select type" {{on "change" this.setType}}>
          <:prepend><EuiFormPrepend @label="type" /></:prepend>
        </EuiSelect>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSelect @compressed={{true}} @options={{this.displays}} @value={{this.display}} aria-label="Select display" {{on "change" this.setDisplay}}>
          <:prepend><EuiFormPrepend @label="display" /></:prepend>
        </EuiSelect>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    {{#if (eq this.type "multi")}}
      <EuiButtonGroup
        @legend="Document actions"
        @variant="selection"
        @display={{this.display}}
        @type="multi"
        @idToSelectedMap={{this.idToSelectedMap}}
        @onChange={{this.onChangeMulti}}
        as |group|
      >
        <group.Button @id="save">Save</group.Button>
        <group.Button @id="edit">Edit</group.Button>
        <group.Button @id="delete">Delete</group.Button>
      </EuiButtonGroup>
    {{else}}
      <EuiButtonGroup
        @legend="Document actions"
        @variant="selection"
        @display={{this.display}}
        @idSelected={{this.actionsIdSelected}}
        @onChange={{this.onChangeSingle}}
        as |group|
      >
        <group.Button @id="save">Save</group.Button>
        <group.Button @id="edit">Edit</group.Button>
        <group.Button @id="delete">Delete</group.Button>
      </EuiButtonGroup>
    {{/if}}

    <EuiSpacer />

    <EuiFlexGroup @gutterSize="s">
      <EuiButtonGroup
        @legend="View mode"
        @variant="selection"
        @display={{this.display}}
        @idSelected={{this.viewIdSelected}}
        @onChange={{this.onChangeView}}
        as |group|
      >
        <EuiToolTip @content="Grid view">
          <group.ButtonIcon @id="grid" @iconType="grid" aria-label="Grid view" />
        </EuiToolTip>
        <EuiToolTip @content="List view">
          <group.ButtonIcon @id="list" @iconType="list" aria-label="List view" />
        </EuiToolTip>
        <EuiToolTip @content="Map view">
          <group.ButtonIcon @id="map" @iconType="mapMarker" aria-label="Map view" />
        </EuiToolTip>
      </EuiButtonGroup>
    </EuiFlexGroup>
  </template>
}
