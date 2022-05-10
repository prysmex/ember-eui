---
order: 6
---

# Customizing the page header

<EuiText>
	The page header content props are helpful props to push content into established Elastic page layout patterns. They are completely optional and by design, inflexible. If you need a layout that does not match these patterns you can pass in your own <EuiCode>{{"<:default>"}}</EuiCode> block utilizing the <strong>EuiPageHeaderSection</strong> components.

</EuiText>

```hbs template
<EuiPageHeader @alignItems='center' @bottomBorder={{true}}>
  <EuiPageHeaderSection>
    <EuiTitle @size='l'>
      Page title
    </EuiTitle>
  </EuiPageHeaderSection>
  <EuiPageHeaderSection>Page abilities</EuiPageHeaderSection>
</EuiPageHeader>
```
