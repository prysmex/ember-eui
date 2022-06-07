---
order: 1
---



```hbs template
{{#let (use-state 0) as |activePage|}}
  <EuiPagination
    @aria-label='Many pages example'
    @pageCount={{22}}
    @activePage={{activePage.value}}
    @onPageClick={{activePage.setState}}
  />
{{/let}}
```
