---
order: 3
---

# Centered pagination

<EuiText>

You can use **EuiFlexGroup** to center the pagination in a layout.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFlexGroup, EuiFlexItem, EuiPagination } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked activePage = 0;

  @action
  goToPage(activePage) {
    this.activePage = activePage;
  }

  <template>
    <EuiFlexGroup @justifyContent="spaceAround">
      <EuiFlexItem @grow={{false}}>
        <EuiPagination
          aria-label="Centered pagination example"
          @pageCount={{15}}
          @activePage={{this.activePage}}
          @onPageClick={{this.goToPage}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
