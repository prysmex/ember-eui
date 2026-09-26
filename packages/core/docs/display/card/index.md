---
title: Card
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Card"/>
<EuiSpacer/>
<EuiText>
  <p>
  <strong>EuiCard</strong>  is a content-oriented component built on top of EuiPanel. Be sure to check out the guidelines for properly nesting panels.
   </p>
</EuiText>

<EuiHorizontalRule/>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCard

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@footer` | `string` |  | Footer text (vertical layout only). Use the `<:footer>` block for markup. |
| `@selectable` | `EuiCardSelectProps` |  | Adds a "Select" toggle button to the bottom of the card, making the card selectable: `{ onClick, isSelected, isDisabled, color, … }` (see `EuiCardSelectProps`). Clicking anywhere on the card clicks it. |
| `@topClassName` | `string` |  | Class that will apply to the card top section. |
| `@contentClassName` | `string` |  | Class that will apply to the card content section. |
| `@footerClassName` | `string` |  | Class that will apply to the card footer section. |
| `@target` | `string` |  | `target` of the `@href` link, e.g. `'_blank'`. |
| `@betaBadgeProps` |  |  | Shows an `EuiBetaBadge` on the card's top edge: `{ label: 'Beta', title?, tooltipContent? }`. |
| `@description` | `string` |  | Text under the title. Use the `<:description>` block for markup. |
| `@title` | `string` |  | The title of the card. |
| `@titleSize` |  | `'s'` | Size of the title, any `EuiTitle` size. |
| `@titleElement` | `string` | `'span'` | Tag wrapping the title, e.g. `'h3'` to include it in the page outline. |
| `@href` | `string` |  | Makes the title a link; clicking anywhere on the card follows it. |
| `@onClick` | `(e: MouseEvent) => void` |  | Makes the title a button; clicking anywhere on the card calls it. |
| `@isDisabled` | `boolean` |  | Disables the card's link or button and greys it out. |
| `@textAlign` | `'left' \| 'center' \| 'right'` | `'center'` | `'left'`, `'center'` or `'right'`. |
| `@image` | `string` |  | URL of an image across the top of the card (vertical layout only). |
| `@icon` | `string` |  | Icon above the title; anything `EuiIcon`'s `@type` accepts. |
| `@layout` | `'horizontal' \| 'vertical'` | `'vertical'` | `'vertical'` stacks icon, title, description and footer. `'horizontal'` puts the icon next to the text and hides the image and footer. |
| `@display` |  | a plain panel with a shadow | Background of the card, any `EuiPanel` color (`'plain'`, `'subdued'`, `'transparent'`, `'primary'`, …); also adds a border. |
| `@paddingSize` |  |  | Padding inside the card, any `EuiPanel` padding size. |
| `@iconSize` |  |  | Size of `@icon`. |

| Block | Description |
| --- | --- |
| `<:icon>` | Custom content above the title instead of `@icon` / `@image`; yields the class to put on it. |
| `<:title>` | Custom title. Yields a function to register your link or button element (e.g. with `did-insert`) so clicks on the card trigger it. |
| `<:description>` | Custom description, instead of `@description`. |
| `<:body>` | Extra content after the description. |
| `<:footer>` | Custom footer, instead of `@footer` (vertical layout only). |

### EuiCheckableCard

Attributes and modifiers (`name`, `value`, `{{on "change" …}}`) go to the
radio or checkbox input.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the input, linked to the label. |
| `@label` | `string` |  | The card's label. Use the `<:label>` block for markup. |
| `@checked` | `boolean` |  | Whether the card's radio or checkbox is checked. |
| `@disabled` | `boolean` |  | Disables the input and greys the card out. |
| `@checkableType` | `'checkbox' \| 'radio'` | `'radio'` | `'radio'` for picking one card of a group (give them the same `name`), `'checkbox'` for independent cards. |

| Block | Description |
| --- | --- |
| `<:label>` | The label, instead of `@label`. |
| `<:content>` | Details below the label, linked to the input with `aria-describedby`. |

</EuiText>
<!-- api:end -->
