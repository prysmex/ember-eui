---
order: 3
---

# Bottom border

<EuiText>
<p>The <EuiCode>bottomBorder</EuiCode> helps to separate the tab group from the content below and is on by default. However, some components like <a href="#/layout/flyout">flyouts</a> already provide borders which can act as the divider. In this case you can turn the border off with <EuiCode>bottomBorder<span class="token operator">=</span><span class="token punctuation">{</span><span class="token boolean">false</span><span class="token punctuation">}</span></EuiCode>.</p>
</EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Show tabs flyout header
</EuiButton>
{{#if this.flyoutOpen}}
  <EuiFlyout @onClose={{this.closeFlyout}}>
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Flyout header</EuiTitle>
      <EuiTabbedContent @tabs={{this.tabsItems1}} />
    </EuiFlyoutHeader>
    <EuiFlyoutBody />
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent='spaceBetween' @gutterSize='s'>
        <EuiButton {{on 'click' this.closeFlyout}}>
          Cancel
        </EuiButton>
        <EuiButton @fill={{true}} {{on 'click' this.closeFlyout}}>
          Send
        </EuiButton>
      </EuiFlexGroup>
    </EuiFlyoutFooter>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked tabsIndex2 = 0;

  @tracked flyoutOpen = false;

  @action
  openFlyout() {
    this.flyoutOpen = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyoutOpen = false;
  }

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
