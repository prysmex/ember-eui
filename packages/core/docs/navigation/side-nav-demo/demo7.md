---
order: 7
---

# Icon components and custom item rendering

<EuiText>

An item's `icon` is an icon name, or a component rendered as is, like an **EuiIcon** with its own color. Set `renderItem` on an item (or `@renderItem` on **EuiSideNav** for every item) to replace its link or button, for example with your router's link component. It is a component receiving `@href`, `@target`, `@rel`, `@onClick`, `@disabled` and the item's `class`, and yields the item's content in its block.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiIcon, EuiSideNav, EuiSpacer } from '@ember-eui/core/components';

const KibanaIcon = <template><EuiIcon @type="logoKibana" /></template>;
const ClockIcon = <template><EuiIcon @type="clock" @color="success" /></template>;

const RouterLink = <template>
  <a href={{@href}} target={{@target}} rel={{@rel}} data-router-link ...attributes>
    {{yield}}
  </a>
</template>;

const items = [
  {
    id: 'kibana',
    name: 'Kibana',
    icon: KibanaIcon,
    href: '#kibana',
    items: [
      { id: 'discover', name: 'Discover', href: '#discover', icon: ClockIcon },
      { id: 'dashboards', name: 'Dashboards', href: '#dashboards' }
    ]
  }
];

<template>
  <EuiSideNav
    aria-label="Custom side nav example"
    @renderItem={{RouterLink}}
    @items={{items}}
    style="width: 192px"
  />
</template>
```
