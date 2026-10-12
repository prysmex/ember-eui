import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiSelectableMessageStyles,
  euiTextStyles
} from '../utils/eui/styles.generated.ts';
import { euiTextColorCss } from './eui-text-color.gts';

/**
 * A message shown by `EuiSelectable` instead of its list: while loading,
 * when nothing matches the search, or when there are no options.
 */
export interface EuiSelectableMessageSignature {
  Element: HTMLDivElement;
  Args: {
    /** Adds the list's border, for bordered lists. */
    bordered?: boolean;
  };
  Blocks: {
    /** The message. */
    default: [];
  };
}

/**
 * Upstream renders `<EuiText color="subdued" size="xs" css={message}>`. Until
 * EuiText takes `@css`, the same styles are composed here into one class
 * (text, size, color, then the message styles), so precedence never depends
 * on rule insertion order.
 */
export default class EuiSelectableMessage extends Component<EuiSelectableMessageSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const { euiTheme } = context.upstream;
    const text = useEuiBorealisStyles(context, euiTextStyles);
    const message = useEuiBorealisStyles(context, euiSelectableMessageStyles);
    return euiClass(
      context,
      {
        boxSizing: 'border-box',
        margin: 0,
        fontFamily: euiTheme.font.family,
        '& :where(p)': { margin: 0, padding: 0, fontSize: 'inherit' }
      },
      text.euiText,
      text.xs,
      euiTextColorCss(context, 'subdued'),
      message.euiSelectableMessage,
      this.args.bordered && message.bordered
    );
  }

  <template>
    <div
      class="euiText euiSelectableMessage {{this.classes}}"
      data-test-subj="euiSelectableMessage"
      ...attributes
    >{{yield}}</div>
  </template>
}
