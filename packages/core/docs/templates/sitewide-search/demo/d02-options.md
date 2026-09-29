---
order: 2
---

# Loading and a popover button

<EuiText>

The `<:popoverButton>` block replaces the field with a button that opens
the popover (the search moves into it), here with a title. While
`@isLoading`, "Loading results" is shown: this demo "fetches" for a
second after each change of the search.

</EuiText>

```hbs template
<EuiSelectableTemplateSitewide
  @options={{this.options}}
  @isLoading={{this.isLoading}}
  @isPreFiltered={{true}}
  @onSearch={{this.search}}
  @popoverWidth={{400}}
>
  <:popoverButton as |toggle|>
    <EuiButtonIcon @iconType="search" @display="base" aria-label="Search" {{on "click" toggle}} />
  </:popoverButton>
  <:popoverTitle>Search the docs</:popoverTitle>
</EuiSelectableTemplateSitewide>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const PAGES = ['Button', 'Badge', 'Card', 'Combo box', 'Context menu', 'Flyout', 'Modal'];

export default class SitewideLoading extends Component {
  @tracked options = PAGES.map((label) => ({ label, icon: { type: 'document' } }));
  @tracked isLoading = false;

  @action
  async search(value) {
    this.isLoading = true;
    await new Promise((resolve) => setTimeout(resolve, 1000));
    this.options = PAGES.filter((label) =>
      label.toLowerCase().includes(value.toLowerCase()),
    ).map((label) => ({ label, icon: { type: 'document' } }));
    this.isLoading = false;
  }
}
```
