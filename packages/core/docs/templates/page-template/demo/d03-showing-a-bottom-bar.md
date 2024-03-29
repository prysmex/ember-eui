---
order: 3
---

# Showing a bottom bar

<EuiSpacer />
<!-- <EuiText>
  Adding an
  <strong>EuiBottomBar</strong>
  can be tricky to use and account for any side bars.
  <strong>EuiPageTemplate</strong>
  handles this nicely by supplying a
  <EuiCode>bottomBar</EuiCode>
  prop for passing the contents of your bottom bar, and
  <EuiCode>bottomBarProps</EuiCode>
  that extends
  <strong>EuiBottomBar</strong>.<br /><br />

  <!-- It uses the
  <EuiCode>sticky</EuiCode>
  position so that it sticks to the bottom of and remains within the bounds of
  <strong>EuiPageBody</strong>. This way it will never overlap the
  <strong>EuiPageSideBar</strong>, no matter the screen size. It also means not
  needing to accommodate for the height of the bar in the body element.
</EuiText> -->
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
