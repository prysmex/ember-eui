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
| `@timelineIcon` |  | `'user'` | Icon of the timeline avatar (upstream `timelineAvatar` as a string). Use the `<:timelineIcon>` block for custom content such as `<EuiAvatar @name="Jane" />`. |
| `@timelineAvatarAriaLabel` | `string` |  | Accessible name of the default timeline avatar. |
| `@eventColor` | `EuiCommentEventColor` | `'highlighted'` for regular comments and `'transparent'` for updates | Background of the header panel: `'highlighted'`, `'subdued'`, `'transparent'`, `'plain'`, `'accent'`, `'primary'`, `'success'`, `'warning'` or `'danger'`. Regular comments also get a border of this color (`'subdued'` for highlighted). |
| `@eventIcon` |  |  | Icon in a small avatar before the username, e.g. `'pencil'`. |
| `@eventIconAriaLabel` | `string` |  | Accessible name of `@eventIcon`; without it the icon is decorative. |
| `@verticalAlign` | `'top' \| 'center'` | `'top'` with a `<:body>`, else `'center'` | Vertical alignment of the avatar with the event: `'top'` or `'center'`. |

Deprecated: `@type` (Has no effect: like upstream, the type follows the blocks. A comment with a `<:body>` and header content is `regular` (a bordered `<figure>`), one without a body is a compact `update`, and one with only a body is `custom` (no header).).

| Block | Description |
| --- | --- |
| `<:timelineIcon>` | Custom timeline content, e.g. `<EuiAvatar @name="Jane" />`. |
| `<:username>` | Who wrote it. |
| `<:event>` | What happened, e.g. "added a comment" or "closed the issue". |
| `<:timestamp>` | When, e.g. "on Jan 1st, 2024"; wrapped in `<time>`. |
| `<:actions>` | Actions at the end of the header, e.g. an `EuiButtonIcon`. |
| `<:body>` | The comment's content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>`.

</EuiText>
<!-- api:end -->
