---
title: Timeline
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Timeline"/>
<EuiSpacer @size="l" />

<EuiText>

Use a timeline to display an ordered sequence of events. Each
`EuiTimelineItem` combines an icon with event content, and `@gutterSize`
controls the space between events.

```hbs
<EuiTimeline aria-label="Deployment history">
  <EuiTimelineItem @icon="check" @iconAriaLabel="Completed">
    Deployed version 3
  </EuiTimelineItem>
  <EuiTimelineItem @verticalAlign="top">
    <:icon><EuiAvatar @name="Jane Cooper" /></:icon>
    <:default>Jane approved the release</:default>
  </EuiTimelineItem>
</EuiTimeline>
```

Use the `<:icon>` block for custom icon content. When `@icon` is a string,
the component renders it in a subdued `EuiAvatar`; provide
`@iconAriaLabel` when the icon communicates information.

</EuiText>

<EuiSpacer />

<EuiText>

This component allows you to create any type of timeline, but for more specific use cases you should consider:

*   `EuiSteps`: a timeline that allows you to present instructional content that must be conducted in a particular order and might contain progress indications.
*   `EuiCommentList`: a timeline that allows you to display comments or logging actions that either a user or a system has performed.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Accessibility requirement" @iconType="accessibility">
  For accessibility, it is required to wrap your <strong>EuiTimelineItem</strong>s with an <strong>EuiTimeline</strong>. It is highly recommended to provide a descriptive <EuiCode>aria-label</EuiCode>, or a text node ID of an external label to the <EuiCode>aria-labelledby</EuiCode> attribute of the <strong>EuiTimeline</strong>.
</EuiCallOut>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTimeline

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@items` | `EuiTimelineItemData[]` |  | Simple item data; use the default block for rich event content. |
| `@gutterSize` | `EuiTimelineGutterSize` | `'xl'` | Vertical space between items. |
| `@css` | `EuiCss` |  | Extra styles composed last into the timeline class. |

| Block | Description |
| --- | --- |
| default block | Rich timeline items, rendered after any simple `@items`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ol>`.

### EuiTimelineItem

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@icon` | `EuiTimelineIconType` |  | EuiIcon type rendered in a subdued avatar. |
| `@iconAriaLabel` | `string` |  | Accessible label for a string icon; an omitted label is decorative. |
| `@verticalAlign` | `EuiTimelineVerticalAlign` | `'center'` | Align the icon and event at their top or center. |
| `@css` | `EuiCss` |  | Extra styles composed last into the list item class. |

| Block | Description |
| --- | --- |
| default block | Event content rendered beside the icon. |
| `<:icon>` | Custom icon content instead of the default avatar. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>`.

### EuiTimelineItemEvent

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@verticalAlign` | `EuiTimelineVerticalAlign` | `'center'` | Align at the top or center of the icon. |
| `@css` | `EuiCss` |  | Extra styles composed last into the event class. |

| Block | Description |
| --- | --- |
| default block | Event content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTimelineItemIcon

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@icon` | `EuiTimelineIconType` |  | EuiIcon type rendered in a subdued avatar. |
| `@iconAriaLabel` | `string` |  | Accessible label for a string icon; an omitted label is decorative. |
| `@verticalAlign` | `EuiTimelineVerticalAlign` | `'center'` | Align at the top or center of the event. |
| `@css` | `EuiCss` |  | Extra styles composed last into the icon-column class. |

| Block | Description |
| --- | --- |
| default block | Custom icon content instead of the default avatar. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
