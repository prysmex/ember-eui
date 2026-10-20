// A custom theme-aware component (public theming API).
import Component from '@glimmer/component';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles,
} from '@ember-eui/core/theming';

const styles = ({ euiTheme }) => ({ root: { padding: euiTheme.size.m } });

class Card extends Component {
  get classes() {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, styles).root);
  }
  <template>
    <div class={{this.classes}}>{{yield}}</div>
  </template>
}

console.log(Card);
