---
order: 1
---

# Component

<EuiText>

Use tabs to organize related but unique content for a single idea or subject. Tabs show and hide content using **in-page** navigation UI.

**EuiTabs** is a wrapping component that requires **EuiTab** components as direct children. You control the displayed contents and current state through arguments on EuiTab like `@isSelected` and an `{{on "click"}}` modifier.

Use the `<:prepend>` and `<:append>` blocks of a tab to add content before and after the tab label respectively.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiIcon, EuiNotificationBadge, EuiSpacer, EuiTab, EuiTabs, EuiText } from '@ember-eui/core/components';

const contents = {
  'cobalt--id':
    'Cobalt is a chemical element with symbol Co and atomic number 27. Like nickel, cobalt is found in the Earth’s crust only in chemically combined form, save for small deposits found in alloys of natural meteoric iron. The free element, produced by reductive smelting, is a hard, lustrous, silver-gray metal.',
  'dextrose--id':
    'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.',
  'hydrogen--id':
    'Hydrogen is a chemical element with symbol H and atomic number 1. With a standard atomic weight of 1.008, hydrogen is the lightest element on the periodic table',
  'monosodium_glutamate--id':
    'Monosodium glutamate (MSG, also known as sodium glutamate) is the sodium salt of glutamic acid, one of the most abundant naturally occurring non-essential amino acids. Monosodium glutamate is found naturally in tomatoes, cheese and other foods.'
};

export default class DemoComponent extends Component {
  @tracked selectedTabId = 'cobalt--id';

  get selectedContent() {
    return contents[this.selectedTabId];
  }

  @action
  select(id, event) {
    // the last tab only shows the href, don't navigate away
    event.preventDefault();
    this.selectedTabId = id;
  }

  <template>
    <EuiTabs>
      <EuiTab
        @isSelected={{eq this.selectedTabId "cobalt--id"}}
        {{on "click" (fn this.select "cobalt--id")}}
      >
        Cobalt
      </EuiTab>
      <EuiTab
        @isSelected={{eq this.selectedTabId "dextrose--id"}}
        {{on "click" (fn this.select "dextrose--id")}}
      >
        Dextrose
      </EuiTab>
      <EuiTab
        @disabled={{true}}
        @isSelected={{eq this.selectedTabId "hydrogen--id"}}
        {{on "click" (fn this.select "hydrogen--id")}}
      >
        <:prepend><EuiIcon @type="chartHeatmap" /></:prepend>
        <:default>Hydrogen</:default>
      </EuiTab>
      <EuiTab
        @href="#/navigation/tabs#monosodium"
        @isSelected={{eq this.selectedTabId "monosodium_glutamate--id"}}
        {{on "click" (fn this.select "monosodium_glutamate--id")}}
      >
        <:default>Monosodium Glutamate</:default>
        <:append>
          <EuiNotificationBadge class="eui-alignCenter" @size="m">10</EuiNotificationBadge>
        </:append>
      </EuiTab>
    </EuiTabs>

    <EuiSpacer />
    <EuiText>
      <p>{{this.selectedContent}}</p>
    </EuiText>
  </template>
}
```
