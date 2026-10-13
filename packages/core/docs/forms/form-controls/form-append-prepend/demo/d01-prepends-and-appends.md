---
order: 1
---

# Prepends and appends

<EuiText>

Most form controls accept a `<:prepend>` and `<:append>` block that allows passing a string or a single node. These are great for demarcating the input's metric like "px" or "ms".

Use the dedicated `EuiFormPrepend` and `EuiFormAppend` components to pass the content and ensure expected styling.

Where needed, you can wrap those components with other container components like `EuiPopover` or `EuiToolTip`.

You can render the prepend and append content as an interactive button element by setting `@element="button"` on `EuiFormPrepend` and `EuiFormAppend` and passing `@onClick` as handler.

**`<:prepend>` and `<:append>` only support single interactions.**

The switches above the examples are docs-only helpers.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, get } from '@ember/helper';
import {
  EuiFieldText,
  EuiFlexGroup,
  EuiFormAppend,
  EuiFormPrepend,
  EuiNotificationBadge,
  EuiPopover,
  EuiSpacer,
  EuiSwitch,
  EuiToolTip,
} from '@ember-eui/core/components';

export default class PrependAppendDemo extends Component {
  toggles = [
    { key: 'compressed', label: 'compressed' },
    { key: 'disabled', label: 'disabled' },
    { key: 'readOnly', label: 'readOnly' },
  ];

  noop = () => {};

  @tracked flags = {};

  @action
  toggle(key, event) {
    this.flags = { ...this.flags, [key]: event.target.checked };
  }

  <template>
    <EuiFlexGroup @responsive={{false}}>
      {{#each this.toggles as |toggle|}}
        <EuiSwitch
          @label={{toggle.label}}
          @checked={{get this.flags toggle.key}}
          @onChange={{fn this.toggle toggle.key}}
        />
      {{/each}}
    </EuiFlexGroup>

    <EuiSpacer />

    <EuiFlexGroup @direction="column" @gutterSize="m">
      <EuiFieldText
        @id="input-0"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend><EuiFormPrepend @label="String" /></:prepend>
        <:append><EuiFormAppend @label="String" @iconLeft="gear" /></:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-1"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend><EuiFormPrepend @label="String" @iconRight="gear" /></:prepend>
        <:append>
          <EuiFormAppend
            @element="button"
            @label="String"
            @iconLeft="gear"
            @onClick={{this.noop}}
          />
        </:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-2"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend>
          <EuiFormPrepend @label="String" @iconLeft="vectorSquare" @iconRight="gear" />
        </:prepend>
        <:append>
          <EuiFormAppend
            @element="button"
            @label="String"
            @iconLeft="gear"
            @iconRight="vectorSquare"
            @onClick={{this.noop}}
          />
        </:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-3"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend>
          <EuiFormPrepend @label="String" @iconLeft="vectorSquare" @iconRight="gear">
            <EuiNotificationBadge @color="subdued">1</EuiNotificationBadge>
          </EuiFormPrepend>
        </:prepend>
        <:append>
          <EuiFormAppend
            @element="button"
            @label="String"
            @iconLeft="gear"
            @iconRight="vectorSquare"
            @onClick={{this.noop}}
          >
            <EuiNotificationBadge>1</EuiNotificationBadge>
          </EuiFormAppend>
        </:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-4"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend>
          <EuiToolTip @content="content"><EuiFormPrepend @label="Tooltip" /></EuiToolTip>
        </:prepend>
        <:append>
          <EuiToolTip @content="content">
            <EuiFormAppend @element="button" @label="Tooltip" @onClick={{this.noop}} />
          </EuiToolTip>
        </:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-5"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend>
          <EuiPopover @isOpen={{false}} @closePopover={{this.noop}}>
            <:button>
              <EuiFormPrepend
                @element="button"
                @iconLeft="calendar"
                @iconRight="chevronSingleDown"
                @onClick={{this.noop}}
              />
            </:button>
            <:content>Popover content</:content>
          </EuiPopover>
        </:prepend>
        <:append>
          <EuiPopover @isOpen={{false}} @closePopover={{this.noop}}>
            <:button>
              <EuiFormAppend
                @element="button"
                @iconRight="chevronSingleDown"
                @label="Popover"
                @onClick={{this.noop}}
              />
            </:button>
            <:content>Popover content</:content>
          </EuiPopover>
        </:append>
      </EuiFieldText>

      <EuiFieldText
        @id="input-6"
        placeholder="Text field"
        @compressed={{this.flags.compressed}}
        @disabled={{this.flags.disabled}}
        @readOnly={{this.flags.readOnly}}
      >
        <:prepend><EuiFormPrepend @iconLeft="vectorSquare" /></:prepend>
        <:append>
          <EuiFormAppend @element="button" @iconLeft="gear" @onClick={{this.noop}} />
        </:append>
      </EuiFieldText>
    </EuiFlexGroup>
  </template>
}
```
