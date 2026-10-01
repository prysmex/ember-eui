---
order: 3
---

# Colors

<EuiText>

Without `@color` an icon inherits the text color (`currentColor`). `@color`
takes one of EUI's color names (`primary`, `success`, `accent`, `warning`,
`danger`, `text`, `subdued`, `ghost`, `default`, `inherit`) or any CSS color
such as `"#DA8B45"` or `"rgb(0 119 204)"`.

Multi-color icons (logos and apps) keep their colors unless you pass a color:
`ghost` and `text` turn them into a single color, e.g. for dark backgrounds.
For your own svgs to take a color, remove their `fill` attributes.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l" @wrap={{true}}>
  {{#each this.colors as |color|}}
    <EuiFlexItem @grow={{false}}>
      <EuiFlexGroup @direction="column" @alignItems="center" @gutterSize="s" @responsive={{false}}>
        <EuiFlexItem @grow={{false}}>
          <EuiIcon @type="brush" @size="l" @color={{color}} />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiText @size="xs">{{color}}</EuiText>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>

<EuiSpacer />

<EuiPanel @color="subdued" @paddingSize="m">
  <EuiFlexGroup @gutterSize="l" @alignItems="center" @responsive={{false}}>
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="logoKibana" @size="xl" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="logoKibana" @size="xl" @color="text" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}} style="background: #25282f; padding: 8px; border-radius: 4px;">
      <EuiIcon @type="logoKibana" @size="xl" @color="ghost" />
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size="s">
        <p>A multi-color logo as is, with <code>@color="text"</code> and with <code>@color="ghost"</code>.</p>
      </EuiText>
    </EuiFlexItem>
  </EuiFlexGroup>
</EuiPanel>
```

```js component
import Component from '@glimmer/component';

export default class IconColorsDemo extends Component {
  colors = [
    'default',
    'primary',
    'success',
    'accent',
    'warning',
    'danger',
    'text',
    'subdued',
    '#DA8B45',
    'rgb(0 119 204)',
  ];
}
```
