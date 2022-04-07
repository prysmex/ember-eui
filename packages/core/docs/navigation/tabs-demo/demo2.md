---
order: 1
---

# Tabbed Content

<EuiText>
<p><strong>EuiTabbedContent</strong> makes it easier to associate tabs with content based on the selected tab. Use the <EuiCode>initialSelectedTab</EuiCode> prop to specify which tab to initially select.</p>
</EuiText>

```hbs template
<EuiTabbedContent @tabs={{this.tabsItems1}} />
```

```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked tabsIndex2 = 0;

  constructor() {
    super(...arguments);

    this.tabsItems1 = [
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
  }
}
```
