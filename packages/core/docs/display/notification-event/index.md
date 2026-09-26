---
title: Notification Event
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Notification Event"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiNotificationEvent` is one entry of a notifications list (usually in
a flyout opened from the header): its source, severity, time, title,
messages, read state and actions.

```hbs
<EuiNotificationEvent
  @id="report-ready"
  @type="Report"
  @iconType="reportingApp"
  @time="1 min ago"
  @title="Monthly report is ready"
  @messages={{array "Download it from the reports page."}}
  @isRead={{this.isRead}}
  @onRead={{this.toggleRead}}
/>
```

Pass `@isRead` (a boolean) to show the read indicator and `@onRead` to
let users toggle it; `@onClickTitle` or `@href` make the title
clickable, and the `<:contextMenu>` block holds more actions.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiNotificationEvent

One notification in a list (e.g. a flyout from the header): title,
source, time, messages, read state and actions.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` |  | Id of the event, for its read button/icon. |
| `@tagName` | `string` | `'article'` | Tag of the event. |
| `@isRead` | `boolean` |  | Read state. When a boolean, shows a read indicator (a button with `@onRead`, otherwise an icon); leave it undefined to show none. |
| `@href` | `string` |  | Makes the title a link. |
| `@onClickTitle` | `(event: MouseEvent) => void` |  | Makes the title a button calling this function. |
| `@onRead` | `(event: MouseEvent) => void` |  | Called by the read button; toggle `@isRead` here. |
| `@onOpenContextMenu` | `(event: MouseEvent) => void` |  | Called when the context menu button is clicked. |
| `@title` | `string` |  | The event's title. |
| `@type` | `string` |  | Kind of event shown in a badge, e.g. "Alert" or "Report". |
| `@severity` | `string` |  | Severity appended to the badge, e.g. "Critical" ("Alert: Critical"). |
| `@badgeColor` |  |  | Color of the type badge, any `EuiBadge` color. |
| `@iconType` |  |  | Icon before the badge, e.g. the app it comes from. |
| `@iconAriaLabel` | `string` |  | Accessible label of `@iconType`; without it the icon is decorative. |
| `@time` | `string` |  | When it happened, e.g. "2 min ago". |
| `@iconColor` | `string` |  | Color of `@iconType`. |
| `@readIconColor` | `string` | `'primary'` | Color of the read indicator. |
| `@headingLevel` |  | `'h2'` | Heading tag of the title. |
| `@messages` (required) |  |  | The event's messages: the first is shown, the rest behind a "show more" accordion. |
| `@accordionButtonText` |  |  | Text of the button revealing the other messages, e.g. "+ 2 more". |
| `@accordionHideText` |  |  | Text shown next to it while closed, e.g. "Show". |

| Block | Description |
| --- | --- |
| `<:contextMenu>` | Context menu content, e.g. an `EuiContextMenuPanel` of actions. |
| `<:primaryAction>` | A primary action below the messages, e.g. a "View" button. |

</EuiText>
<!-- api:end -->
