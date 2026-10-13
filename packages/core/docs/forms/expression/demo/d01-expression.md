---
order: 1
---

# Expression

<EuiText>

Use the `EuiExpression` component to surface expressions. It requires both a `@description` (left side) and `@value` (right side). Optionally, you can pass it an `@onClick` action that will convert it to a button and add some additional styling to indicate that it is clickable.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiExpression,
  EuiFieldNumber,
  EuiFlexGroup,
  EuiFlexItem,
  EuiPopover,
  EuiPopoverTitle,
  EuiSelectable,
} from '@ember-eui/core/components';

export default class ExpressionDemo extends Component {
  @tracked openPopover = null;
  @tracked example1Options = [
    { label: 'count()', checked: 'on' },
    { label: 'average()' },
    { label: 'sum()' },
    { label: 'median()' },
    { label: 'min()' },
    { label: 'max()' },
  ];
  @tracked example2Options = [
    { label: 'Is above', checked: 'on' },
    { label: 'Is below' },
    { label: 'Is exactly' },
  ];
  @tracked example3Value = 100;

  get example1Value() {
    return this.example1Options.find((option) => option.checked === 'on')?.label;
  }

  get example2Value() {
    return this.example2Options.find((option) => option.checked === 'on')?.label;
  }

  @action
  open(name) {
    this.openPopover = name;
  }

  @action
  close() {
    this.openPopover = null;
  }

  @action
  changeExample1(options) {
    this.example1Options = options;
    this.openPopover = null;
  }

  @action
  changeExample2(options) {
    this.example2Options = options;
    this.openPopover = null;
  }

  @action
  changeExample3(event) {
    this.example3Value = event.target.value;
  }

  <template>
    <EuiFlexGroup @gutterSize="s">
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{eq this.openPopover "first"}}
          @closePopover={{this.close}}
          @panelPaddingSize="s"
          @anchorPosition="downLeft"
        >
          <:button>
            <EuiExpression
              @description="when"
              @value={{this.example1Value}}
              @isActive={{eq this.openPopover "first"}}
              @onClick={{fn this.open "first"}}
            />
          </:button>
          <:content>
            <EuiSelectable
              @singleSelection="always"
              @options={{this.example1Options}}
              @onChange={{this.changeExample1}}
              as |parts|
            >
              <div style="width: 240px">
                <EuiPopoverTitle>When</EuiPopoverTitle>
                <parts.list />
              </div>
            </EuiSelectable>
          </:content>
        </EuiPopover>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{eq this.openPopover "second"}}
          @closePopover={{this.close}}
          @panelPaddingSize="s"
          @anchorPosition="downLeft"
        >
          <:button>
            <EuiExpression
              @description={{this.example2Value}}
              @isActive={{eq this.openPopover "second"}}
              @onClick={{fn this.open "second"}}
            />
          </:button>
          <:content>
            <EuiSelectable
              @singleSelection="always"
              @options={{this.example2Options}}
              @onChange={{this.changeExample2}}
              as |parts|
            >
              <div style="width: 240px">
                <EuiPopoverTitle>When</EuiPopoverTitle>
                <parts.list />
              </div>
            </EuiSelectable>
          </:content>
        </EuiPopover>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{eq this.openPopover "third"}}
          @closePopover={{this.close}}
          @panelPaddingSize="s"
          @anchorPosition="downLeft"
        >
          <:button>
            <EuiExpression
              @description=""
              @value={{this.example3Value}}
              @isActive={{eq this.openPopover "third"}}
              @onClick={{fn this.open "third"}}
            />
          </:button>
          <:content>
            <EuiFieldNumber
              @compressed={{true}}
              @value={{this.example3Value}}
              aria-label="Value"
              {{on "input" this.changeExample3}}
            />
          </:content>
        </EuiPopover>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
