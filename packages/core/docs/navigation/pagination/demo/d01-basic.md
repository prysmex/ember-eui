---
order: 1
---

# Basic usage with many pages

<EuiText>
		<p><strong>EuiPagination</strong> accepts a total <EuiCode>pageCount</EuiCode> and only shows up to 5 consecutive pages, with shortcuts to the first and/or last page. It also requires the parent component to maintain the current <EuiCode>activePage</EuiCode> and handle the <EuiCode>onPageClick</EuiCode>.</p>
</EuiText>

```hbs template
{{#let (use-state 0) as |activePage|}}
  <EuiPagination
    @compressed={{true}}
    @aria-label='Many pages example'
    @pageCount={{22}}
    @activePage={{activePage.value}}
    @onPageClick={{activePage.setState}}
  />
  <EuiPagination
    @aria-label='Many pages example'
    @pageCount={{22}}
    @activePage={{activePage.value}}
    @onPageClick={{activePage.setState}}
  />
{{/let}}
```
