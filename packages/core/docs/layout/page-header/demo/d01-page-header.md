---
order: 1
---

# Page header

<EuiText>

While the `EuiPageHeader` component can be placed anywhere within your page layout, we recommend using it within the `EuiPageTemplate` component by passing the configuration args as its `@pageHeader`.

`EuiPageHeader` provides args for opinionated, consistent formatting of your header. Any combination of `@pageTitle`, `@description`, `@tabs`, or any default block will adjust the layout as needed.

The `<:rightSideItems>` block lays out a list of items in a flexbox row. This is commonly used for adding multiple buttons, of which, at least one should be primary (adding `@fill={{true}}`). Wrap each in the yielded `Item`. These items are also displayed in **reverse order** so that the first and primary item will be displayed on the far right.

You can further adjust the display of these content types with an optional `@iconType` placed to the left of the title, `@alignItems` for adjusting the vertical alignment of the two sides, and `@responsive` (`'reverse'`) to determine which content side to display first on smaller screens.

</EuiText>

```gjs component
import { EuiPageHeader, EuiButton } from '@ember-eui/core/components';

<template>
  <EuiPageHeader
    @pageTitle="Page title"
    @iconType="logoKibana"
    @description="This description should be describing the current page as depicted by the page title. It will never extend beneath the right side content."
  >
    <:rightSideItems as |Item|>
      <Item>
        <EuiButton @fill={{true}}>Add something</EuiButton>
      </Item>
      <Item>
        <EuiButton>Do something</EuiButton>
      </Item>
    </:rightSideItems>
  </EuiPageHeader>
</template>
```
