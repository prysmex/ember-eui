---
order: 2
---

# ColorModes

<EuiText>

`EuiSelectableTemplateSitewide` by default has the color mode of the nearest provider applied. If you want to override this manually, you can pass `@colorModes` to the component. This allows you to apply different color modes to the search and popover components: `light`, `dark`, `inverse` (the opposite of the nearest provider's), `default` (the nearest provider's) and, for the popover, `global` (the outermost provider's).

```hbs
<EuiSelectableTemplateSitewide @colorModes={{hash search="default" popover="inverse"}} />
```

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

  colorModes = { search: 'default', popover: 'inverse' };

  <template>
    <EuiSelectableTemplateSitewide @options={{this.options}} @colorModes={{this.colorModes}} />
  </template>
}
```
