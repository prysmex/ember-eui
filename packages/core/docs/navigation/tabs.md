---
title: Tabs
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Tabs"/>
<EuiSpacer @size="l" />

<EuiText>

Tabs switch between views of the same context.

- **`EuiTabs`** renders a row of `EuiTab`s; you keep which one is
  selected (`@isSelected`) and render its content yourself. Use this for
  tabs that are routes (`@href`) or when you lay out the content.
- **`EuiTabbedContent`** takes `@tabs` (`{ id, name, content }`) and
  shows the selected tab's content for you.

```hbs
<EuiTabs>
  {{#each this.tabs as |tab|}}
    <EuiTab @isSelected={{eq tab.id this.selected}} {{on "click" (fn this.select tab.id)}}>
      {{tab.name}}
    </EuiTab>
  {{/each}}
</EuiTabs>
```

Tabs get `role="tab"`; use a short noun for each label.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTabs

A row of `EuiTab`s; you track the selected one. See also EuiTabbedContent.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@display` |  | `'default'` | `'default'`, or `'condensed'` (tighter, no bottom border). |
| `@size` |  | `'m'` | `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@expand` | `boolean` | `false` | Evenly stretches the tabs to fill the width. |
| `@bottomBorder` | `boolean` | `true` (not for `'condensed'`) | Border under the tabs. |
| `@className` | `string` |  | Extra class(es). |

| Block | Description |
| --- | --- |
| default block | The `EuiTab`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTab

One tab of an EuiTabs. Add `{{on "click" …}}` to select it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the tab. |
| `@href` | `string` |  | Makes the tab a link, e.g. to a route. |
| `@isSelected` | `boolean` |  | Marks the tab as selected (`aria-selected`). |
| `@disabled` | `boolean` |  | Disables the tab. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the label, e.g. an icon. |
| default block | The tab's label. |
| `<:append>` | Content after the label, e.g. a notification badge. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>` / `<a>`.

### EuiTabbedContent

Tabs with their panels, managing the selected tab for you. For custom layouts use EuiTabs.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@autoFocus` | `'initial' \| 'selected'` |  | When tabbing into the tabs, set the focus on `initial` for the first tab, or `selected` for the currently selected tab. Best use case is for inside of overlay content like popovers or flyouts. |
| `@display` |  |  | Choose `default` or alternative `condensed` display styles |
| `@expand` | `boolean` |  | Evenly stretches each tab to fill the horizontal space |
| `@initialSelectedTab` | `EuiTabbedContentTab` |  | Use this prop to set the initially selected tab while letting the tabbed content component control selection state internally |
| `@onTabClick` | `(selectedTab: EuiTabbedContentTab) => void` |  | Called with the clicked tab. |
| `@selectedTab` | `EuiTabbedContentTab` |  | Use this prop if you want to control selection state within the owner component |
| `@size` |  | `'m'` | Size of the tabs: `'s'`, `'m'`, `'l'` or `'xl'`. |
| `@tabs` (required) | `EuiTabbedContentTab[]` |  | Each tab needs id and content properties, so we can associate it with its panel for accessibility. The name property (a node) is also required to display to the user. |

| Block | Description |
| --- | --- |
| `<:selectedTabContent>` | Renders the selected tab's panel (instead of its `content`); yields the tab: `<:selectedTabContent as \|tab\|>{{#if (eq tab.id "a")}}…`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
