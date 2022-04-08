---
order: 1
---


<EuiText>
<p><strong>EuiTabs</strong> is a wrapping component that requires <strong>EuiTab</strong> components as direct children. You control the displayed contents and current state through props on EuiTab like <EuiCode>isSelected</EuiCode> and <EuiCode>onClick</EuiCode>.</p><p>Use the <EuiCode>prepend</EuiCode> and <EuiCode>append</EuiCode> tab props to add content before and after the tab label respectively.</p>
</EuiText>

```hbs template
<EuiTabs>
  {{#each this.tabs as |tab|}}
    <EuiTab
      @isSelected={{eq tab.id this.selectedTab.id}}
      {{on 'click' (set this 'selectedTab' tab)}}
    >
      {{tab.name}}
    </EuiTab>
  {{/each}}
</EuiTabs>
<EuiSpacer />
<EuiText>
  {{this.selectedTab.content}}
</EuiText>
```

```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked selectedTab = 0;
  @tracked tabs = [
    {
      id: 'cobalt--id',
      name: 'Cobalt',
      content:
        ' Cobalt is a chemical element with symbol Co and atomic number 27. Like nickel, cobalt is found in the Earth&rsquo;s crust only in chemically combined form, save for small deposits found in alloys of natural meteoric iron. The free element, produced by reductive smelting, is a hard, lustrous, silver-gray metal.'
    },
    {
      id: 'dextrose--id',
      name: 'Dextrose',
      content:
        'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.'
    },
    {
      id: 'hydrogen--id',
      name: 'Hydrogen',
      prepend: 'heatmap',
      disabled: true,
      content:
        'Intravenous sugar solution, also known as dextrose solution, is a mixture of dextrose (glucose) and water. It is used to treat low blood sugar or water loss without electrolyte loss.'
    },
    {
      id: 'monosodium_glutammate--id',
      name: 'Monosodium Glutamate',
      content:
        ' Monosodium glutamate (MSG, also known as sodium glutamate) is the sodium salt of glutamic acid, one of the most abundant naturally occurring non-essential amino acids. Monosodium glutamate is found naturally in tomatoes, cheese and other foods.'
    }
  ];
  constructor() {
    super(...arguments);
    this.selectedTab = this.tabs[0];
  }
}
```
