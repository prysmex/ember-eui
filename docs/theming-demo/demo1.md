---
order: 1
---

# A component with a style factory

<EuiText>

`StatCard` builds its class from semantic tokens through
`useEuiBorealisStyles` and `euiClass`, and composes the caller's `@css`
last. Switch the section to dark or high contrast: the card follows.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSwitch
} from '@ember-eui/core/components';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

const statCardStyles = ({ euiTheme }) => ({
  root: {
    padding: euiTheme.size.m,
    borderRadius: euiTheme.border.radius.medium,
    border: euiTheme.border.thin,
    backgroundColor: euiTheme.colors.backgroundBasePlain,
    color: euiTheme.colors.textParagraph
  },
  danger: { borderColor: euiTheme.colors.borderBaseDanger },
  label: { color: euiTheme.colors.textSubdued },
  value: {
    fontSize: euiTheme.size.l,
    fontWeight: euiTheme.font.weight.bold,
    color: euiTheme.colors.textHeading
  },
  dangerValue: { color: euiTheme.colors.textDanger }
});

class StatCard extends Component {
  get styles() {
    return useEuiBorealisStyles(getEuiThemeContext(this), statCardStyles);
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    return euiClass(
      context,
      this.styles.root,
      this.args.danger && this.styles.danger,
      this.args.css
    );
  }

  @cached
  get labelClass() {
    return euiClass(getEuiThemeContext(this), this.styles.label);
  }

  @cached
  get valueClass() {
    return euiClass(
      getEuiThemeContext(this),
      this.styles.value,
      this.args.danger && this.styles.dangerValue
    );
  }

  <template>
    <div class={{this.classes}} ...attributes>
      <div class={{this.labelClass}}>{{@label}}</div>
      <div class={{this.valueClass}}>{{@value}}</div>
    </div>
  </template>
}

export default class DemoComponent extends Component {
  @tracked dark = false;
  @tracked highContrast = false;

  toggleDark = () => (this.dark = !this.dark);
  toggleContrast = () => (this.highContrast = !this.highContrast);

  <template>
    <EuiFlexGroup @gutterSize="m" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @label="Dark" @checked={{this.dark}} @onChange={{this.toggleDark}} />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch @label="High contrast" @checked={{this.highContrast}} @onChange={{this.toggleContrast}} />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiEmotionProvider
      @colorMode={{if this.dark "dark" "light"}}
      @highContrastMode={{this.highContrast}}
    >
      <EuiFlexGroup @gutterSize="m" @responsive={{false}}>
        <EuiFlexItem><StatCard @label="Requests" @value="12,840" /></EuiFlexItem>
        <EuiFlexItem><StatCard @label="Errors" @value="37" @danger={{true}} /></EuiFlexItem>
      </EuiFlexGroup>
    </EuiEmotionProvider>
  </template>
}
```
