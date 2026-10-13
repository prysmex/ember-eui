---
order: 1
---

# Component

<EuiText>

Pass an illustration asset to the `@type` argument. The component picks the correct color-mode variant automatically, so try toggling the theme in the top toolbar. The assets below are sample artwork; in your app they come from `@elastic/eui-illustrations`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiIllustration } from '@ember-eui/core/components';

const art = (sky, hill, sun) =>
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 100" width="160" height="100">` +
  `<rect width="160" height="100" rx="8" fill="${sky}"/>` +
  `<circle cx="120" cy="30" r="14" fill="${sun}"/>` +
  `<path d="M0 80 Q40 45 80 75 T160 70 V100 H0Z" fill="${hill}"/></svg>`;

export default class IllustrationComponentDemo extends Component {
  asset = {
    id: 'hills',
    title: 'Rolling hills under the sun',
    light: art('#E8F1FF', '#8EC5A8', '#F6C744'),
    dark: art('#1D2A3E', '#2F6B57', '#C9A227')
  };

  <template>
    <div style="max-width: 360px">
      <EuiIllustration @type={{this.asset}} />
    </div>
  </template>
}
```

