---
order: 1
---

# Generating ids

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiButton,
  EuiCode,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiSpacer
} from '@ember-eui/core/components';
import { htmlIdGenerator } from '@ember-eui/core/utils/html-id-generator';

const generateId = htmlIdGenerator('test');

export default class HtmlIdGeneratorDemo extends Component {
  @tracked prefix = 'Some';
  @tracked suffix = 'Id';
  @tracked value = htmlIdGenerator()();
  @tracked batch = [generateId(), generateId(), generateId('hello'), generateId('world')];

  get customId() {
    return htmlIdGenerator(this.prefix)(this.suffix);
  }

  @action
  regenerate() {
    this.value = htmlIdGenerator()();
    this.batch = [generateId(), generateId(), generateId('hello'), generateId('world')];
  }

  @action
  setPrefix(event) {
    this.prefix = event.target.value;
  }

  @action
  setSuffix(event) {
    this.suffix = event.target.value;
  }

  <template>
    <div>
      <EuiFlexGroup @alignItems='center' @gutterSize='m' @justifyContent='flexStart'>
        <EuiFlexItem @grow={{false}}><EuiCode>{{this.value}}</EuiCode></EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton {{on 'click' this.regenerate}}>Regenerate</EuiButton>
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiSpacer @size='xl' />
      <EuiFlexGroup @gutterSize='m' @alignItems='center' @justifyContent='flexStart'>
        <EuiFlexItem @grow={{false}}>
          <EuiFormRow @label='Prefix'>
            <EuiFieldText @value={{this.prefix}} placeholder='Enter prefix' {{on 'input' this.setPrefix}} />
          </EuiFormRow>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiFormRow @label='Suffix'>
            <EuiFieldText @value={{this.suffix}} placeholder='Enter suffix' {{on 'input' this.setSuffix}} />
          </EuiFormRow>
        </EuiFlexItem>
      </EuiFlexGroup>
      <EuiSpacer @size='m' />
      <EuiCode>{{this.customId}}</EuiCode>
      <EuiSpacer @size='xl' />
      {{#each this.batch as |id|}}
        <EuiCode>{{id}}</EuiCode><br />
      {{/each}}
    </div>
  </template>
}
```
