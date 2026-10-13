---
order: 3
---

# Displacement

<EuiText>
  <p>
    There is an <EuiCode>@affordForDisplacement</EuiCode> argument (defaulting to <EuiCode>true</EuiCode>), which determines whether the component makes room for itself by adding bottom padding equivalent to its own height on the document <EuiCode @language="html">body</EuiCode> element. Setting this to <EuiCode>false</EuiCode> can be useful to minimize scrollbar visibility but will cause the bottom bar to overlap body content.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiBottomBar, EuiButton, EuiButtonGroup, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class BottomBarDisplacementDemo extends Component {
  @tracked toggleIdSelected = null;

  toggleButtons = [
    {
      id: 'bottomBarStandard',
      label: 'Show bottom bar'
    },
    {
      id: 'bottomBarWithoutAffordForDisplacement',
      label: 'Show bottom bar (without affordForDisplacement behavior)'
    }
  ];

  get affordForDisplacement() {
    return this.toggleIdSelected === 'bottomBarStandard';
  }

  @action
  onChange(optionId) {
    this.toggleIdSelected = optionId;
  }

  @action
  close() {
    this.toggleIdSelected = null;
  }

  <template>
    <div>
      <EuiButtonGroup
        @legend='Bottom Bar demo toggle buttons group'
        @type='single'
        @buttonSize='m'
        @color='primary'
        @options={{this.toggleButtons}}
        @idSelected={{this.toggleIdSelected}}
        @onChange={{this.onChange}}
      />

      {{#if this.toggleIdSelected}}
        <EuiBottomBar @affordForDisplacement={{this.affordForDisplacement}}>
          <EuiFlexGroup @justifyContent='flexEnd'>
            <EuiFlexItem @grow={{false}}>
              <EuiButton
                @color='text'
                @size='s'
                @iconType='cross'
                {{on 'click' this.close}}
              >
                close
              </EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiBottomBar>
      {{/if}}
    </div>
  </template>
}
```
