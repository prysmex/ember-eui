---
order: 4
---

# Buttons with icons


```hbs template
<div>

  <EuiFlexGroup
    @responsive={{false}}
    @wrap={{true}}
    @gutterSize="s"
    @alignItems="center"
  >
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="heart">
        Primary
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton
        @fill={{true}}
        @iconType="lensApp"
      >
        Filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="heart" @size="s">
        Small
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="lensApp" @size="s" @fill={{true}}>
        Small and filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{true}}>
      <EuiButton fullWidth @iconType="lensApp">
        Full width
      </EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @iconType="lensApp">
        Empty button
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @iconType="lensApp" @size="s">
        Small empty
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty @iconType="lensApp" @size="xs">
        Extra small empty
      </EuiButtonEmpty>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconSide="right" @iconType="arrowDown">
        Icon right
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton
        @iconSide="right"
        @fill={{true}}
        @iconType="arrowDown"
      >
        Filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton
        @iconSide="right"
        @iconType="arrowDown"
        @size="s"
      >
        Small
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton
        @iconSide="right"
        @iconType="arrowDown"
        @size="s"
        @fill={{true}}
      >
        Small and filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{true}}>
      <EuiButton
        fullWidth
        @iconSide="right"
        @iconType="arrowDown"
      >
        Full width
      </EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty
        @iconSide="right"
        @iconType="arrowDown"
      >
        Icon right
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty
        @iconSide="right"
        @iconType="arrowDown"
        @size="s"
      >
        Small empty
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty
        @iconSide="right"
        @iconType="arrowDown"
        @size="xs"
      >
        Extra small empty
      </EuiButtonEmpty>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="heart" @isDisabled={{true}}>
        Disabled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton @fill={{true}} @iconType="lensApp" @isDisabled={{true}}>
        Filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton @iconType="heart" @size="s" @isDisabled={{true}}>
        Small
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButton
        @iconType="lensApp"
        @size="s"
        @fill={{true}}
        @isDisabled={{true}}
      >
        Small and filled
      </EuiButton>
    </EuiFlexItem>

    <EuiFlexItem @grow={{true}}>
      <EuiButton fullWidth @iconType="lensApp" @isDisabled={{true}}>
        Full width
      </EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty
        @isDisabled={{true}}
        @color="text"
        @iconType="dashboardApp"
      >
        Disabled app icon
      </EuiButtonEmpty>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiButtonEmpty
        @isDisabled={{true}}
        @color="text"
        @iconType="arrowDown"
        @iconSide="right"
        @size="xs"
      >
        Disabled icon right
      </EuiButtonEmpty>
    </EuiFlexItem>
  </EuiFlexGroup>

</div>
```