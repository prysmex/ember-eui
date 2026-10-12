import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTimelineStyles } from '../utils/eui/styles.generated.ts';
import EuiTimelineItem from './eui-timeline-item.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiTimelineItemData } from './eui-timeline-item.gts';

export type EuiTimelineGutterSize = 'm' | 'l' | 'xl';

const LIST_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;

export interface EuiTimelineSignature {
  Element: HTMLOListElement;
  Args: {
    /** Simple item data; use the default block for rich event content. */
    items?: EuiTimelineItemData[];
    /** Vertical space between items. Defaults to `'xl'`. */
    gutterSize?: EuiTimelineGutterSize;
    /** Extra styles composed last into the timeline class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Rich timeline items, rendered after any simple `@items`. */
    default: [];
  };
}

/** An ordered sequence of events connected by a vertical line. */
export default class EuiTimeline extends Component<EuiTimelineSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTimelineStyles);
    return euiClass(
      context,
      LIST_RESET,
      styles.euiTimeline,
      styles[this.args.gutterSize ?? 'xl'],
      this.args.css
    );
  }

  <template>
    {{! template-lint-disable no-redundant-role }}
    <ol class="euiTimeline {{this.classes}}" role="list" ...attributes>
      {{#each @items as |item|}}
        <EuiTimelineItem
          @icon={{item.icon}}
          @iconAriaLabel={{item.iconAriaLabel}}
          @verticalAlign={{item.verticalAlign}}
        >{{item.content}}</EuiTimelineItem>
      {{/each}}
      {{yield}}
    </ol>
  </template>
}
