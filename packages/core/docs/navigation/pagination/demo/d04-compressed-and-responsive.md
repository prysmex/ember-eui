---
order: 4
---

# Compressed and responsive

<EuiText>

Use the `@compressed` argument to minimize the horizontal footprint. This will replace the numbered buttons with static numbers and rely on the first, last, next and previous icon buttons to navigate.

This is also the same display that will occur when `@responsive` is **not** `false`. You can adjust the responsiveness by supplying an array of named breakpoints to `@responsive`. The default is `['xs', 's']`.

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
      aria-label="Compressed example"
      @pageCount={{24}}
      @activePage={{this.activePage}}
      @onPageClick={{this.goToPage}}
      @compressed={{true}}
    />
  </template>
}
```
