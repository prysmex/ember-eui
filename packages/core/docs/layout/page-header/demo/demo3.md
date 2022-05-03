---
order: 3
---

# Tabs

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
  @description='This description should be describing the current page as depicted by the page title. It will never extend beneath the right side content.'
	@dumb={{true}}
	@tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
/>
```