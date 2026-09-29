---
title: Sitewide search
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sitewide search"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSelectableTemplateSitewide` is the "Search for anything…" field of an
app's header: typing opens a popover of results, each with an icon,
details (`meta`) and an optional avatar, and keyboard navigation (up,
down, Enter).

```hbs
<EuiSelectableTemplateSitewide
  @options={{this.results}}
  @onSearch={{this.search}}
  @onChange={{this.go}}
/>
```

```js
results = [
  {
    label: 'Revenue by region',
    icon: { type: 'visBarVertical' },
    avatar: { name: 'Sales' },
    meta: [{ text: 'Visualization', type: 'application' }, { text: 'Sales' }],
    url: '/visualize/revenue',
  },
];

go = (options) => {
  const chosen = options.find((option) => option.checked === 'on');
  this.router.transitionTo(chosen.url);
};
```

It filters `@options` by the typed text itself; when a server already
returns matching results, pass `@isPreFiltered={{true}}` and update the
options from `@onSearch`. `meta` entries with a `type` (`'application'`,
`'deployment'`, `'article'`, `'case'`, `'platform'`) get a color, and
`highlightSearchString` highlights the search in them too.

In a narrow header, the `<:popoverButton>` block gives a button (e.g. a
search icon) that opens the popover, with the search inside it.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSelectableTemplateSitewide

The search of a whole site or app ("Search for anything…"): a search
field that opens a popover of results with icons, details and avatars.
You provide the results (filtered from the search, e.g. by a server)
and navigate when one is chosen (`@onChange` gets the options with the
chosen one `checked: 'on'`).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSelectableTemplateSitewideOption[]` |  | The results. |
| `@onChange` |  |  | Called with the options, the chosen one `checked: 'on'`. |
| `@onSearch` | `(searchValue: string) => void` |  | Called with the search text as you type. |
| `@isLoading` | `boolean` |  | Shows "Loading results" instead of the list. |
| `@placeholder` | `string` | "Search for anything..." | Placeholder of the search. |
| `@popoverWidth` | `number` | `600` | Width of the popover in px. |
| `@isPreFiltered` | `boolean` | `false` | The results are already filtered (e.g. by a server), so the search does not filter them again. |

| Block | Description |
| --- | --- |
| `<:popoverButton>` | A button opening the popover (the search moves into it), e.g. an icon in a narrow header; yields the function toggling it. |
| `<:popoverTitle>` | Content above the results, e.g. a title. |
| `<:popoverFooter>` | Content below the results, e.g. keyboard shortcuts. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
