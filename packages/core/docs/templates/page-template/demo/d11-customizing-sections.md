---
order: 11
---

# Customizing sections and header blocks

<EuiText>
  Nested props override the layout defaults. This example disables sticky
  navigation, uses smaller padding and a numeric content width, and supplies
  breadcrumbs and title styling. Header blocks provide markup without adding
  another page header or main landmark.
</EuiText>

```hbs template
<EuiPageTemplate
  @paddingSize='m'
  @pageSideBarProps={{hash sticky=false paddingSize='s'}}
  @pageBodyProps={{hash paddingSize='m'}}
  @pageContentProps={{hash hasBorder=true hasShadow=false paddingSize='s'}}
  @pageContentBodyProps={{hash restrictWidth=640 paddingSize='m'}}
  @pageHeader={{hash
    breadcrumbs=(array (hash text='Projects' href='#projects'))
    pageTitleProps=(hash className='eui-textTruncate')
    alignItems='bottom'
    restrictWidth=720
    bottomBorder=false
  }}
>
  <:pageSideBar><EuiText><p>Project navigation</p></EuiText></:pageSideBar>
  <:pageHeaderPageTitle><span>Project <em>overview</em></span></:pageHeaderPageTitle>
  <:pageHeaderDescription><p>Manage your team's projects.</p></:pageHeaderDescription>
  <:pageHeaderDefault><EuiText><p>Additional header content.</p></EuiText></:pageHeaderDefault>
  <:pageHeaderRightSideItems as |Item|>
    <Item><EuiButton @fill={{true}}>New project</EuiButton></Item>
  </:pageHeaderRightSideItems>
  <:default><EuiLoadingContent @lines={{8}} /></:default>
</EuiPageTemplate>
```
