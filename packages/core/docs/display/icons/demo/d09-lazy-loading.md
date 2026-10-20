---
order: 9
---

# Lazy loading

<EuiText>

Each EUI icon is a separate chunk that is downloaded the first time it
renders; after that it renders immediately everywhere. Until it arrives an
empty icon with the same size and classes keeps its place, so nothing jumps.

Preload icons that should be there from the first paint, e.g. the ones in
your header or navigation:

```js
// app/routes/application.js
import { preloadIcons } from '@ember-eui/core/utils/preload-icons';

export default class ApplicationRoute extends Route {
  async beforeModel() {
    await preloadIcons(['chevronSingleDown', 'cross', 'magnify', 'gear']);
  }
}
```

`preloadIcons` resolves once all of them loaded. An icon that fails to load
(e.g. a network error) is logged and loaded again the next time it renders.

To have icons without any loading at all, import them and register them
at boot: they are bundled with your app and render with the first paint,
without the placeholder or the fade-in. Every icon type has a module,
`@ember-eui/core/icons/<type>`, whose default export is its component:

```js
// app/app.js
import { registerIcons } from '@ember-eui/core/utils/preload-icons';
import chevronSingleDown from '@ember-eui/core/icons/chevronSingleDown';
import cross from '@ember-eui/core/icons/cross';
import magnify from '@ember-eui/core/icons/magnify';

registerIcons({ chevronSingleDown, cross, magnify });
```

To bundle every EUI icon up front instead (no lazy loading at all, at the
cost of all ~700 icons in your bundle: ~330KB minified, ~130KB gzip),
register them all once:

```js
// app/app.js
import { registerAllIcons } from '@ember-eui/core/utils/register-all-icons';

registerAllIcons();
```

Icons that are neither registered nor preloaded load the first time they
render, as above. An icon that has loaded (or was registered) renders at
once everywhere afterwards, without fading in again.

In tests, `await render()` and `settled()` wait for icons to load, so
assertions see the real svg.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { preloadIcons } from '@ember-eui/core/utils/preload-icons';
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiIcon, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class LazyIconsDemo extends Component {
  @tracked isLoading = false;
  @tracked showLogos = false;

  logos = ['logoGolang', 'logoPostgres', 'logoRedis', 'logoKafka', 'logoNginx'];

  @action
  async loadLogos() {
    this.isLoading = true;
    // render them only once they are all loaded, so they appear together
    await preloadIcons(this.logos);
    this.isLoading = false;
    this.showLogos = true;
  }

  <template>
    <EuiButton @iconType="download" @isLoading={{this.isLoading}} {{on "click" this.loadLogos}}>
      Preload and show some logos
    </EuiButton>

    <EuiSpacer />

    {{#if this.showLogos}}
      <EuiFlexGroup @gutterSize="l" @wrap={{true}} @responsive={{false}}>
        {{#each this.logos as |logo|}}
          <EuiFlexItem @grow={{false}}>
            <EuiIcon @type={{logo}} @size="xl" @title={{logo}} />
          </EuiFlexItem>
        {{/each}}
      </EuiFlexGroup>
    {{/if}}
  </template>
}
```

