---
order: 1
---

# Highlight a search

<EuiText>

Type to highlight the matches in each name. Toggle the switches to match
case or to highlight every match.

</EuiText>

```hbs template
<EuiFieldSearch
  @placeholder="Search"
  @value={{this.search}}
  @incremental={{true}}
  @onSearch={{this.setSearch}}
/>
<EuiSpacer @size="s" />
<EuiSwitch @label="Match case" @checked={{this.strict}} {{on "change" this.toggleStrict}} />
<EuiSpacer @size="s" />
<EuiSwitch @label="Highlight all matches" @checked={{this.highlightAll}} {{on "change" this.toggleAll}} />
<EuiSpacer />
<EuiText>
  <ul>
    {{#each this.names as |name|}}
      <li>
        <EuiHighlight
          @text={{name}}
          @search={{this.search}}
          @strict={{this.strict}}
          @highlightAll={{this.highlightAll}}
        />
      </li>
    {{/each}}
  </ul>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class HighlightDemo extends Component {
  names = [
    'Banana bread with banana chips',
    'Bandana Blue',
    'Canal banks of Amsterdam',
    'An annual banquet',
  ];

  @tracked search = 'an';
  @tracked strict = false;
  @tracked highlightAll = false;

  @action
  setSearch(value) {
    this.search = value;
  }

  @action
  toggleStrict(event) {
    this.strict = event.target.checked;
  }

  @action
  toggleAll(event) {
    this.highlightAll = event.target.checked;
  }
}
```
