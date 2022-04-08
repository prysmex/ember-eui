---
order: 2
---

# Controlled tabbed content

<EuiText>
<p>You can also use the <code class="euiCode" data-code-language="text">selectedTab</code> and <code class="euiCode" data-code-language="text">onTabClick</code> props to take complete control over tab selection. This can be useful if you want to change tabs based on user interaction with another part of the UI.</p>
</EuiText>

```hbs template
<EuiButton @color='primary' {{on 'click' this.cycleTabs}}>
  Next tab
</EuiButton>
Outer selected tab:
{{get (object-at this.tabsIndex2 this.tabsItems1) 'name'}}
<EuiTabbedContent
  @tabs={{this.tabsItems1}}
  @selectedTab={{object-at this.tabsIndex2 this.tabsItems1}}
/>

<EuiSpacer />
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

  sayMyName(tab) {
    alert(`I am ${tab.name || tab.id}`);
  }

  @action
  cycleTabs() {
    this.tabsIndex2++;

    if (this.tabsIndex2 >= this.tabsItems2.length) {
      this.tabsIndex2 = 0;
    }
  }
}
```
