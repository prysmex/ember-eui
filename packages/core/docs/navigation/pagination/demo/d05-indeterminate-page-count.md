---
order: 5
---

# Indeterminate page count

<EuiText>

If the total number of pages cannot be accurately determined, you can pass `0` as the `@pageCount`. This will remove the button numbers and rely solely on the arrow icon buttons for navigation. Without a total page count, the last page button will pass back `-1` for the `@activePage`.

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
      aria-label="Indeterminate example"
      @pageCount={{0}}
      @activePage={{this.activePage}}
      @onPageClick={{this.goToPage}}
    />
  </template>
}
```
