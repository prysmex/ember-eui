---
order: 13
---

# Panel class name

<EuiText>
    Use the <EuiCode>@panelClassName</EuiCode> argument to pass a custom class to the panel containing the popover contents.
  </EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiPopover } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { set } from 'ember-set-helper';

export default class PopoverDemo1 extends Component {
  @tracked popover = false;

  <template>
    <div>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.popover}}
        @anchorPosition='downLeft'
        @panelClassName='guideDemo__textLines'
        @closePopover={{set this 'popover' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'popover' true)}}
          >
            Text scaling
          </EuiButton>
        </:button>
        <:content>
          This has a custom class that applies some grid lines.
        </:content>
      </EuiPopover>
    </div>
  </template>
}
```
