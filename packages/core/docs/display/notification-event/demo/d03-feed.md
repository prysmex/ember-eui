---
order: 3
---

# Feed

```hbs template
<div>
  {{#each this.items as |item|}}
    {{#let (slice
      0 this.messagesCount (shuffle item.messages)
    ) as |msgs|}}
      <EuiNotificationEvent
        @type={{item.type}}
        @badgeColor={{item.badgeColor}}
        @time={{item.time}}
        @title={{item.title}}
        @messages={{msgs}}
        @iconType={{item.iconType}}
        @accordionButtonText={{concat '+ ' (sub msgs.length 1) ' more'}}
        @accordionHideText='hide'
      >

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
    {{/let}}
  {{/each}}
</div>

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

export default class NotificationEvent3Component extends Component {
  @tracked messagesCount;
  @tracked showPrimaryAction;
  
  messages = [
    'This is a message',
    "Wait, there's more",
    'hmmm...'
  ]

  items = [
    {
      messages: this.messages,
      iconType: 'email',
      badgeColor: 'primary',
      type: 'Hey',
      time: '1 min',
      title: 'Welcome'
    },
    {
      messages: this.messages,
      iconType: 'tag',
      badgeColor: 'accent',
      type: 'News',
      time: '3 min',
      title: 'Someone tagged you'
    },
    {
      messages: this.messages,
      iconType: 'bug',
      badgeColor: 'warning',
      type: 'Alert',
      time: '10 min',
      title: 'Found a bug'
    }
  ]

  constructor() {
    super(...arguments);
    this.messagesCount = 1;
    this.showPrimaryAction = false;
  }

  @action
  setMessagesCount(e){
    this.messagesCount = e.target.value;
  }

}
```