---
title: Comment List
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Comment List"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCommentList` shows a timeline of `EuiComment`s, like the activity of
an issue: comments with a body, and one-line updates ("closed the
issue").

```hbs
<EuiCommentList>
  <EuiComment>
    <:timelineIcon><EuiAvatar @name="Jane Cooper" /></:timelineIcon>
    <:username>jane</:username>
    <:event>added a comment</:event>
    <:timestamp>2 hours ago</:timestamp>
    <:body><EuiText><p>Looks good to me!</p></EuiText></:body>
  </EuiComment>
  <EuiComment @type="update" @timelineIcon="lock">
    <:username>raj</:username>
    <:event>locked the conversation</:event>
  </EuiComment>
</EuiCommentList>
```

</EuiText>

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
