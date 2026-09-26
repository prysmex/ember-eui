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
    await preloadIcons(['arrowDown', 'cross', 'search', 'gear']);
  }
}
```

`preloadIcons` resolves once all of them loaded. An icon that fails to load
(e.g. a network error) is logged and loaded again the next time it renders.

In tests, `await render()` and `settled()` wait for icons to load, so
assertions see the real svg.

</EuiText>

```hbs template
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
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { preloadIcons } from '@ember-eui/core/utils/preload-icons';

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
}
```
