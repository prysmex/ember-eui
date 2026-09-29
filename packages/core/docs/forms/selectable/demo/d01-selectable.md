---
order: 1
---

# Pick several, with search

<EuiText>

Click options (or use the arrow keys and Enter from the search) to check
and uncheck them. Group labels and disabled options cannot be picked.

</EuiText>

```hbs template
<EuiPanel @paddingSize="none" style="max-width: 320px;">
  <EuiSelectable
    @options={{this.options}}
    @onChange={{this.setOptions}}
    @searchable={{true}}
    @listProps={{hash bordered=true}}
    aria-label="Planets"
  />
</EuiPanel>
<EuiSpacer />
<EuiText @size="s"><p>Selected: {{this.selected}}</p></EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SelectableDemo extends Component {
  @tracked options = [
    { label: 'Inner planets', isGroupLabel: true },
    { label: 'Mercury' },
    { label: 'Venus', checked: 'on' },
    { label: 'Earth', checked: 'on' },
    { label: 'Mars' },
    { label: 'Outer planets', isGroupLabel: true },
    { label: 'Jupiter', append: '95 moons' },
    { label: 'Saturn', append: '146 moons' },
    { label: 'Uranus' },
    { label: 'Neptune' },
    { label: 'Pluto', disabled: true, append: 'not anymore' },
  ];

  get selected() {
    return (
      this.options
        .filter((option) => option.checked === 'on')
        .map((option) => option.label)
        .join(', ') || 'none'
    );
  }

  @action
  setOptions(options) {
    this.options = options;
  }
}
```
