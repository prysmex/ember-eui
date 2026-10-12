---
order: 8
---

# Split buttons

<EuiText>

`EuiSplitButton` joins a primary action and a secondary icon action into
one control. It yields `ActionPrimary` (an `EuiButton`, or an
`EuiButtonIcon` with `@isIconOnly`) and `ActionSecondary` (an
`EuiButtonIcon` that needs an `aria-label`). `@size`, `@color`, `@fill`,
`@isDisabled` and `@isLoading` apply to both. Pass `@popoverProps` to the
secondary action to anchor a popover to it (its icon is then always the
down chevron); its block is the popover content.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="m" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiSplitButton as |split|>
      <split.ActionPrimary>Primary action</split.ActionPrimary>
      <split.ActionSecondary
        aria-label="More actions"
        @popoverProps={{hash isOpen=this.isOpen closePopover=this.close}}
        {{on "click" this.toggle}}
      >
        <EuiContextMenuPanel @size="s">
          <EuiContextMenuItem @icon="copy">Duplicate</EuiContextMenuItem>
          <EuiContextMenuItem @icon="trash">Delete</EuiContextMenuItem>
        </EuiContextMenuPanel>
      </split.ActionSecondary>
    </EuiSplitButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSplitButton @fill={{true}} @size="s" as |split|>
      <split.ActionPrimary @iconType="play">Run</split.ActionPrimary>
      <split.ActionSecondary
        @iconType="gear"
        aria-label="Run settings"
        @tooltipProps={{hash content="Run settings"}}
      />
    </EuiSplitButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSplitButton @color="text" @size="s" as |split|>
      <split.ActionPrimary @iconType="calendar" @isIconOnly={{true}} aria-label="Pick a date" />
      <split.ActionSecondary @iconType="refresh" aria-label="Refresh" />
    </EuiSplitButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiSplitButton @isDisabled={{true}} as |split|>
      <split.ActionPrimary>Disabled</split.ActionPrimary>
      <split.ActionSecondary @iconType="boxesVertical" aria-label="More" />
    </EuiSplitButton>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SplitButtonDemo extends Component {
  @tracked isOpen = false;

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
