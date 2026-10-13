---
order: 1
---

# Basic bottom bar

<EuiText>
  <p>
    <strong>EuiBottomBar</strong> is a simple wrapper component that does nothing but affix a dark bar (usually filled with buttons) to the bottom of the page. Use it when you have really long pages or complicated, multi-page forms. In the case of forms, only invoke it if a form is in a savable state.
  </p>
  <p>
    Like many of our other wrapper components, <strong>EuiBottomBar</strong> accepts a <EuiCode>@paddingSize</EuiCode> argument, which can be set to <EuiCode>s | m (default) | l | none</EuiCode>.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiBottomBar, EuiButton, EuiButtonEmpty, EuiContextMenuItem, EuiContextMenuPanel, EuiFlexGroup, EuiFlexItem, EuiPopover } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class BottomBarBasicDemo extends Component {
  @tracked showBar = false;
  @tracked showBarPopover = false;

  @action
  toggleBar() {
    this.showBar = !this.showBar;
  }

  @action
  toggleBarPopover() {
    this.showBarPopover = !this.showBarPopover;
  }

  @action
  closePopover() {
    this.showBarPopover = false;
  }

  <template>
    <EuiButton @color='primary' {{on 'click' this.toggleBar}}>
      Toggle appearance of the bottom bar
    </EuiButton>

    {{#if this.showBar}}
      <EuiBottomBar>
        <EuiFlexGroup @justifyContent='spaceBetween'>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='s'>
              <EuiFlexItem @grow={{false}}>
                <EuiPopover
                  @isOpen={{this.showBarPopover}}
                  @closePopover={{this.closePopover}}
                  @panelPaddingSize='none'
                  @repositionOnScroll={{true}}
                >
                  <:button>
                    <EuiButton
                      @color='text'
                      @size='s'
                      @iconType='help'
                      {{on 'click' this.toggleBarPopover}}
                    >
                      Help
                    </EuiButton>
                  </:button>
                  <:content>
                    <EuiContextMenuPanel>
                      <EuiContextMenuItem @icon='link' {{on 'click' this.closePopover}}>
                        Link A
                      </EuiContextMenuItem>
                      <EuiContextMenuItem @icon='link' {{on 'click' this.closePopover}}>
                        Link B
                      </EuiContextMenuItem>
                    </EuiContextMenuPanel>
                  </:content>
                </EuiPopover>
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <EuiButton @color='text' @size='s' @iconType='user'>
                  Add user
                </EuiButton>
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup @gutterSize='s'>
              <EuiFlexItem @grow={{false}}>
                <EuiButtonEmpty @color='text' @size='s' @iconType='cross'>
                  Discard
                </EuiButtonEmpty>
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <EuiButton
                  @color='primary'
                  @fill={{true}}
                  @size='s'
                  @iconType='check'
                >
                  Save
                </EuiButton>
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiBottomBar>
    {{/if}}
  </template>
}
```
