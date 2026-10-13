---
order: 2
---

# Read state

<EuiText>

With `@isRead` and `@onRead`, a button toggles the read state; read
events are shown dimmed.

</EuiText>

```gjs component
import { htmlSafe } from '@ember/template';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButtonEmpty, EuiContextMenuItem, EuiNotificationEvent, EuiPanel, EuiRange, EuiSpacer, EuiSwitch, EuiTab, EuiTabs } from '@ember-eui/core/components';
import { concat, fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { pick, slice } from '@nullvoxpopuli/ember-composable-helpers';
import { set } from 'ember-set-helper';
import { eq } from 'ember-truth-helpers';

const sub = (a, b) => a - b;

export default class NotificationEvent2Component extends Component {
  @tracked selectedTab;
  @tracked isRead;
  @tracked messagesCount;
  @tracked showPrimaryAction;
  
  messages = [
    'This is a message',
    "Wait, there's more",
    'hmmm...'
  ]

  tabs = [
    {
      id: 'icon',
      name: 'Icon',
      isRead: false
    },
    {
      id: 'button',
      name: 'Button',
      isRead: false,
      onRead: this.onRead
    }
  ];

  constructor() {
    super(...arguments);
    this.messagesCount = 1;
    this.selectedTab = this.tabs[0];
    this.isRead = this.selectedTab.isRead;
    this.showPrimaryAction = false;
  }

  @action
  onRead() {
    this.isRead = !this.isRead
  }

  @action
  onTabSelection(obj) {
    this.isRead = obj.isRead;
    this.selectedTab = obj
  }

  @action
  setMessagesCount(e){
    this.messagesCount = e.target.value;
  }

  get primaryActionStyle() {
    return htmlSafe(this.showPrimaryAction ? 'display: revert;' : 'display: none;');
  }

  <template>
    <EuiTabs>
      {{#each this.tabs as |tab|}}
        <EuiTab
          @isSelected={{eq tab.id this.selectedTab.id}}
          {{on 'click' (fn this.onTabSelection tab)}}
        >
          {{tab.name}}
        </EuiTab>
      {{/each}}
    </EuiTabs>

    <EuiSpacer/>

    {{#let (slice
      0 this.messagesCount this.messages
    ) as |msgs|}}
      <EuiPanel @paddingSize='xs'>
        <EuiNotificationEvent
          @isRead={{this.isRead}}
          @onRead={{this.selectedTab.onRead}}
          @type='Hey!'
          @badgeColor='primary'
          @time='1 min'
          @title='Some nice title'
          @messages={{msgs}}
          @iconType='email'
          @accordionButtonText={{concat '+ ' (sub msgs.length 1) ' more'}}
          @accordionHideText='hide'
        >
          <:contextMenu>
            <EuiContextMenuItem
              {{on 'click' this.onRead}}
            >
              Mark as {{if this.isRead 'unread' 'read'}}
            </EuiContextMenuItem>
          </:contextMenu>

          <:primaryAction>
            <EuiButtonEmpty
              style={{this.primaryActionStyle}}
              @flush="left"
              @size="s"
            >
              Do something!
            </EuiButtonEmpty>
          </:primaryAction>

        </EuiNotificationEvent>
      </EuiPanel>
    {{/let}}

    <EuiSpacer/>

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

