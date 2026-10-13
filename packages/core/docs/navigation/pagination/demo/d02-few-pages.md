---
order: 2
---

# Few pages

<EuiText>

The UI simplifies when we have fewer than the maximum number of visible pages.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiPagination } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked activePage = 0;

  @action
  goToPage(activePage) {
    this.activePage = activePage;
  }

  <template>
    <EuiPagination
      aria-label="Few pages example"
      @pageCount={{4}}
      @activePage={{this.activePage}}
      @onPageClick={{this.goToPage}}
    />
  </template>
}
```
