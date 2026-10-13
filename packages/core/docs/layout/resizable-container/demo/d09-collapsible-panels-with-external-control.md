---
order: 9
---

# Collapsible panels with external control

<EuiText>
  <p>
    <strong>EuiResizableContainer</strong> also yields a <EuiCode>togglePanel</EuiCode> action for parent components to access internal methods, such as <strong>Panel</strong> collapse toggling.
  </p>
  <p>
    Note that when bypassing internal <strong>EuiResizableContainer</strong> logic, it is possible to create situations that would otherwise be prevented. For instance, allowing all panels to be collapsed creates a scenario where your app will need to account for empty state and accessibility in regards to keyboard navigation.
  </p>
  <h3>Custom collapse button</h3>
  <p>
    You can also provide an external collapse button for custom placement and look within your panel with <EuiCode>@mode=&#123;&#123;array 'custom'&#125;&#125;</EuiCode>. When collapsed, however, the default collapsed button will be used for users to expand the panel.
  </p>
  <p>
    For consistency, we recommend the usage of the <EuiCode>transition*</EuiCode> icon types.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { tracked } from '@glimmer/tracking';
import { EuiButtonGroup, EuiButtonIcon, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiResizableContainer, EuiSpacer, EuiText, EuiTitle, EuiToolTip } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class ExternalControlDemo extends Component {
  @tracked toggleIdToSelectedMap = {};
  togglePanel;

  toggleButtons = [
    { id: '1', label: 'Toggle Panel 1' },
    { id: '2', label: 'Toggle Panel 2' }
  ];

  customMode = ['custom', { position: 'top' }];

  @action
  setTogglePanel(togglePanel) {
    this.togglePanel = togglePanel;
  }

  @action
  onCollapse(optionId) {
    this.toggleIdToSelectedMap = {
      ...this.toggleIdToSelectedMap,
      [optionId]: !this.toggleIdToSelectedMap[optionId]
    };
  }

  @action
  onChange(optionId) {
    this.onCollapse(optionId);
    this.togglePanel(`panel${optionId}`, {
      direction: optionId === '3' ? 'right' : 'left'
    });
  }

  <template>
    <EuiText @textAlign='center'>
      <EuiButtonGroup
        @legend='Collapsible panels'
        @options={{this.toggleButtons}}
        @idToSelectedMap={{this.toggleIdToSelectedMap}}
        @onChange={{this.onChange}}
        @color='primary'
        @type='multi'
      />
    </EuiText>

    <EuiSpacer />

    <EuiResizableContainer
      style='height: 250px;'
      @onToggleCollapsed={{this.onCollapse}}
      as |c|
    >
      {{! keep the yielded togglePanel, to call it from the buttons outside }}
      <span hidden {{didInsert (fn this.setTogglePanel c.togglePanel)}}></span>
      <c.Panel @id='panel1' @initialSize={{30}} @minSize='10%'>
        <EuiPanel @paddingSize='l' style='height: 100%;'>
          <EuiTitle><p>Panel 1</p></EuiTitle>
        </EuiPanel>
      </c.Panel>
      <c.Button />
      <c.Panel @id='panel2' @initialSize={{35}} @minSize='50px'>
        <EuiPanel @paddingSize='l' style='height: 100%;'>
          <EuiTitle><p>Panel 2</p></EuiTitle>
        </EuiPanel>
      </c.Panel>
      <c.Button />
      <c.Panel @id='panel3' @mode={{this.customMode}} @initialSize={{35}} @minSize='10%'>
        <EuiPanel @paddingSize='l' style='height: 100%;'>
          <EuiFlexGroup @justifyContent='spaceBetween' @alignItems='center'>
            <EuiFlexItem>
              <EuiTitle><p>Panel 3</p></EuiTitle>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiToolTip @content='Toggle panel 3' @disableScreenReaderOutput={{true}}>
                <EuiButtonIcon
                  @color='text'
                  @iconType='transitionRightOut'
                  aria-label='Toggle panel 3'
                  {{on 'click' (fn this.onChange '3')}}
                />
              </EuiToolTip>
            </EuiFlexItem>
          </EuiFlexGroup>
          <EuiSpacer />
          <EuiText @size='s'>
            <p>
              This panel provides its own button for triggering collapsibility but relies on the default collapsed button to expand.
            </p>
          </EuiText>
        </EuiPanel>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
