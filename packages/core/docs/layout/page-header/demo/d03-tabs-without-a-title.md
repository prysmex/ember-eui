---
order: 3
---

# Tabs without a title

<EuiText>

When supplying `@tabs` without a `@pageTitle`, `EuiPageHeader` will promote those tabs as if they are the page title. This means that any `@description` or default block will sit **below** the tabs and should used to describe the currently selected tab.

</EuiText>

```gjs component
import { EuiPageHeader } from '@ember-eui/core/components';
import { array, hash } from '@ember/helper';

<template>
  <EuiPageHeader
    @tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
    @description="This description should be describing the current page as depicted by the current tab. It has grow set to false to ensure a readable line-length."
  />
</template>
```
