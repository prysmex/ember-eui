---
'@ember-eui/core': patch
---

`EuiTabbedContent`: a tab's `content` can be any value when the `<:selectedTabContent>` block renders it, e.g. a translation key. `EuiTabbedContent` is generic over the type of its `@tabs`' items, so `@tabs`, `@initialSelectedTab`, `@selectedTab` and `@onTabClick` take your own tab type and the blocks yield it: with `content: 'settings.general'` in every tab, the block's `tab.content` is a `string`. `EuiTabbedContentTab<Content>` types such a tab (`Content` defaults to a component, as before). Without the block, `content` is still a component rendered as the panel.
