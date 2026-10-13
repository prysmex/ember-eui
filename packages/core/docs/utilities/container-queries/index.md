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

**Not in Ember EUI:** `useEuiContainerQuery` (querying a container from JavaScript). Upstream recommends keeping layout changes in CSS for performance anyway; when you need the size in JavaScript, use the `resize-observer` modifier.

</EuiText>

<EuiSpacer />
