---
order: 3
---

# Showing a bottom bar

<EuiSpacer />
<EuiText>
  Put controls in the named bottomBar block. By default the bar stays within the
  page body using sticky positioning, so it does not overlap the side bar.
  Bottom-bar props override padding, position and the region's accessible name.
  The bar becomes static when the default template's full-height layout is active.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    <strong>EuiPageTemplate</strong>
    only supports bottom bars in the
    <EuiCode>default</EuiCode>
    template.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @bottomBarProps={{hash paddingSize='s' landmarkHeading='Save page changes'}}
  @pageHeader={{hash iconType='logoElastic' pageTitle='Page Title'}}
>
  <:pageSideBar>
    <EuiLoadingContent @lines={{8}} />
  </:pageSideBar>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton>
        Go to full screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiLoadingContent @lines={{16}} />
  </:default>
  <:bottomBar>
    <EuiButton>
      Save
    </EuiButton>
  </:bottomBar>
</EuiPageTemplate>
```
