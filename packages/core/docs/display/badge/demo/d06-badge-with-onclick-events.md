---
order: 6
---

# Badge with onClick events

<EuiText>

Badges can have `@onClick` events applied to the badge itself or the icon within the badge. The latter option is useful for when you might use badges in other components (like a tag system with autocomplete where you need close events).

</EuiText>
<EuiSpacer />
<EuiCallOut @size="s" @title="@onClick with @iconOnClick">
  <p>When providing both these click handlers, <strong>EuiBadge</strong> must alter the contents so that it does not contain nested button tags. Please make note that if you provide attributes other than those explicit to <strong>EuiBadge</strong>, they will always be applied to the main <code>button</code> tag which may be inside of the outer most tag.</p>
</EuiCallOut>
<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { EuiBadge, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

export default class BadgeOnClickDemo extends Component {
  noop = () => {};

  <template>
    <EuiFlexGroup @wrap={{true}} @responsive={{false}} @gutterSize="xs">
      <EuiFlexItem @grow={{false}}>
        <EuiBadge
          @color="primary"
          @onClick={{this.noop}}
          @onClickAriaLabel="Example of onClick event for the button"
          data-test-sub="testExample1"
        >
          onClick on text within badge
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge
          @color="hollow"
          @iconType="cross"
          @iconSide="right"
          @iconOnClick={{this.noop}}
          @iconOnClickAriaLabel="Example of onClick event for icon within the button"
          data-test-sub="testExample2"
        >
          onClick on icon within badge
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge
          @color="success"
          @iconType="cross"
          @iconSide="right"
          @onClick={{this.noop}}
          @onClickAriaLabel="Example of onClick event for the button"
          @iconOnClick={{this.noop}}
          @iconOnClickAriaLabel="Example of onClick event for icon within the button"
          data-test-sub="testExample3"
        >
          onClick on both text and icon within badge
        </EuiBadge>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiBadge
          @isDisabled={{true}}
          @color="danger"
          @onClick={{this.noop}}
          @onClickAriaLabel="Example of disabled button badge"
          @iconOnClick={{this.noop}}
          @iconOnClickAriaLabel="Example of disabled button badge"
          data-test-sub="testExample4"
        >
          disabled button badge
        </EuiBadge>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

