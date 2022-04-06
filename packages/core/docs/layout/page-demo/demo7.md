---
order: 7
---

# Full height layout

<EuiText>
  Though it is not recomended for most layouts, some require the control of scrolling to be handled through child components. You can achieve this through nested flex groups and overflow properties; adding certain combinations of CSS overflow utility classes to these children. There are a few <strong>caveats</strong> to understand when trying to achieve full height layouts with <strong>EuiPageTemplate</strong>.

  <ol>
    <li>Using the <EuiCode>fullHeight</EuiCode> prop adds an extra layer of <strong>EuiFlexGroup</strong> and <strong>EuiFlexItem</strong> around the template children to negate the negative margins.</li>
    <li>Using <EuiCode>fullHeight=true</EuiCode> will automatically add scrolling behavior to the <strong>EuiFlexItem</strong> that wraps the children.</li>
    <li>Using <EuiCode>fullHeight="noscroll"</EuiCode> removes all scrolling behavior and your layouts will break if you do not manually add them.</li>
    <li>When using either values for <EuiCode>fullHeight</EuiCode>, there will always be a minimum height of <EuiCode>460px</EuiCode> to the page contents.</li>
    <li>Full height layouts are restricted to <strong>medium breakpoints</strong> and above. We recommend retaining any responsive behavior and allowing normal page scroll on smaller screens.</li>
  </ol>
</EuiText>
<EuiSpacer />
<EuiCallOut @iconType="accessibility" @color="warning">
  <:title>
   When applying the <EuiCode>.eui-yScroll</EuiCode> class, it is recommended to also apply <EuiCode>tabindex=0</EuiCode> to ensure keyboard users can scroll these containers.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate @grow={{true}} @fullHeight={{true}} @template='empty'>
  <EuiFlexGroup
    class='eui-fullHeight'
    @gutterSize='none'
    @direction='column'
    @responsive={{false}}
  >
    <EuiFlexItem class='eui-yScroll'>
      <EuiFlexItem @grow={{false}}>
        <EuiPanel @color='danger' />
      </EuiFlexItem>
      <EuiSpacer @size='l' />
      <EuiFlexItem class='eui-fullHeight'>
        <EuiFlexGroup class='eui-fullHeight' @gutterSize='l'>
          <EuiFlexItem @grow={{2}}>
            <EuiPanel tabIndex={{0}} class='eui-yScroll' @hasShadow={{false}}>
              <EuiLoadingContent @lines={{8}} />
              <EuiSpacer />
              <EuiLoadingContent @lines={{8}} />
            </EuiPanel>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiPanel @hasShadow={{false}} />
            <EuiSpacer />
            <EuiButton>
              Go full screen
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
    </EuiFlexItem>
  </EuiFlexGroup>
</EuiPageTemplate>
```
