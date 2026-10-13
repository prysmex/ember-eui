---
order: 2
---

# Light and dark artwork (Ember EUI extension)

<EuiText>

The same asset in a light and a dark provider, at its intrinsic width
(`@fullWidth={{false}}`) and filling a 240px column.

</EuiText>

```hbs template
<EuiFlexGroup @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiEmotionProvider @colorMode="light">
      <EuiPanel>
        <EuiIllustration @type={{this.asset}} @fullWidth={{false}} />
      </EuiPanel>
    </EuiEmotionProvider>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiEmotionProvider @colorMode="dark">
      <EuiPanel>
        <EuiIllustration @type={{this.asset}} @fullWidth={{false}} />
      </EuiPanel>
    </EuiEmotionProvider>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <div style="width: 240px">
      <EuiIllustration @type={{this.asset}} @alt="" />
    </div>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

const art = (sky, hill, sun) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 100" width="160" height="100">` +
  `<rect width="160" height="100" rx="8" fill="${sky}"/>` +
  `<circle cx="120" cy="30" r="14" fill="${sun}"/>` +
  `<path d="M0 80 Q40 45 80 75 T160 70 V100 H0Z" fill="${hill}"/></svg>`;

export default class IllustrationDemo extends Component {
  asset = {
    id: 'hills',
    title: 'Rolling hills under the sun',
    light: art('#E8F1FF', '#8EC5A8', '#F6C744'),
    dark: art('#1D2A3E', '#2F6B57', '#C9A227')
  };
}
```
