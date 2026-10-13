---
title: Scroll
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Scroll"/>
<EuiSpacer @size="l" />

<EuiText>

Scrollable regions must be focusable so keyboard only users can reach their content: add `tabindex="0"` to the region (and give it a role and an `aria-label` when it is promoted to a region). See Deque's `scrollable-region-focusable` rule.

Upstream offers the `eui-scrollBar`, `eui-yScroll`, `eui-xScroll` (and `WithShadows`) class names and the `useEuiScrollBar`/`useEuiOverflowScroll` hooks. In Ember EUI the class names are not injected globally (see CSS utility classes) and there are no hooks. `@ember-eui/core/theming` exports the underlying style functions instead; use them in an `@css` theme function, with the theme given as the first argument:

* `euiScrollBarStyles(theme, { thumbColor, trackColor, width, size, corner })`: the minimal scroll bar. Best on small, inner page regions with `overflow: auto`.
* `euiYScroll(theme, { height })`: vertical scrolling (height defaults to `100%`) with the minimal scroll bar. Give the container a `height` (or `max-height`) if you do not want it to stretch.
* `euiYScrollWithShadows(theme, { height, side, hasAnimatedOverflowShadow })`: the same, masking the top and bottom edges to show there is more content (used in modals and flyouts). `side` is `'both'`, `'start'` or `'end'`. Add a little padding at the ends of the content so the mask does not cover it.

```js
import { euiYScroll } from '@ember-eui/core/theming';

const scrollable = (theme) => euiYScroll(theme, { height: '200px' });
```

```hbs
<EuiPanel @css={{scrollable}} tabindex="0">…</EuiPanel>
```

**Not in Ember EUI:** the horizontal helpers (`euiXScroll`, `useEuiOverflowScroll('x')`); use `overflow-x: auto` together with `euiScrollBarStyles` for the same result.

</EuiText>

<EuiSpacer />
