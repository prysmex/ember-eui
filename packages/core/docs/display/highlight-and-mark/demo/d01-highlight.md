---
order: 1
---

# Highlight

<EuiText>

Use `EuiHighlight` to highlight substrings within a string, typically in response to user input.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiFieldSearch, EuiFlexGroup, EuiFormRow, EuiHighlight, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';

export default class extends Component {
  @tracked searchInput = 'jumped over';
  @tracked isHighlightAll = false;
  @tracked searchMultiple = false;
  @tracked caseSensitive = false;

  get searchValues() {
    return this.searchMultiple && this.isHighlightAll
      ? this.searchInput.split(' ')
      : this.searchInput;
  }

  @action
  setSearchInput(value) {
    this.searchInput = value;
  }

  @action
  toggleCaseSensitive() {
    this.caseSensitive = !this.caseSensitive;
  }

  @action
  toggleHighlightAll() {
    this.isHighlightAll = !this.isHighlightAll;
  }

  @action
  toggleSearchMultiple() {
    this.searchMultiple = !this.searchMultiple;
  }

  <template>
    <EuiFlexGroup>
      <EuiSwitch
        @label='Case sensitive'
        @checked={{this.caseSensitive}}
        @onChange={{this.toggleCaseSensitive}}
      />
      <EuiSwitch
        @label='Highlight all'
        @checked={{this.isHighlightAll}}
        @onChange={{this.toggleHighlightAll}}
      />
      {{#if this.isHighlightAll}}
        <EuiSwitch
          @label='Search for an array of separate words'
          @checked={{this.searchMultiple}}
          @onChange={{this.toggleSearchMultiple}}
        />
      {{/if}}
    </EuiFlexGroup>
    <EuiSpacer @size='xl' />
    <EuiFormRow @label='Enter text to highlight substrings within a string'>
      <EuiFieldSearch
        @value={{this.searchInput}}
        @incremental={{true}}
        @onSearch={{this.setSearchInput}}
      />
    </EuiFormRow>
    <EuiSpacer @size='m' />
    <EuiHighlight
      @strict={{this.caseSensitive}}
      @highlightAll={{this.isHighlightAll}}
      @search={{this.searchValues}}
      @text='The quick brown fox jumped over the lazy dog'
    />
  </template>
}
```

