---
title: Skeleton
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Skeleton"/>
<EuiSpacer @size="l" />

<EuiText>

The **EuiSkeleton** components are placeholder components for content which has yet to load. They provide meaningful previews, avoid layout content shifts, and add accessible announcements to screen readers when content is done loading.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Accessibility recommendation" @color="success" @iconType="accessibility">
  <p>The <code>@contentAriaLabel</code> argument should be used to help describe the type of content that is loading to screen reader users. If you do not provide a descriptive label and have multiple loading skeletons on the page, screen reader users may hear a multitude of “Loaded” messages in a row, with no meaningful indication of what actually loaded.</p>
</EuiCallOut>

<EuiSpacer />

<EuiText>

- **`EuiSkeletonText`** stands in for paragraphs, **`EuiSkeletonTitle`** for an `EuiTitle`, **`EuiSkeletonCircle`** for avatars and icons, and **`EuiSkeletonRectangle`** for anything else (images, charts, buttons).
- **`EuiSkeletonLoading`** swaps any loading content for loaded content; the other skeletons are built on it.

While loading, the content is wrapped in an `aria-busy` region and the skeleton is a `progressbar` labelled "Loading {contentAriaLabel}". When it loads, screen readers hear "Loaded {contentAriaLabel}".

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSkeletonText

Placeholder lines for text that is loading, swapped for its block once
loaded.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` | `true` | When true, shows the skeleton; when false, shows the block and announces to screen readers that the content loaded. |
| `@contentAriaLabel` | `string` |  | Label your loading sections to give screen readers more context: pass "API keys" to have them read "Loading API keys" and "Loaded API keys". |
| `@announceLoadingStatus` | `boolean` | `false` | Makes a live screen reader announcement when `@isLoading` is true. |
| `@announceLoadedStatus` | `boolean` | `true` | Makes a live screen reader announcement when `@isLoading` is false. |
| `@ariaLiveProps` | `EuiScreenReaderLiveProps` |  | Options for the live region that announces the status: `{ isActive, role, 'aria-live', focusRegionOnTextChange }`. |
| `@ariaWrapperProps` | `EuiSkeletonAriaWrapperProps` |  | Attributes for the `aria-busy` wrapper around the skeleton. |
| `@css` | `EuiCss` |  | Extra styles composed last into the skeleton's class (like upstream's `css` prop). |
| `@lines` | `number` | `3` | Number of lines to display (1 to 10). |
| `@size` | `EuiSkeletonTextSize` | `'m'` | EuiText size the lines stand in for: `'m'`, `'s'`, `'xs'`, or `'relative'` (`1em`). |

| Block | Description |
| --- | --- |
| default block | The loaded content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiSkeletonTitle

A placeholder bar as tall as an EuiTitle's line, swapped for its block
once loaded.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` | `true` | When true, shows the skeleton; when false, shows the block and announces to screen readers that the content loaded. |
| `@contentAriaLabel` | `string` |  | Label your loading sections to give screen readers more context: pass "API keys" to have them read "Loading API keys" and "Loaded API keys". |
| `@announceLoadingStatus` | `boolean` | `false` | Makes a live screen reader announcement when `@isLoading` is true. |
| `@announceLoadedStatus` | `boolean` | `true` | Makes a live screen reader announcement when `@isLoading` is false. |
| `@ariaLiveProps` | `EuiScreenReaderLiveProps` |  | Options for the live region that announces the status: `{ isActive, role, 'aria-live', focusRegionOnTextChange }`. |
| `@ariaWrapperProps` | `EuiSkeletonAriaWrapperProps` |  | Attributes for the `aria-busy` wrapper around the skeleton. |
| `@css` | `EuiCss` |  | Extra styles composed last into the skeleton's class (like upstream's `css` prop). |
| `@size` | `EuiSkeletonTitleSize` | `'m'` | EuiTitle size it stands in for: `'xxxs'`, `'xxs'`, `'xs'`, `'s'`, `'m'` or `'l'`. |

| Block | Description |
| --- | --- |
| default block | The loaded content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

### EuiSkeletonCircle

A round placeholder, e.g. for an avatar, swapped for its block once
loaded.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` | `true` | When true, shows the skeleton; when false, shows the block and announces to screen readers that the content loaded. |
| `@contentAriaLabel` | `string` |  | Label your loading sections to give screen readers more context: pass "API keys" to have them read "Loading API keys" and "Loaded API keys". |
| `@announceLoadingStatus` | `boolean` | `false` | Makes a live screen reader announcement when `@isLoading` is true. |
| `@announceLoadedStatus` | `boolean` | `true` | Makes a live screen reader announcement when `@isLoading` is false. |
| `@ariaLiveProps` | `EuiScreenReaderLiveProps` |  | Options for the live region that announces the status: `{ isActive, role, 'aria-live', focusRegionOnTextChange }`. |
| `@ariaWrapperProps` | `EuiSkeletonAriaWrapperProps` |  | Attributes for the `aria-busy` wrapper around the skeleton. |
| `@css` | `EuiCss` |  | Extra styles composed last into the skeleton's class (like upstream's `css` prop). |
| `@size` | `EuiSkeletonCircleSize` | `'m'` | `'s'`, `'m'`, `'l'` or `'xl'` (theme sizes l, xl, xxl and 4 × base). |

| Block | Description |
| --- | --- |
| default block | The loaded content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSkeletonRectangle

A rectangular placeholder of any size, e.g. for an image or chart,
swapped for its block once loaded.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` | `true` | When true, shows the skeleton; when false, shows the block and announces to screen readers that the content loaded. |
| `@contentAriaLabel` | `string` |  | Label your loading sections to give screen readers more context: pass "API keys" to have them read "Loading API keys" and "Loaded API keys". |
| `@announceLoadingStatus` | `boolean` | `false` | Makes a live screen reader announcement when `@isLoading` is true. |
| `@announceLoadedStatus` | `boolean` | `true` | Makes a live screen reader announcement when `@isLoading` is false. |
| `@ariaLiveProps` | `EuiScreenReaderLiveProps` |  | Options for the live region that announces the status: `{ isActive, role, 'aria-live', focusRegionOnTextChange }`. |
| `@ariaWrapperProps` | `EuiSkeletonAriaWrapperProps` |  | Attributes for the `aria-busy` wrapper around the skeleton. |
| `@css` | `EuiCss` |  | Extra styles composed last into the skeleton's class (like upstream's `css` prop). |
| `@width` | `string \| number` | `'24px'` | Width: a number (px) or any CSS length. |
| `@height` | `string \| number` | `'24px'` | Height: a number (px) or any CSS length. |
| `@borderRadius` | `EuiSkeletonRectangleRadius` | `'s'` | `'s'` or `'m'` (the theme's inline radius) or `'none'`. |

| Block | Description |
| --- | --- |
| default block | The loaded content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSkeletonLoading

Swaps loading content for loaded content, marking the region
`aria-busy` while loading and announcing the change to screen readers
("Loading …" / "Loaded …"). The other EuiSkeleton components use it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isLoading` | `boolean` | `true` | When true, shows `<:loadingContent>`; when false, shows `<:loadedContent>` and announces to screen readers that it loaded. |
| `@contentAriaLabel` | `string` |  | Label your loading sections to give screen readers more context: pass "API keys" to have them read "Loading API keys" and "Loaded API keys". |
| `@announceLoadingStatus` | `boolean` | `false` | Makes a live screen reader announcement when `@isLoading` is true. |
| `@announceLoadedStatus` | `boolean` | `true` | Makes a live screen reader announcement when `@isLoading` is false. |
| `@ariaLiveProps` | `EuiScreenReaderLiveProps` |  | Options for the live region that announces the status: `{ isActive, role, 'aria-live', focusRegionOnTextChange }` (upstream EuiScreenReaderLive props). |
| `@css` | `EuiCss` |  | Extra styles composed into the wrapper's class (like upstream's `css` prop). |

| Block | Description |
| --- | --- |
| `<:loadingContent>` | Shown while loading. Put `role` and `aria-label` from the yielded object on its root element (upstream adds them to `loadingContent`). |
| `<:loadedContent>` | Shown once loaded. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
