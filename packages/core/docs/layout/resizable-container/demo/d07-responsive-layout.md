---
order: 7
---

# Responsive layout

<EuiText>
  <p>
    It is possible to dynamically change the <EuiCode>@direction</EuiCode> arg to allow for adapting layouts to screen size. Resize the window to see the panel orientation change. Upstream does this with the <EuiCode>useIsWithinBreakpoints</EuiCode> hook; here the <EuiCode>use-is-within-breakpoints</EuiCode> modifier reports whether the window is within the given breakpoints.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import useIsWithinBreakpoints from '@ember-eui/core/modifiers/use-is-within-breakpoints';
import { tracked } from '@glimmer/tracking';
import { EuiListGroup, EuiListGroupItem, EuiPage, EuiPanel, EuiResizableContainer, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';
import { array, fn } from '@ember/helper';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';

export default class ResponsiveDemo extends Component {
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

  @tracked isMobile = false;

  @action
  setIsMobile(value) {
    this.isMobile = value;
  }

  get mainPanelStyle() {
    return htmlSafe(
      this.isMobile ? 'height: 100%;' : 'min-height: 100%;'
    );
  }

  <template>
    <EuiPage @paddingSize='none'>
      <EuiResizableContainer
        @direction={{if this.isMobile 'vertical' 'horizontal'}}
        style='height: 400px;'
        {{useIsWithinBreakpoints
          sizes=(array 'xs' 's')
          setIsWithinBreakpointsValue=this.setIsMobile
        }}
        as |c|
      >
        <c.Panel @mode='collapsible' @initialSize={{20}} @minSize='10%'>
          <EuiListGroup @flush={{true}}>
            {{#each this.items as |item|}}
              <EuiListGroupItem @label={{item.label}} @size='s' @onClick={{fn this.selectItem item}} />
            {{/each}}
          </EuiListGroup>
        </c.Panel>
        <c.Button />
        <c.Panel @mode='main' @initialSize={{80}} @minSize='50px'>
          <EuiPanel @paddingSize='l' style={{this.mainPanelStyle}}>
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
