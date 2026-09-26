---
order: 7
---

# Registering icons by name

<EuiText>

To use your icons by name, like EUI's own (`<EuiIcon @type="rocket" />`,
`<EuiButton @iconType="rocket">`), register them in the `euiIcon.icons`
config. `iconsFromGlob` registers a whole folder: each file becomes an icon
named after the file, like ember-svg-jar did (`icons/brands/acme.svg` →
`acme`). Pass `prefix` to namespace them or `name` for custom names.

```js
// app/routes/application.js
import Route from '@ember/routing/route';
import { service } from '@ember/service';
import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';
import Rocket from '../icons/rocket.svg';

export default class ApplicationRoute extends Route {
  @service euiConfig;

  beforeModel() {
    this.euiConfig.updateConfig({
      'euiIcon.icons': {
        // every svg in app/icons (the glob must be eager)
        ...iconsFromGlob(import.meta.glob('../icons/**/*.svg', { eager: true })),
        // or one by one
        launch: Rocket,
      },
    });
  }
}
```

Keep these svgs out of `public/`: files there are served as they are and not
turned into components. Registered names win over image URLs, so moving
`public/assets/icons/*.svg` into `app/icons/` keeps the names your templates
already use.

This site registers `app/icons/*.svg` with `prefix: 'site-'`:

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="site-rocket" @size="l" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="site-ember" @size="l" @color="danger" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="site-leaf" @size="l" @color="success" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @iconType="site-rocket" @size="s">Launch</EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
```
