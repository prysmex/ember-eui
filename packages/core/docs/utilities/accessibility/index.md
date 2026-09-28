---
title: Accessibility
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Accessibility"/>
<EuiSpacer @size="l" />

<EuiText>

Helpers for content that only screen reader and keyboard users need.

- **`EuiScreenReaderOnly`** hides its content visually but keeps it for
  screen readers, e.g. the text of an icon-only control or extra context
  in a table. `@showOnFocus` shows it while something in it has focus.
- **`EuiSkipLink`** is a "Skip to main content" link, hidden until a
  keyboard user tabs to it, so they can jump past the header.

```hbs
<EuiSkipLink @destinationId="main-content" @position="fixed">
  Skip to main content
</EuiSkipLink>

<EuiButtonIcon @iconType="trash" aria-label="Delete" />
<EuiScreenReaderOnly>Deleting cannot be undone.</EuiScreenReaderOnly>
```

To hide a single element without a wrapper, the `screenReaderOnly`
modifier does the same: `<span &#123;&#123;screenReaderOnly}}>…</span>`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiScreenReaderOnly

Hides its content visually but keeps it for screen readers, e.g. a
table caption or the text of an icon-only control. To hide one element
without a wrapper, use the `screenReaderOnly` modifier instead.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@showOnFocus` | `boolean` |  | Shows the content while something in it has keyboard focus, e.g. a "Skip to content" link. |

| Block | Description |
| --- | --- |
| default block | The content read by screen readers. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiSkipLink

A link for keyboard users to jump past repeated content (like the
header) to the main content. It is hidden until focused, so put it
first in the page.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@destinationId` (required) | `string` |  | Id of the element to jump to (without `#`), e.g. `'main-content'`. Give that element `tabindex="-1"` if it is not focusable itself. |
| `@position` | `'static' \| 'fixed' \| 'absolute'` | `'static'` | Where the link shows when focused: `'static'` (in place), `'fixed'` (top left of the viewport) or `'absolute'`. |
| `@tabIndex` | `number` |  | `tabindex` of the link; a fixed link always gets `0`. |

| Block | Description |
| --- | --- |
| default block | The link text, e.g. "Skip to main content". |

</EuiText>
<!-- api:end -->
