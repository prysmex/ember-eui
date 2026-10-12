---
title: Search bar
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Search bar"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSearchBar` is a search field that parses an EQL-like query into a
`Query`, with optional filter buttons that edit the same query. The syntax
supports free text, `field:value` (also `=`, `>`, `>=`, `<`, `<=`),
`is:flag`, negation with `-`, phrases in quotes, `field:(a or b)` and
`(clause or clause)` groups, numbers, booleans and dates in single quotes.

```hbs
<EuiSearchBar
  @defaultQuery="is:active -status:archived"
  @box={{hash placeholder="Search users" incremental=true}}
  @filters={{this.filters}}
  @onChange={{this.onChange}}
/>
```

`@onChange` receives `{ query, queryText, error }`: a parsed `Query` (or
`null` and the parse `error`). Filter configs are plain objects:

- `{ type: 'is', field, name, negatedName }`: toggles `is:field`.
- `{ type: 'field_value_toggle', field, value, name }`: toggles `field:value`.
- `{ type: 'field_value_toggle_group', field, items: [{ value, name }] }`:
  joined toggles, one value at a time.
- `{ type: 'field_value_selection', field, name, options, multiSelect }`:
  a popover list of values; `options` is an array of `{ value, name, view }`
  or an async loader, `multiSelect` is `true` (and clauses), `'or'` (one
  `field:(a or b)` clause) or `false`.
- `{ type: 'custom_component', component }`: your component, receiving
  `@query` and `@onChange`.

The query engine (`Query`, `AST`, parsing, printing, `Query.execute(query,
items)`, `Query.toESQuery(query)`) is a port of upstream's and can be used
without the component:

```js
import { Query } from '@ember-eui/core/components/eui-search-bar';

const query = Query.parse('tag:(a or b) count>5');
const matches = Query.execute(query, items);
```

### Ember differences

- Tools are the `<:toolsLeft>` and `<:toolsRight>` blocks; the hint's
  content is the `<:hint>` block (or `@hint.content`).
- Custom filter components are Ember components (`@query`, `@onChange`);
  option `view`s are text.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSearchBar

A search field parsing an EQL-like query (`text field:value is:flag
-excluded (a or b)`) into a `Query`, with optional filter buttons and
tools around it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@onChange` |  |  | Called with `{ query, queryText, error }` when the query text or its parse error changes. |
| `@defaultQuery` | `QueryType` |  | The initial query (a `Query` or text). |
| `@query` | `QueryType` |  | Controlled query: when its text differs from the bar's, the bar resets to it. |
| `@box` | `EuiSearchBoxOptions` |  | The search field: `{ placeholder, incremental, schema, isClearable, isLoading, compressed, fullWidth, 'aria-label', 'data-test-subj', … }`. |
| `@filters` | `SearchFilterConfig[]` |  | The filter configs, rendered in an `EuiFilterGroup`. |
| `@dateFormat` | `object` |  | Date format used to parse date values (upstream `dateFormat`). |
| `@hint` | `EuiSearchBarHint` |  | A hint shown below the field while it has focus. |
| `@compressed` | `boolean` |  | Shorter field and filters. |
| `@showErrorTooltip` | `boolean` | `true` | Shows a tooltip with the parse error of an invalid query. With `false`, surface and announce parse errors yourself. |
| `@css` | `EuiCss` |  | Styles composed last into the root flex group's class. |

| Block | Description |
| --- | --- |
| `<:toolsLeft>` | Tools left of the field (in a non-growing flex item). |
| `<:toolsRight>` | Tools right of the filters (in a non-growing flex item). |
| `<:hint>` | The hint's content (instead of `@hint.content`). |

### EuiSearchBarFilters

The filter buttons of an `EuiSearchBar` in an `EuiFilterGroup`, built
from filter configs: `is` (flag toggle), `field_value_toggle`,
`field_value_toggle_group`, `field_value_selection` (popover list) and
`custom_component`. Each filter edits `@query` and calls `@onChange`
with the new `Query`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@query` (required) | `Query` |  | The current query (a `Query`, exported by `components/eui-search-bar`). |
| `@onChange` (required) | `(query: Query) => void` |  | Called with the updated query when a filter changes. |
| `@filters` | `SearchFilterConfig[]` |  | The filter configs. |
| `@compressed` | `boolean` |  | Shorter filter group. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
