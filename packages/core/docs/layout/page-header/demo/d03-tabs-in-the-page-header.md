---
order: 3
---

# Tabs without a title

<EuiText>

Without `@pageTitle`, the tabs become the page's title row.

</EuiText>

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
  @description='This description should be describing the current page as depicted by the current tab. It has grow set to false to ensure a readable line-length.'
	@tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
/>
```