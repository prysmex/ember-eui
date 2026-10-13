---
order: 2
---

# `@css`: objects, strings and theme functions

<EuiText>

`@css` is composed last into the component's own class. A theme function
receives `{ euiTheme, colorMode, highContrastMode }`; it is defined at
module scope, so it runs once per theme and is shared by every panel.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiPanel,
  EuiSpacer,
  EuiSwitch
} from '@ember-eui/core/components';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';

const narrow = { maxInlineSize: '32ch' };

const underline = 'text-decoration: underline dotted;';

const accentEdge = ({ euiTheme, colorMode, highContrastMode }) => ({
  borderInlineStart: `${highContrastMode ? '4px' : '2px'} solid ${euiTheme.colors.borderStrongAccent}`,
  backgroundColor:
    colorMode === 'DARK'
      ? euiTheme.colors.backgroundBaseAccent
      : euiTheme.colors.backgroundLightAccent,
  color: euiTheme.colors.textAccent
});

const mixed = [narrow, accentEdge];

export default class DemoComponent extends Component {
  @tracked dark = false;
  toggle = () => (this.dark = !this.dark);

  <template>
    <EuiSwitch @label="Dark section" @checked={{this.dark}} @onChange={{this.toggle}} />
    <EuiSpacer />
    <EuiEmotionProvider @colorMode={{if this.dark "dark" "light"}}>
      <EuiFlexGroup @gutterSize="m" @wrap={{true}}>
        <EuiFlexItem><EuiPanel @css={{narrow}}>An object</EuiPanel></EuiFlexItem>
        <EuiFlexItem><EuiPanel @css={{underline}}>A string</EuiPanel></EuiFlexItem>
        <EuiFlexItem><EuiPanel @css={{accentEdge}}>A theme function</EuiPanel></EuiFlexItem>
        <EuiFlexItem><EuiPanel @css={{mixed}}>An array of both</EuiPanel></EuiFlexItem>
      </EuiFlexGroup>
    </EuiEmotionProvider>
  </template>
}
```
