---
order: 1
---

# Component

<EuiText>

Some EUI components have pagination built-in, like **EuiBasicTable**, but for custom built paginated interfaces you can use **EuiPagination** manually.

**EuiPagination** accepts a total `@pageCount` and only shows up to 5 consecutive pages, with shortcuts to the first and/or last page. It also requires the parent component to maintain the current `@activePage` and handle the `@onPageClick`.

Provide a descriptive `aria-label` for each pagination set.

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
      aria-label="Many pages example"
      @pageCount={{22}}
      @activePage={{this.activePage}}
      @onPageClick={{this.goToPage}}
    />
  </template>
}
```
