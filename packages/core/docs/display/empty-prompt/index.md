---
title: Empty Prompt
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Empty prompt"/>
<EuiSpacer/>
<EuiText>

The **EuiEmptyPrompt** is the building block to create an empty state. You can use it as a placeholder for any type of empty content. They are especially helpful for replacing entire pages or parts of a product that contain no content.

## Guidelines

### Anatomy

A useful empty state will let the user know what's happening, why it's happening, and what to do about it. It can contribute to a more compelling user experience and add more value to the business if done right.

To make the empty state clear, follow this pattern:

1. **Icon or illustration (optional):** A meaningful representation of the the solution or context.
2. **Title:** Answers the question "What's happening?". Is it an error? Is it loading?
3. **Description:** Why is it happening? Explain why the space is empty and guide the users through the required actions.
4. **Action(s):** Your call to actions should answer the question "What will solve the issue?". Lead the users to take action or guide them about the next steps.
5. **Footer (optional):** Use this section to reference documentation or link to an area where users can learn more about the issue they are facing.

### Vertical vs. horizontal

The vertical layout is perfect when the content is small, a title and two paragraphs at most. You can use this layout with an icon, an illustration, or no icons at all.

Use the horizontal layout when you have a long description, multiple calls to action, and a footer. For this type of layout, an illustration is required.

### Icons and illustrations

Icons and illustrations must first and foremost communicate meaning. They are also an opportunity to delight users and show our Elastic brand.

When using an illustration, bear in mind that they stand out a lot. Use one illustration per page. Having multiple illustrations might make the page too crowded. An illustration works better in a horizontal layout. Avoid using icons and illustrations that don't mean anything and are not related to the content.

### Learn more links

"Learn more" links are optional. You can use them in your empty prompt to link to documentation where users can get more detailed help.

Include the link after the description when the empty prompt doesn't contain a call to action. If there is a call to action, include the link in the footer.

### Multiple empty states

When a page has multiple empty states, avoid using multiple primary actions and multiple icons or illustrations.

Use secondary actions and no icons or illustrations. This way, the visual noise will be reduced. Consider using an illustration or a primary action if you want to make one of the empty states stand out. Avoid mixing different types of empty states. Be consistent.

### Less content, more actions

Simplify the prompt by removing unneeded parts. Multiple actions can be provided as an array but list primary actions first and secondary actions as empty buttons.

</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiEmptyPrompt

A message filling an empty page or section: an icon, a title, some text
and actions, e.g. when a list has no items yet or a page failed to load.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@layout` | `Layout` | `'vertical'` | `'vertical'` centers everything in a column; `'horizontal'` puts the icon beside the text on large screens (it stacks below the `l` breakpoint). |
| `@paddingSize` | `PaddingSize` | `'l'` | Padding around the content: `'none'`, `'s'`, `'m'` or `'l'`. |
| `@color` |  | `'transparent'` | Background, any `EuiPanel` color (`'plain'`, `'subdued'`, `'danger'`, …). |
| `@hasBorder` | `boolean` | `true` for `'plain'`, `false` otherwise | Adds a border around the prompt. |
| `@iconType` |  |  | Large icon above the title, e.g. `'magnify'` or `'logoKibana'`. |
| `@iconColor` |  | `@color` when it is a named icon color (e.g | Color of the icon. `'danger'`), or `'subdued'`. |
| `@title` | `string` |  | Title, e.g. "No dashboards yet". |
| `@titleSize` |  | `'m'` | Size of the title, any `EuiTitle` size. |
| `@body` | `string` |  | Text explaining the situation and what to do. |
| `@actions` | `ComponentLike[]` |  | Components rendered as the prompt's actions (e.g. a primary `EuiButton` and an `EuiButtonEmpty`), laid out in a column (vertical) or row (horizontal). Use the `<:content>` block for full control. |
| `@footer` | `string` |  | Text in a footer, e.g. a link to the docs. Use the `<:footer>` block for markup. |

| Block | Description |
| --- | --- |
| `<:icon>` | Custom content instead of the `@iconType` icon, e.g. an `EuiImage`. |
| `<:content>` | Replaces the title, body and actions with your own content. |
| `<:footer>` | The footer, instead of `@footer`. |

</EuiText>
<!-- api:end -->
