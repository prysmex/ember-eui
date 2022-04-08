---
order: 5
---

# Controlled tabbed content

<EuiText>
<p>You can also use the <code class="euiCode" data-code-language="text">selectedTab</code> and <code class="euiCode" data-code-language="text">onTabClick</code> props to take complete control over tab selection. This can be useful if you want to change tabs based on user interaction with another part of the UI.</p>
</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on 'click' this.cycleTabs}}
  @iconType='arrowRight'
  @iconSide='right'
>
  Cycle through tabs
</EuiButton>
Outer selected tab:
{{this.selectedTab.name}}
<EuiTabbedContent @tabs={{this.tabs}} @selectedTab={{this.selectedTab}}>
  <:selectedTabContent as |selected|>
    <EuiSpacer />
    <EuiText>
      {{selected.content}}
    </EuiText>
  </:selectedTabContent>
</EuiTabbedContent>

<EuiSpacer />
```

```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked selectedTab;

  constructor() {
    super(...arguments);

    this.tabs = [
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

    this.selectedTab = this.tabs[0];
  }

  @action
  cycleTabs() {
    const tabs = this.tabs;
    const selectedTabIndex = tabs.indexOf(this.selectedTab);
    const nextTabIndex =
      selectedTabIndex < tabs.length - 1 ? selectedTabIndex + 1 : 0;
    this.selectedTab = tabs[nextTabIndex];
  }
}
```
