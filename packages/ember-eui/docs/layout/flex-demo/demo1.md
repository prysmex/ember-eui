# Demo

```hbs template
<EuiTitle>
  Flex Group
</EuiTitle>
<EuiSpacer />
<EuiTitle @size="s">
  Flex Wrap
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1); min-width: 300px;">
    Min Width: 300px
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1); min-width: 300px;">
    Min Width: 300px
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1); min-width: 300px;">
    Min Width: 300px
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex Group with unlimited items
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    1
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    2
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    3
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    4
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    5
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    6
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    7
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    8
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    9
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    10
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex Grow
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow="false" style="padding: 16px; background: rgba(27,169,245,0.1);">
    This item won't grow.
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    But this item will.
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex - Proportional Growth
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{1}}>
    1
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{2}}>
    2
    <br />
    wraps content if necessary
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{3}}>
    3
    <br />
    expands_to_fit_if_content_cannot_wrap
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{4}}>
    4
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{6}}>
    6
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{3}}>
    3
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{1}}>
    1
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{3}}>
    3
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow={{6}}>
    6
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex - Justify and Align
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @justifyContent="spaceEvenly">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    One here on the left
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    The other over here on the right.
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @justifyContent="spaceBetween">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    One here on the left
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    The other over here on the right.
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @justifyContent="spaceAround">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    I’m a single centered item!
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @alignItems="center">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    <EuiText>
      <p>
        I
      </p>
      <p>
        am
      </p>
      <p>
        really
      </p>
      <p>
        tall
      </p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    I am vertically centered!
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex Groups can change direction
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @direction="column">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    Content grid item
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    Another content grid item
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);" @grow="false">
    Using the column direction
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex Grids for repeatable grids - can have up to 4 columns
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGrid @columns={{4}}>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      One
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Two
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Three
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Four
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Five
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Six
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Seven
    </div>
  </EuiFlexItem>
</EuiFlexGrid>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Flex Grids can change direction
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGrid @direction="column" @columns={{2}}>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      One
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Two
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Three
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Four
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Five
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Six
    </div>
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    <div>
      Seven
    </div>
  </EuiFlexItem>
</EuiFlexGrid>
<EuiSpacer @size="xl" />
<EuiTitle @size="s">
  Gutter Size for both Grids and Groups
</EuiTitle>
<EuiSpacer @size="s" />
<EuiFlexGroup @gutterSize="none">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    None
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    None
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    None
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    None
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @gutterSize="xs">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra small
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @gutterSize="s">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Small
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Small
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @gutterSize="m">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Medium
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Medium
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Medium
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Medium
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @gutterSize="l">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Large (default)
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Large (default)
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Large (default)
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Large (default)
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @gutterSize="xl">
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra Large
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra Large
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra Large
  </EuiFlexItem>
  <EuiFlexItem style="padding: 16px; background: rgba(27,169,245,0.1);">
    Extra Large
  </EuiFlexItem>
</EuiFlexGroup>
```