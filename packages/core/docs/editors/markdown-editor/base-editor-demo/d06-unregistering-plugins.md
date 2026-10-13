---
order: 6
---

# Unregistering plugins

<EuiText>

<strong>EuiMarkdownEditor</strong> comes with default plugins. If they are unnecessary for your use-case or context, you can unregister them with the <EuiCode>exclude</EuiCode> option passed to <EuiCode>getDefaultEuiMarkdownPlugins()</EuiCode>, then hand the returned lists to the editor (or to <strong>EuiMarkdownFormat</strong>) as <EuiCode>@parsingPluginList</EuiCode> and <EuiCode>@processingPluginList</EuiCode>. The syntax of an unregistered plugin won't be identified or rendered.

In Ember EUI only the <EuiCode>tooltip</EuiCode> plugin can be excluded for now. Toggle the switch to see the tooltip syntax render or stay as plain text.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { getDefaultEuiMarkdownPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/index';
import { EuiFlexGroup, EuiFlexItem, EuiMarkdownEditor, EuiSwitch } from '@ember-eui/core/components';

export default class UnregisterPlugins extends Component {
  @tracked tooltip = true;
  @tracked value = `
### tooltip

When disabled, the following syntax will no longer work.

!{tooltip[anchor text](Tooltip content)}

### checkbox

- [ ] Checkboxes are always registered here

### emoji

:smile:
`;

  get plugins() {
    return getDefaultEuiMarkdownPlugins({
      exclude: this.tooltip ? [] : ['tooltip'],
    });
  }

  @action setValue(value) {
    this.value = value;
  }

  @action toggleTooltip() {
    this.tooltip = !this.tooltip;
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='tooltip'
          @checked={{this.tooltip}}
          @onChange={{this.toggleTooltip}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiMarkdownEditor
          @ariaLabel='Demo with excluded default plugins'
          @value={{this.value}}
          @onChange={{this.setValue}}
          @parsingPluginList={{this.plugins.parsingPlugins}}
          @processingPluginList={{this.plugins.processingPlugins}}
          @uiPlugins={{this.plugins.uiPlugins}}
          @initialViewMode='viewing'
          @autoExpandPreview={{false}}
          @height={{400}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

