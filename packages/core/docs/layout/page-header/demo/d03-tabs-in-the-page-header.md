---
order: 3
---

```hbs template
<!-- example 2 -->
<EuiPageHeader
  @bottomBorder={{true}}
  @description='This description should be describing the current page as depicted by the current tab. It has grow set to false to ensure a readable line-length.'
	@dumb={{true}}
	@tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
/>
```