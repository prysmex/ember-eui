---
title: Page template guidelines
order: 2
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Page template guidelines"/>
<EuiSpacer @size="l" />

<EuiText>

These guidelines follow upstream EUI's page template guidelines. They
cover building pages with the composable
[`EuiPageTemplate`](/docs/core/docs/templates/page-template) API, centering
content, and empty, loading and error states. Upstream illustrates each
rule with screenshots of Kibana; here the do's and don'ts are described.

## When to center content

Whether or not the page has side navigation, any empty/loading/error
states that take up the whole page should be vertically and horizontally
centered using `@alignment="center"` on the individual page section.

**Most empty states can use the template's `T.EmptyPrompt`, which
automatically centers the content for you.**

- **Do** use fully centered alignment for empty states, even when using
  tabs.
- **Don't** center the content only horizontally: it mismatches the basic
  template.
- **Do** use the empty prompt component for fully empty pages and hide the
  page header.
- **Don't** duplicate content between the page header and the empty
  state: it isn't helpful.

## Empty pages

### When the whole page is empty

Use `T.EmptyPrompt` to replace the whole page.

- **Do** use the empty state component, which automatically adds panelling
  and centering.
- **Don't** just replace the page content with a simple sentence: it
  creates an incorrect hierarchy.
- **Do** use the empty state component with a specific call to action.
- **Don't** show ambiguous empty state messages without any actions: they
  are not helpful.

### Empty state due to insufficient permissions

Provide language that specifically points to permissions as the reason
for the empty state. If possible, link to an admin contact.

- **Do** provide more explanation within the empty state.
- **Don't** show ambiguous empty states without any actions: they can feel
  like an error.

### Empty page content that still needs the page header

If necessary, `T.EmptyPrompt` can still be used alongside `T.Header`.
Remove any UI that can't be used due to the emptiness.

- **Do** hide unusable elements and use the empty state with one or more
  specific calls to action.
- **Don't** show empty tables with filters that won't find any results, or
  duplicate actions.
- **Do** use only the empty prompt, with explanations and a call to action.
- **Don't** add a page header when the same labelling is used throughout
  other parts of the page.

## Error and loading states

### When loading the content

If, after loading, the entire page renders as an empty or error state, the
loading state should also be an entire page.

- **Do** use the empty prompt as a loading state, followed by an empty
  prompt styled as an error/empty state (or the loaded content). See
  [the loading, error and empty states example](/docs/core/docs/display/empty-prompt).
- **Don't** temporarily show content like the page header while loading,
  then remove those elements on error: it is jarring.

### Callouts versus empty prompts

Typically there should only be one `T.EmptyPrompt` when the whole page is
empty or an error. They should never be used to stack multiple errors on
the same page.

- **Do** use [`EuiCallOut`](/docs/core/docs/display/callout) components for
  stacking error messages alongside content.
- **Don't** stack multiple large empty prompts: they push the main content
  out of view and, without actions, harm the user experience.

### Tabbed content

Treat the page contents under tabs as "full page" content, using empty
prompts for empty/loading/error states if it is the only content that is
rendered as the tab content. However, the context of the state should
dictate whether an empty prompt or a simple callout is appropriate.

- **Do** use a centered empty prompt if the error blocks all interactions
  of the tabbed content.
- **Do** use a simple callout if the error is not detrimental or doesn't
  block much user interaction (an empty prompt may also fit).

</EuiText>
