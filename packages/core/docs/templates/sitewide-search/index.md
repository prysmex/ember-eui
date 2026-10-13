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
search icon) that opens the popover, with the search inside it;
`@popoverButtonBreakpoints` (e.g. `(array "xs" "s")`) limits that to
those screen sizes, the search stays inline otherwise.

`@searchProps`, `@listProps` and `@popoverProps` tune the search field
(`append`, `onKeyUpCapture`, `inputRef`, `className`, ...), the list
(`className`, `css`, `rowHeight`, ...) and the `EuiPopover` (`width`,
`className`, `anchorPosition`, ...), and `@colorModes` sets the color
mode of the search and of the popover. A `meta` with a custom `type`
(e.g. `PINK`) gets the class
`euiSelectableTemplateSitewide__optionMeta--PINK` to style it with.

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
| `@searchProps` |  |  | Options of the search field, as in `EuiSelectable`: `{ placeholder, compressed, isClearable, value, defaultValue, onChange, onSearch, onKeyDown, onKeyUpCapture, onInput, onClick, onFocus, onBlur, inputRef, className, prepend, append, 'data-test-subj' }`. `append` and `prepend` are a string (a label, e.g. "⌘K") or a component. `onFocus`, `onBlur`, `onKeyDown` and `onInput` run besides the template's own handling (opening and closing the popover). |
| `@listProps` |  |  | Options of the list, as in `EuiSelectable` (`css`, `textWrap`, `truncationProps`, `isVirtualized`...), plus `className`. Defaults: `{ rowHeight: 52, showIcons: false, onFocusBadge: { text: "Go to", iconSide: "right" } }`; yours win. |
| `@popoverProps` | `EuiSelectableTemplateSitewidePopoverProps` |  | Args of the `EuiPopover` housing the list (`anchorPosition`, `panelPaddingSize`, `panelClassName`, `zIndex`, `closePopover`, `panelRef`...), plus `width` (default `600`) and `className`. |
| `@popoverButtonBreakpoints` | `EuiBreakpointSize[]` |  | Screen sizes (`'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`) at which the `<:popoverButton>` replaces the search. Without it, the button always shows (if given). |
| `@colorModes` |  |  | Color modes of the search and of the popover: `'light'`, `'dark'`, `'inverse'` (the opposite of the nearest provider's), `'default'` (the nearest provider's) and, for the popover, `'global'` (the outermost provider's). Both default to `'default'`. |
| `@placeholder` | `string` | "Search for anything..." | Placeholder of the search. |
| `@popoverWidth` | `number` | `600` | Width of the popover content in px; `@popoverProps.width` wins. |
| `@onActiveOptionChange` |  |  | As `EuiSelectable`: called with the current option, or `null`. |
| `@optionMatcher` |  |  | As `EuiSelectable`: decides whether an option matches the search. |
| `@height` |  |  | As `EuiSelectable`: height of the list. |
| `@errorMessage` |  |  | As `EuiSelectable`: error message shown instead of the list. |
| `@allowExclusions` | `boolean` |  | As `EuiSelectable`: pressing a checked option excludes it. |
| `@selectableScreenReaderText` | `string` |  | As `EuiSelectable`: screen reader text before the instructions. |
| `@singleSelection` |  | `true` (one result is chosen) | As `EuiSelectable`. |
| `@loadingMessage` | `string` | "Loading results" | Text while `@isLoading`. |
| `@emptyMessage` | `string` | "No results available" | Text when there are no results. |
| `@noMatchesMessage` | `string` | `@emptyMessage`'s | Text when the search matches nothing. |
| `@isPreFiltered` |  | `false` | The results are already filtered (e.g. by a server), so the search does not filter them again. |
| `@css` | `EuiCss` |  | Styles composed last into the selectable's class (upstream's `css`, part of the rest props spread onto `EuiSelectable`). |

| Block | Description |
| --- | --- |
| `<:popoverButton>` | A button opening the popover (the search moves into it), e.g. an icon in a narrow header; yields the function toggling it. See `@popoverButtonBreakpoints`. |
| `<:popoverTitle>` | Content above the results, e.g. a title. |
| `<:popoverFooter>` | Content below the results, e.g. keyboard shortcuts. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
