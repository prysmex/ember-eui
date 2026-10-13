---
order: 3
---

# Files and folders (Ember EUI extension)

<EuiText>

Folders open and close; the icon changes while open. Clicking a file
calls its `callback`, which here shows its name below.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiSpacer, EuiText, EuiTreeView } from '@ember-eui/core/components';

export default class TreeViewDemo extends Component {
  @tracked selected = 'nothing';

  get items() {
    const file = (id, label) => ({
      id,
      label,
      icon: 'document',
      callback: () => (this.selected = label),
    });

    return [
      {
        id: 'app',
        label: 'app',
        icon: 'folderClosed',
        iconWhenExpanded: 'folderOpen',
        isExpanded: true,
        children: [
          file('app-js', 'app.js'),
          file('router-js', 'router.js'),
          {
            id: 'components',
            label: 'components',
            icon: 'folderClosed',
            iconWhenExpanded: 'folderOpen',
            children: [file('nav-gjs', 'nav.gjs'), file('footer-gjs', 'footer.gjs')],
          },
        ],
      },
      {
        id: 'tests',
        label: 'tests',
        icon: 'folderClosed',
        iconWhenExpanded: 'folderOpen',
        children: [file('test-helper', 'test-helper.js')],
      },
      file('package-json', 'package.json'),
    ];
  }

  <template>
    <div style="width: 280px;">
      <EuiTreeView @items={{this.items}} aria-label="Project files" />
    </div>
    <EuiSpacer />
    <EuiText @size="s"><p>Selected: {{this.selected}}</p></EuiText>
  </template>
}
```

