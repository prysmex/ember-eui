---
order: 1
---

# Notification event

```gjs component
import { htmlSafe } from '@ember/template';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonEmpty, EuiNotificationEvent, EuiPanel, EuiRange, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { concat } from '@ember/helper';
import { pick, slice } from '@nullvoxpopuli/ember-composable-helpers';
import { set } from 'ember-set-helper';

const sub = (a, b) => a - b;

export default class NotificationEvent1Component extends Component {
  @tracked messagesCount;
  @tracked showPrimaryAction;

  messages = ['This is a message', "Wait, there's more", 'hmmm...'];

  constructor() {
    super(...arguments);
    this.messagesCount = 1;
    this.showPrimaryAction = false;
  }

  @action
  setMessagesCount(e) {
    this.messagesCount = e.target.value;
  }

  get primaryActionStyle() {
    return htmlSafe(this.showPrimaryAction ? 'display: revert;' : 'display: none;');
  }

  <template>
    {{#let (slice 0 this.messagesCount this.messages) as |msgs|}}
      <EuiPanel @paddingSize='xs'>
        <EuiNotificationEvent
          @type='Hey!'
          @badgeColor='primary'
          @time='1 min'
          @title='Some nice title'
          @messages={{msgs}}
          @iconType='email'
          @accordionButtonText={{concat '+ ' (sub msgs.length 1) ' more'}}
          @accordionHideText='hide'
        >

          <:primaryAction>
            <EuiButtonEmpty
              style={{this.primaryActionStyle}}
              @flush='left'
              @size='s'
            >
              Do something!
            </EuiButtonEmpty>
          </:primaryAction>

        </EuiNotificationEvent>
      </EuiPanel>
    {{/let}}

    <EuiSpacer />

    Messages count:
    <EuiRange
      @min={{1}}
      @max={{3}}
      @step={{1}}
      @value={{this.messagesCount}}
      @onChange={{this.setMessagesCount}}
      @showLabels={{true}}
    />

    <EuiSwitch
      @label='Show primary action'
      @checked={{this.showPrimaryAction}}
      @onChange={{pick 'target.checked' (set this 'showPrimaryAction')}}
    />
  </template>
}
```

