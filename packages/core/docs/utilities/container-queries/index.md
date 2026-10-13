---
title: Container queries
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Container queries"/>
<EuiSpacer @size="l" />

<EuiText>

Container queries let styles adapt to the space available in an element's parent container instead of the whole viewport, so a component stays responsive wherever you place it, for example in a narrow flyout or beside an expanded sidebar.

Ember EUI exports upstream's helpers from `@ember-eui/core/theming`:

* `euiContainerCSS(type, name?, scrollState?)` returns styles that establish a containment context. `type` is `'size'`, `'inline-size'` or `'normal'`. Pass it as `@css` to the element that acts as the container.
* `euiContainerQuery(conditions, containerName?)` returns the `@container` rule opener for a style string. All conditions must be wrapped in parentheses and can use `and`, `or` and `not` (size, scroll-state or style queries). Without a `containerName` the nearest ancestor with containment is queried.

```js
import { EuiText } from '@ember-eui/core/components';
import { euiContainerCSS, euiContainerQuery } from '@ember-eui/core/theming';

const container = euiContainerCSS('inline-size');
const small = ({ euiTheme }) => `
  ${euiContainerQuery('(width < 300px)')} { color: ${euiTheme.colors.danger}; }
`;

<template>
  <EuiText @css={{container}}>
    <EuiText @css={{small}}>Red when the container is narrower than 300px</EuiText>
  </EuiText>
</template>
```

A `@css` function receives the theme (`{ euiTheme, colorMode, ... }`), so the query can use tokens.

### Reading the result in templates and JavaScript

Upstream's `useEuiContainerQuery` hook reports whether a container query matches. Ember EUI has two equivalents, both built on the same `matchContainer` technique as upstream (a `transitionrun` listener on a custom property that the query changes), so they work wherever container queries do:

* **EuiContainerQuery** renders a `<div>` that is the container (`@type` defaults to `'inline-size'`) and yields `true` while `@condition` matches, with an optional `@name` and an `@onChange` callback.
* The `container-query` modifier (`{{containerQuery "(width > 400px)" name="sidebar" onChange=this.update}}`, import it from `@ember-eui/core/modifiers`) is the lower level piece. The element it is attached to is the one that is queried, so it must be inside a container (an ancestor with `container-type`, e.g. `euiContainerCSS`). `onChange` is called with the result on setup and on each change.

Upstream recommends doing layout changes in CSS (`euiContainerQuery`) and using the hook only when the result is needed in JavaScript.

</EuiText>

<EuiSpacer />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiContainerQuery

A container that yields whether a CSS container query matches its width
or height (the Ember counterpart of upstream's `useEuiContainerQuery`):

```hbs
<EuiContainerQuery @condition="(width > 400px)" as |matches|>
  {{if matches "Wide" "Narrow"}}
</EuiContainerQuery>
```

It renders a `<div>` that establishes the container (`container-type:
inline-size` by default) and a hidden probe inside it that the query is
evaluated for. Prefer styling with `euiContainerQuery` in CSS; use this
when the result is needed in templates or JavaScript.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@condition` (required) | `string` |  | A CSS container condition, e.g. `(min-width: 400px)`. |
| `@name` | `string` |  | Optional container name, e.g. `sidebar`. |
| `@type` | `EuiContainerType` | `'inline-size'`; use `'size'` to query the height too (the container then needs a height of its own) | The `container-type` of the container. |
| `@onChange` | `(matches: boolean) => void` |  | Called with the result on render and whenever it changes. |

| Block | Description |
| --- | --- |
| default block | Yields `true` while the container matches the condition. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
