---
order: 8
---

# Split buttons


```hbs template
<TodoText/>
<!-- <EuiFlexGroup @responsive={{false}} @gutterSize="xs" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @size="s" @iconType="calendar">
      Last 15 min
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>

    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.popover}}
      @anchorPosition='downCenter'
      @closePopover={{set this 'popover' false}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'popover' true)}}
        >
          Show Popover
        </EuiButton>
      </:button>
      <:content>
        <EuiText @size="m" style="width: 300px;">
          <p>
            Popover content that’s wider than the default width
          </p>
        </EuiText>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup> -->
```