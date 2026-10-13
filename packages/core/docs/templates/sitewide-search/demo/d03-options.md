---
order: 3
---

# Options

<EuiText>

The `@options` are the most opinionated portion of the template. Their display is determined by the keys passed in and extends the normal `EuiSelectable` option. All parts are optional with the exception of the label (A). The example option below uses all of them: the icon, the avatar, and three meta items.

- `label` (required): The name of the item itself. By default, the search box will only use this to match the search term against, but you can supply a separate `searchableLabel` that combines the label and meta data to search on.
- `icon`: Only display the solution or application's logo when the option links to the application itself (Dashboard app) and not lower-level items such as individual dashboards. Size and color are predetermined but can be overridden.
- `avatar`: Represents the Kibana Space that the item is located in, **if** multiple spaces are present. Type and size are predetermined but can be overridden.
- `meta`: This bottom line should only contain items if the option is a lower-level item (individual dashboard). The display of which defaults to simple text, but if you pass one of the predetermined `type`s (`application`, `deployment`, `article`, `case`, `platform`), they will be styled according to the design pattern.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiSelectableTemplateSitewide } from '@ember-eui/core/components';
import Component from '@glimmer/component';

export default class SitewideOptionsDemo extends Component {
  options = [
    {
      label: 'Label',
      icon: { type: 'logoKibana' },
      avatar: { name: 'Default' },
      meta: [
        { text: 'Meta', type: 'application' },
        { text: 'Deployment', type: 'deployment' },
        { text: 'Default display' },
      ],
    },
  ];

  <template>
    <EuiSelectableTemplateSitewide @options={{this.options}} @placeholder="Type e.g. “Label” to see the option" />
  </template>
}
```
