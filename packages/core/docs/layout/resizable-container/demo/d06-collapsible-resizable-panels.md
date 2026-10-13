---
order: 6
---

# Collapsible resizable panels

<EuiText>
  <p>
    Panels can be designated as collapsible, which allows them to hide content and automatically resize to a minimal width. The intent of collapsible panels is to enable large, layout-level content areas to cede space to a main content area. For instance, collapsing an action panel to allow more focus on the primary display panel.
  </p>
  <p>
    Use the <EuiCode>@mode</EuiCode> arg on a <strong>Panel</strong> to mark it as <EuiCode>collapsible</EuiCode> or <EuiCode>main</EuiCode>. From the provided <EuiCode>@mode</EuiCode> configuration, the <strong>EuiResizableContainer</strong> will determine placement of the toggle button and functionality of panel collapsing. To prevent empty states, not all panels can be <EuiCode>@mode="collapsible"</EuiCode> (there must be at least one <EuiCode>@mode="main"</EuiCode> panel).
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiListGroup, EuiListGroupItem, EuiPage, EuiPanel, EuiResizableContainer, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { action } from '@ember/object';

export default class CollapsibleDemo extends Component {
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

  <template>
    <EuiText>
      <h3>Simple</h3>
    </EuiText>
    <EuiSpacer />
    <EuiPage @paddingSize='none'>
      <EuiResizableContainer as |c|>
        <c.Panel @mode='collapsible' @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
        <c.Button />
        <c.Panel @mode='main' @initialSize={{80}} @minSize='50px'>
          <EuiPanel @paddingSize='l' style='min-height: 100%;'>
            <EuiTitle><p>{{this.itemSelected.label}}</p></EuiTitle>
            <EuiSpacer />
            <EuiText><p>{{this.itemSelected.text}}</p></EuiText>
          </EuiPanel>
        </c.Panel>
      </EuiResizableContainer>
    </EuiPage>

    <EuiSpacer />
    <EuiText>
      <h3>Multiple collapsible panels</h3>
    </EuiText>
    <EuiSpacer />
    <EuiPage @paddingSize='none'>
      <EuiResizableContainer as |c|>
        <c.Panel @mode='collapsible' @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
        <c.Button />
        <c.Panel @mode='main' @initialSize={{60}} @minSize='50px' tabindex='0'>
          <EuiPanel @paddingSize='l' style='min-height: 100%;'>
            <EuiTitle><p>{{this.itemSelected.label}}</p></EuiTitle>
            <EuiSpacer />
            <EuiText><p>{{this.itemSelected.text}}</p></EuiText>
          </EuiPanel>
        </c.Panel>
        <c.Button />
        <c.Panel @mode='collapsible' @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
      </EuiResizableContainer>
    </EuiPage>

    <EuiSpacer />
    <EuiText>
      <h3>Vertical collapsible panels</h3>
    </EuiText>
    <EuiSpacer />
    <EuiPage @paddingSize='none'>
      <EuiResizableContainer @direction='vertical' style='height: 400px;' as |c|>
        <c.Panel @mode='collapsible' @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
        <c.Button @accountForScrollbars='before' />
        <c.Panel @mode='main' @initialSize={{80}} @minSize='50px'>
          <EuiPanel @paddingSize='l' style='height: 100%;'>
            <EuiTitle><p>{{this.itemSelected.label}}</p></EuiTitle>
            <EuiSpacer />
            <EuiText><p>{{this.itemSelected.text}}</p></EuiText>
          </EuiPanel>
        </c.Panel>
      </EuiResizableContainer>
    </EuiPage>
  </template>
}
```
