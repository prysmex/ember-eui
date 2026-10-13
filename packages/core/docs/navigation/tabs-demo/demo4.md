---
order: 4
---

# Tabbed content

<EuiText>

**EuiTabbedContent** makes it easier to associate tabs with content based on the selected tab. Use the `@initialSelectedTab` argument to specify which tab to initially select. The selected tab's content is rendered by the `<:selectedTabContent>` block.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiIcon, EuiSpacer, EuiTabbedContent, EuiText } from '@ember-eui/core/components';

const HeatmapIcon = <template><EuiIcon @type="chartHeatmap" /></template>;

export default class DemoComponent extends Component {
  tabs = [
    {
      id: 'cobalt--id',
      name: 'Cobalt',
      content: 'Cobalt is a chemical element with symbol Co and atomic number 27. Like nickel, cobalt is found in the Earth’s crust only in chemically combined form, save for small deposits found in alloys of natural meteoric iron. The free element, produced by reductive smelting, is a hard, lustrous, silver-gray metal.'
    },
    {
      id: 'dextrose--id',
      name: 'Dextrose',
      content: 'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.'
    },
    {
      id: 'hydrogen--id',
      name: 'Hydrogen',
      prepend: HeatmapIcon,
      content: 'Hydrogen is a chemical element with symbol H and atomic number 1. With a standard atomic weight of 1.008, hydrogen is the lightest element on the periodic table'
    },
    {
      id: 'monosodium_glutamate--id',
      name: 'Monosodium Glutamate',
      content: 'Monosodium glutamate (MSG, also known as sodium glutamate) is the sodium salt of glutamic acid, one of the most abundant naturally occurring non-essential amino acids. Monosodium glutamate is found naturally in tomatoes, cheese and other foods.'
    }
  ];

  get initialTab() {
    return this.tabs[1];
  }

  @action
  onTabClick(tab) {
    console.log('clicked tab', tab);
  }

  <template>
    <EuiTabbedContent
      @tabs={{this.tabs}}
      @initialSelectedTab={{this.initialTab}}
      @autoFocus="selected"
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
