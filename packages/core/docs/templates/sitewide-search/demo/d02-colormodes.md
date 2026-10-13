---
order: 2
---

# ColorModes

<EuiText>

Upstream's `colorModes` prop (`{ search: 'default', popover: 'inverse' }`) applies a different color mode to the search and the popover than the nearest theme provider. Ember EUI's `EuiSelectableTemplateSitewide` has no `@colorModes` arg: it follows the color mode of the nearest provider. This is recorded as a gap.

</EuiText>

```gjs component
import { EuiSelectableTemplateSitewide } from '@ember-eui/core/components';
import Component from '@glimmer/component';

export default class SitewideColorModesDemo extends Component {
  options = [
    {
      label: 'Welcome dashboards',
      meta: [{ text: 'Dashboard', type: 'application', highlightSearchString: true }],
      url: 'welcome-dashboards',
    },
  ];

  <template>
    <EuiSelectableTemplateSitewide @options={{this.options}} />
  </template>
}
```
