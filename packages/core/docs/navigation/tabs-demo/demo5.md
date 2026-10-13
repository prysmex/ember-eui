---
order: 5
---

# Controlled tabbed content

<EuiText>

You can also use the `@selectedTab` and `@onTabClick` arguments to take complete control over tab selection. This can be useful if you want to change tabs based on user interaction with another part of the UI.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiButton, EuiSpacer, EuiTabbedContent, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  tabs = [
    {
      id: 'cobalt',
      name: 'Cobalt',
      content: 'Cobalt is a chemical element with symbol Co and atomic number 27. Like nickel, cobalt is found in the Earth’s crust only in chemically combined form, save for small deposits found in alloys of natural meteoric iron. The free element, produced by reductive smelting, is a hard, lustrous, silver-gray metal.'
    },
    {
      id: 'dextrose',
      name: 'Dextrose',
      content: 'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.'
    },
    {
      id: 'hydrogen',
      name: 'Hydrogen',
      content: 'Hydrogen is a chemical element with symbol H and atomic number 1. With a standard atomic weight of 1.008, hydrogen is the lightest element on the periodic table'
    },
    {
      id: 'monosodium_glutamate',
      name: 'Monosodium Glutamate',
      content: 'Monosodium glutamate (MSG, also known as sodium glutamate) is the sodium salt of glutamic acid, one of the most abundant naturally occurring non-essential amino acids. Monosodium glutamate is found naturally in tomatoes, cheese and other foods.'
    }
  ];

  @tracked selectedTab = this.tabs[1];

  @action
  onTabClick(selectedTab) {
    this.selectedTab = selectedTab;
  }

  @action
  cycleTab() {
    const selectedTabIndex = this.tabs.indexOf(this.selectedTab);
    const nextTabIndex =
      selectedTabIndex < this.tabs.length - 1 ? selectedTabIndex + 1 : 0;
    this.selectedTab = this.tabs[nextTabIndex];
  }

  <template>
    <EuiButton @iconType="chevronSingleRight" @iconSide="right" {{on "click" this.cycleTab}}>
      Cycle through the tabs
    </EuiButton>

    <EuiSpacer @size="m" />

    <EuiTabbedContent
      @tabs={{this.tabs}}
      @selectedTab={{this.selectedTab}}
      @onTabClick={{this.onTabClick}}
    >
      <:selectedTabContent as |selected|>
        <EuiSpacer />
        <EuiText>
          <p>{{selected.content}}</p>
        </EuiText>
      </:selectedTabContent>
    </EuiTabbedContent>
  </template>
}
```
