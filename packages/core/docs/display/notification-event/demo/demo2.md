---
order: 2
---

# Read state

```hbs template
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
        <!-- ToDo Missing EuiContextMenu component -->
        <button
          class="euiContextMenuItem"
          type="button"
          {{on 'click' this.onRead}}
        >
          <span class="euiContextMenu__itemLayout">
            <span class="euiContextMenuItem__text">
              Mark as {{if this.isRead 'unread' 'read'}}
            </span>
          </span>
        </button>
      </:contextMenu>

      <:primaryAction>
        <EuiButtonEmpty
          style="display: {{if this.showPrimaryAction '' 'none'}};"
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
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

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

}
```