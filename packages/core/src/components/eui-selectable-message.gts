import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiSelectableMessageStyles } from '../utils/eui/styles.generated.ts';
import EuiText from './eui-text.gts';

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

/** Upstream: `<EuiText color="subdued" size="xs" css={message}>`. */
export default class EuiSelectableMessage extends Component<EuiSelectableMessageSignature> {
  @cached
  get css(): EuiCss {
    const context = getEuiThemeContext(this);
    const message = useEuiBorealisStyles(context, euiSelectableMessageStyles);
    return [message.euiSelectableMessage, this.args.bordered && message.bordered];
  }

  <template>
    <EuiText
      class="euiSelectableMessage"
      data-test-subj="euiSelectableMessage"
      @color="subdued"
      @size="xs"
      @css={{this.css}}
      ...attributes
    >{{yield}}</EuiText>
  </template>
}
