---
order: 6
---

# Unregistering plugins

<EuiText>

<strong>EuiMarkdownEditor</strong> comes with several default plugins, demo'd below. If these defaults are unnecessary for your use-case or context, you can unregister them with a single <EuiCode>exclude</EuiCode> option passed to <EuiCode>getDefaultEuiMarkdownPlugins()</EuiCode> (<EuiCode>'tooltip'</EuiCode>, <EuiCode>'checkbox'</EuiCode>, <EuiCode>'emoji'</EuiCode>, <EuiCode>'linkValidator'</EuiCode> and <EuiCode>'lineBreaks'</EuiCode>), then hand the returned lists to the editor (or to <strong>EuiMarkdownFormat</strong>) as <EuiCode>@parsingPluginList</EuiCode>, <EuiCode>@processingPluginList</EuiCode> and <EuiCode>@uiPlugins</EuiCode>. This ensures the syntax won't be identified or rendered, and no additional UI (like toolbar buttons or help syntax) will be displayed by the unregistered plugins.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { getDefaultEuiMarkdownPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/index';
import { EuiFlexGroup, EuiFlexItem, EuiMarkdownEditor, EuiSwitch } from '@ember-eui/core/components';

export default class UnregisterPlugins extends Component {
  @tracked tooltip = false;
  @tracked checkbox = true;
  @tracked emoji = true;
  @tracked linkValidator = true;
  @tracked lineBreaks = false;

  @tracked value = `
### tooltip

When disabled, the button in the toolbar and the help syntax won't be displayed, and the following syntax will no longer work.

!{tooltip[anchor text](Tooltip content)}

### checkbox

When disabled, a checkbox will no longer render.

- [ ] TODO: Disable some default plugins

### emoji

When disabled, text will render instead of an emoji.

:smile:

### linkValidator

When disabled, all links will render as links instead of as text.

[This is a sus link](file://)

### lineBreaks

When disabled, these sentence will be in the same line.
When enabled, these sentences will be separated by a line break.

Two blank lines in a row will create a new paragraph as usual.
`;

  get plugins() {
    const exclude = [];

    if (!this.tooltip) exclude.push('tooltip');
    if (!this.checkbox) exclude.push('checkbox');
    if (!this.emoji) exclude.push('emoji');
    if (!this.linkValidator) exclude.push('linkValidator');
    if (!this.lineBreaks) exclude.push('lineBreaks');

    return getDefaultEuiMarkdownPlugins({ exclude });
  }

  @action setValue(value) {
    this.value = value;
  }

  @action toggle(name) {
    this[name] = !this[name];
  }

  toggleTooltip = () => this.toggle('tooltip');
  toggleCheckbox = () => this.toggle('checkbox');
  toggleEmoji = () => this.toggle('emoji');
  toggleLinkValidator = () => this.toggle('linkValidator');
  toggleLineBreaks = () => this.toggle('lineBreaks');

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}} style='gap: 20px'>
        <EuiSwitch @label='tooltip' @checked={{this.tooltip}} @onChange={{this.toggleTooltip}} />
        <EuiSwitch @label='checkbox' @checked={{this.checkbox}} @onChange={{this.toggleCheckbox}} />
        <EuiSwitch @label='emoji' @checked={{this.emoji}} @onChange={{this.toggleEmoji}} />
        <EuiSwitch @label='linkValidator' @checked={{this.linkValidator}} @onChange={{this.toggleLinkValidator}} />
        <EuiSwitch @label='lineBreaks' @checked={{this.lineBreaks}} @onChange={{this.toggleLineBreaks}} />
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
