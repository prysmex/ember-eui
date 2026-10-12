import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTimelineStyles } from '../utils/eui/styles.generated.ts';

/** React's global list reset, scoped to the timeline list. */
const LIST_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;

/** Stacks EuiComments along a shared timeline (an ordered list). */
export interface EuiCommentListSignature {
  Element: HTMLOListElement;
  Args: {
    /**
     * Vertical space between comments: `'m'`, `'l'` or `'xl'`.
     * Defaults to `'l'`.
     */
    gutterSize?: 'm' | 'l' | 'xl';
  };
  Blocks: {
    /** The `EuiComment`s. */
    default: [];
  };
}

/**
 * Native Ember comment list: upstream renders it as an `EuiTimeline`
 * (`<ol role="list">`) with the vertical line between the avatars.
 */
export default class EuiCommentList extends Component<EuiCommentListSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTimelineStyles);
    const gutter = this.args.gutterSize;
    return euiClass(
      context,
      LIST_RESET,
      styles.euiTimeline,
      styles[gutter === 'm' || gutter === 'xl' ? gutter : 'l']
    );
  }

  <template>
    {{! template-lint-disable no-redundant-role }}
    <ol class="euiCommentList euiTimeline {{this.classes}}" role="list" ...attributes>
      {{yield}}
    </ol>
  </template>
}
