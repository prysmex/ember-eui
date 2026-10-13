---
order: 1
---

# Query suggestions

<EuiText>

Type (e.g. "st"): matching suggestions open below. Clicking one puts it
in the field and marks the query as unsaved; "Save" saves it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSuggest, EuiButtonEmpty, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const ALL = [
  { type: { iconType: 'kqlField', color: 'tint4' }, label: 'status', description: 'HTTP status code' },
  { type: { iconType: 'kqlField', color: 'tint4' }, label: 'service.name', description: 'The service that logged it' },
  { type: { iconType: 'kqlValue', color: 'tint0' }, label: 'status: 500' },
  { type: { iconType: 'kqlSelector', color: 'tint3' }, label: 'AND' },
  { type: { iconType: 'search', color: 'tint10' }, label: 'Saved: slow requests', description: 'duration > 2s' },
];

export default class SuggestDemo extends Component {
  @tracked suggestions = ALL;
  @tracked status = 'unchanged';
  @tracked chosen = 'nothing';

  @action
  filter(value) {
    this.suggestions = ALL.filter((item) =>
      item.label.toLowerCase().includes(value.toLowerCase()),
    );
  }

  @action
  choose(item) {
    this.chosen = item.label;
    this.status = 'unsaved';
  }

  @action
  save() {
    this.status = 'saved';
  }

  <template>
    <EuiSuggest
      @suggestions={{this.suggestions}}
      @onInputChange={{this.filter}}
      @onItemClick={{this.choose}}
      @status={{this.status}}
      @placeholder="Search logs"
      aria-label="Query"
    >
      <:append>
        <EuiButtonEmpty @size="xs" {{on "click" this.save}}>Save</EuiButtonEmpty>
      </:append>
    </EuiSuggest>
    <EuiSpacer />
    <EuiText @size="s"><p>Last chosen: {{this.chosen}}</p></EuiText>
  </template>
}
```
