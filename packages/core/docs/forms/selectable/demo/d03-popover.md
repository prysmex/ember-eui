---
order: 3
---

# In a popover, with custom options

<EuiText>

A picker in a popover: the yielded parts put the search in the popover's
title, and the option blocks add an avatar and the email under each name.

</EuiText>

```hbs template
<EuiPopover
  @isOpen={{this.isOpen}}
  @closePopover={{this.close}}
  @panelPaddingSize="none"
  @anchorPosition="downLeft"
>
  <:button>
    <EuiButton @iconType="arrowDown" @iconSide="right" {{on "click" this.toggle}}>
      Assignees ({{this.count}})
    </EuiButton>
  </:button>
  <:content>
    <div style="width: 300px;">
      <EuiSelectable
        @options={{this.people}}
        @onChange={{this.setPeople}}
        @searchable={{true}}
        @listProps={{hash rowHeight=50}}
        as |parts|
      >
        <EuiPopoverTitle @paddingSize="s"><parts.search /></EuiPopoverTitle>
        <parts.list>
          <:optionPrepend as |person|>
            <EuiAvatar @name={{person.label}} @size="s" />
          </:optionPrepend>
          <:option as |person search|>
            <EuiHighlight @text={{person.label}} @search={{search}} />
            <EuiText @size="xs" @color="subdued"><small>{{person.email}}</small></EuiText>
          </:option>
        </parts.list>
      </EuiSelectable>
    </div>
  </:content>
</EuiPopover>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SelectablePopover extends Component {
  @tracked isOpen = false;
  @tracked people = [
    { label: 'Ada Lovelace', email: 'ada@example.com', checked: 'on' },
    { label: 'Alan Turing', email: 'alan@example.com' },
    { label: 'Grace Hopper', email: 'grace@example.com' },
    { label: 'Margaret Hamilton', email: 'margaret@example.com' },
  ];

  get count() {
    return this.people.filter((person) => person.checked).length;
  }

  @action
  setPeople(options) {
    this.people = options;
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }
}
```
