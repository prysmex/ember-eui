---
order: 1
---

# Filter a list

<EuiText>

Click a facet to show only its items; click it again to show all.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem @grow={{false}} style="min-width: 200px;">
    <EuiFacetGroup>
      {{#each this.levels as |level|}}
        <EuiFacetButton
          @quantity={{level.count}}
          @isSelected={{eq this.selected level.id}}
          {{on "click" (fn this.select level.id)}}
        >
          <:default>{{level.label}}</:default>
          <:icon>
            <EuiIcon class="euiFacetButton__icon" @type="dot" @color={{level.color}} />
          </:icon>
        </EuiFacetButton>
      {{/each}}
    </EuiFacetGroup>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiText @size="s">
      <ul>
        {{#each this.visibleLogs as |log|}}
          <li><strong>{{log.level}}</strong> {{log.message}}</li>
        {{/each}}
      </ul>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const LOGS = [
  { level: 'error', message: 'Payment service timed out' },
  { level: 'warning', message: 'Disk usage above 80%' },
  { level: 'info', message: 'Deploy 1.4.2 finished' },
  { level: 'error', message: 'Cannot reach the mail server' },
  { level: 'info', message: 'Nightly backup completed' },
];

export default class FacetDemo extends Component {
  @tracked selected = null;

  get levels() {
    return [
      { id: 'error', label: 'Errors', color: 'danger' },
      { id: 'warning', label: 'Warnings', color: 'warning' },
      { id: 'info', label: 'Info', color: 'primary' },
    ].map((level) => ({
      ...level,
      count: LOGS.filter((log) => log.level === level.id).length,
    }));
  }

  get visibleLogs() {
    return this.selected
      ? LOGS.filter((log) => log.level === this.selected)
      : LOGS;
  }

  @action
  select(id) {
    this.selected = this.selected === id ? null : id;
  }
}
```
