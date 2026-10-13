---
order: 8
---

# Collapsible panel options

<EuiText>
  <p>
    A <strong>Panel</strong> marked as <EuiCode>@mode=\{{array 'collapsible'}}</EuiCode> also accepts configuration options for the collapsible button by passing a second item in the array, in the form of <EuiCode>['collapsible', { position: 'top' }]</EuiCode>. That object also takes <EuiCode>className</EuiCode> and <EuiCode>data-test-subj</EuiCode> for the toggle button (upstream only passes on the test subject, although its types list the class too).
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiListGroup, EuiListGroupItem, EuiPage, EuiPanel, EuiResizableContainer, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { action } from '@ember/object';

export default class CollapsibleOptionsDemo extends Component {
  texts = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.'
  ];

  items = [
    { id: 1, label: 'First item', text: this.texts[0] },
    { id: 2, label: 'Second item', text: this.texts[1] },
    { id: 3, label: 'Third item', text: this.texts[2] },
    { id: 4, label: 'Fourth item', text: this.texts[0] }
  ];

  @tracked itemSelected = this.items[0];

  @action
  selectItem(item) {
    this.itemSelected = item;
  }

  firstMode = [
    'collapsible',
    { position: 'top', className: 'docsCollapsibleToggle', 'data-test-subj': 'docsFirstPanelToggle' },
  ];
  lastMode = ['collapsible', { position: 'bottom' }];

  <template>
    <EuiPage @paddingSize='none'>
      <EuiResizableContainer as |c|>
        <c.Panel @mode={{this.firstMode}} @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
        <c.Button @alignIndicator='start' />
        <c.Panel @mode='main' @initialSize={{60}} @minSize='20%' tabindex='0'>
          <EuiPanel @paddingSize='l' style='min-height: 100%;'>
            <EuiTitle><p>{{this.itemSelected.label}}</p></EuiTitle>
            <EuiSpacer />
            <EuiText><p>{{this.itemSelected.text}}</p></EuiText>
          </EuiPanel>
        </c.Panel>
        <c.Button @alignIndicator='end' />
        <c.Panel @mode={{this.lastMode}} @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
      </EuiResizableContainer>
    </EuiPage>
  </template>
}
```
