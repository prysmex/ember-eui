import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiTimelineItemEventStyles } from '../utils/eui/styles.generated.ts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiTimelineVerticalAlign } from './eui-timeline-item.gts';

export interface EuiTimelineItemEventSignature {
  Element: HTMLDivElement;
  Args: {
    /** Align at the top or center of the icon. Defaults to `'center'`. */
    verticalAlign?: EuiTimelineVerticalAlign;
    /** Extra styles composed last into the event class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Event content. */
    default: [];
  };
}

const EVENT_STYLES = euiTimelineItemEventStyles();

/** The flexible event content beside a timeline icon. */
export default class EuiTimelineItemEvent extends Component<EuiTimelineItemEventSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const align = this.args.verticalAlign === 'top' ? 'top' : 'center';
    return euiClass(
      context,
      EVENT_STYLES.euiTimelineItemEvent,
      EVENT_STYLES[align],
      this.args.css
    );
  }

  <template>
    <div class="euiTimelineItemEvent {{this.classes}}" ...attributes>{{yield}}</div>
  </template>
}
