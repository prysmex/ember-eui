---
order: 2
---

# Restricting page width

<EuiSpacer />
<EuiText>
  Most content does not scale well to the full width of the window. You can
  restrict this to a typical width and center the page by setting the
  <EuiCode>restrictWidth</EuiCode>
  prop to
  <EuiCode>true</EuiCode>
  on
  <strong>EuiPageHeader</strong>
  and
  <strong>EuiPageContent</strong>. You can also pass an integer to this property
  to max out the width at a custom pixel value or a string with a custom
  measurement.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    The
    <strong>EuiPageTemplate</strong>
    allows setting this property at the top level and defaults to true.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @restrictWidth='75%'
  @grow={{true}}
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    tabs=this.tabs
    description='Restricting the width to 75%.'
  }}
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
</EuiPageTemplate>
```
