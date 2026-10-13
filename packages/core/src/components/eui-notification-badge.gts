import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiNotificationBadgeStyles } from '../utils/eui/styles.generated.ts';

/** A small count badge, e.g. unread notifications on a header button. */
export interface EuiNotificationBadgeSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'s'` or `'m'`. Defaults to `'s'`. */
    size?: 's' | 'm';
    /** `'accent'`, `'subdued'` or `'success'`. Defaults to `'accent'`. */
    color?: 'accent' | 'subdued' | 'success';
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The count, e.g. `3`. */
    default: [];
  };
}

export default class EuiNotificationBadge extends Component<EuiNotificationBadgeSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiNotificationBadgeStyles);
    return euiClass(
      context,
      // React's global reset: border-box sizing and the body font.
      {
        boxSizing: 'border-box',
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiNotificationBadge,
      styles[this.args.size ?? 's'],
      styles[this.args.color ?? 'accent'],
      this.args.css
    );
  }

  <template>
    <span
      class="euiNotificationBadge {{this.classes}}"
      ...attributes
    >{{yield}}</span>
  </template>
}
