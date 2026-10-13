---
order: 1
---

# Converting from legacy layouts

<EuiText>

Try to use the template's parts (e.g. `<T.Header />`) as much as possible. This ensures the template's settings are propagated and alignment is kept through the stacking order. Use the plain components (e.g. `<EuiPageSection>`) if you deliberately don't want the settings to apply.

For Ember EUI's deprecated `@template` API, move `@pageHeader` to a `T.Header`, the `<:pageSideBar>` block to a `T.Sidebar` in the `<:sidebar>` block, the `<:default>` content into `T.Section`s, the `<:bottomBar>` block to a `T.BottomBar`, and a `centeredContent` empty prompt to a `T.EmptyPrompt`.

- **Do** use `EuiPageTemplate` with its `T.Header` and `T.Section` parts.
- **Don't** wrap entire page layouts in plain `EuiPage` components: it is very manual and no longer matches the template.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiPageSection, EuiSkeletonText } from '@ember-eui/core/components';
import { htmlSafe } from '@ember/template';

const HEIGHT = htmlSafe('height: 430px');

<template>
  <EuiPageTemplate
    @bottomBorder="extended"
    @minHeight="0"
    @offset={{0}}
    style={{HEIGHT}}
  >
    <:sidebar as |T|>
      {{! Sidebars always render beside the main content }}
      <T.Sidebar>
        <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
      </T.Sidebar>
    </:sidebar>
    <:default as |T|>
      {{! This plain section is not tied to the template, so its display is always custom }}
      <EuiPageSection @color="subdued">
        Some content before the page header
      </EuiPageSection>
      {{! Display a page header anywhere in the stack of contents }}
      <T.Header @pageTitle="Page title" />
      {{! This template section overrides some default template settings }}
      <T.Section @grow={{false}} @bottomBorder="extended">
        Some content after the page header
      </T.Section>
      {{! Empty prompts can be placed anywhere in the stack and not replace the entire page contents }}
      <T.EmptyPrompt>
        <EuiSkeletonText @isLoading={{true}} @lines={{3}} />
      </T.EmptyPrompt>
    </:default>
  </EuiPageTemplate>
</template>
```
