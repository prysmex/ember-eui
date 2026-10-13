---
order: 4
---

# Relative positioning

<EuiText>
  <p>
    When <EuiCode>@affordForDisplacement</EuiCode> is enabled and the bottom bar is positioned as <EuiCode>fixed</EuiCode>, <strong>EuiBottomBar</strong> automatically sets a global CSS variable that you can use to position other fixed elements in your application relative to the bottom bar's height:
  </p>
  <ul>
    <li><EuiCode>--euiBottomBarOffset</EuiCode> (Set when <EuiCode>@affordForDisplacement=&#123;&#123;true&#125;&#125;</EuiCode> and <EuiCode>@position="fixed"</EuiCode>)</li>
  </ul>
  <p>
    This variable is automatically updated when the bottom bar resizes and is removed when the bottom bar is closed. Use it in your own CSS, for example <EuiCode>padding-bottom: var(--euiBottomBarOffset, 0);</EuiCode> on a fixed footer. In the example below, the custom fixed footer (bottom right of the window) moves up while the bottom bar is shown.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiBottomBar, EuiButton, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class BottomBarOffsetDemo extends Component {
  @tracked showBar = false;

  @action
  toggleBar() {
    this.showBar = !this.showBar;
  }

  <template>
    <EuiButton @color='primary' {{on 'click' this.toggleBar}}>
      Toggle appearance of the bottom bar
    </EuiButton>

    <div style='position: fixed; right: 0; bottom: 0; z-index: 1; padding-bottom: var(--euiBottomBarOffset, 0);'>
      <EuiPanel @paddingSize='s' @hasShadow={{true}}>
        <EuiText @size='s'>
          <p>Custom fixed footer</p>
        </EuiText>
      </EuiPanel>
    </div>

    {{#if this.showBar}}
      <EuiBottomBar>
        <EuiFlexGroup @justifyContent='flexEnd'>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @color='text' @size='s' @iconType='cross' {{on 'click' this.toggleBar}}>
              close
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiBottomBar>
    {{/if}}
  </template>
}
```
