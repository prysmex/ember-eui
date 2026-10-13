---
title: Comment List
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Comment List"/>
<EuiSpacer @size="l" />

<EuiText>

The **EuiCommentList** is a timeline component built on top of **EuiTimeline**. It allows you to display comments or logged actions that either a user or a system has performed.

</EuiText>
<EuiSpacer />
<EuiCallOut @color="primary" @iconType="accessibility" @size="s" @title="Accessibility recommendation">
  <p>Provide a descriptive <code>aria-label</code> or the ID of an external label to the <code>aria-labelledby</code> attribute of the <strong>EuiCommentList</strong>. A <code>@timelineAvatarAriaLabel</code> should be provided for every <strong>EuiComment</strong> with or without a <code>@timelineIcon</code> icon type.</p>
</EuiCallOut>
<EuiSpacer />

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCommentList

Stacks EuiComments along a shared timeline (an ordered list).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@gutterSize` | `'m' \| 'l' \| 'xl'` | `'l'` | Vertical space between comments: `'m'`, `'l'` or `'xl'`. |
| `@comments` | `EuiCommentListItem[]` |  | Comments to render from data (see `EuiCommentListItem`), before the block's content. Give the list an `aria-label` or `aria-labelledby` attribute. |

| Block | Description |
| --- | --- |
| default block | The `EuiComment`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ol>`.

### EuiComment

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@hasBody` (required) | `boolean` |  |  |
| `@hasEventElements` (required) | `unknown` |  | Truthy when the header has more than a username (upstream). |
| `@hasTimelineIcon` (required) | `boolean` |  |  |
| `@hasUsername` (required) | `boolean` |  |  |
| `@hasEvent` (required) | `boolean` |  |  |
| `@hasTimestamp` (required) | `boolean` |  |  |
| `@hasActions` (required) | `boolean` |  |  |

Also takes the args of `EuiComment`.

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>`.

</EuiText>
<!-- api:end -->
