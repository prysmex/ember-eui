import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTimelineItemIconStyles } from '../utils/eui/styles.generated.ts';
import EuiAvatar from './eui-avatar.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type {
  EuiTimelineIconType,
  EuiTimelineVerticalAlign
} from './eui-timeline-item.gts';

export interface EuiTimelineItemIconSignature {
  Element: HTMLDivElement;
  Args: {
    /** EuiIcon type rendered in a subdued avatar. */
    icon?: EuiTimelineIconType;
    /** Accessible label for a string icon; an omitted label is decorative. */
    iconAriaLabel?: string;
    /** Align at the top or center of the event. Defaults to `'center'`. */
    verticalAlign?: EuiTimelineVerticalAlign;
    /** Extra styles composed last into the icon-column class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Custom icon content instead of the default avatar. */
    default: [];
  };
}

/** The icon column of a timeline item, including the line anchor. */
export default class EuiTimelineItemIcon extends Component<EuiTimelineItemIconSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiTimelineItemIconStyles);
  }

  @cached
  get classes() {
    const align = this.args.verticalAlign === 'top' ? 'top' : 'center';
    return euiClass(
      this.context,
      this.styles.euiTimelineItemIcon,
      this.styles[align],
      this.args.css
    );
  }

  @cached
  get contentClass() {
    return euiClass(this.context, this.styles.euiTimelineItemIcon__content);
  }

  <template>
    <div class="euiTimelineItemIcon {{this.classes}}" ...attributes>
      <div class="euiTimelineItemIcon__content {{this.contentClass}}">
        {{#if (has-block)}}
          {{yield}}
        {{else}}
          <EuiAvatar
            @color="subdued"
            @name={{if @iconAriaLabel @iconAriaLabel ""}}
            @iconType={{@icon}}
          />
        {{/if}}
      </div>
    </div>
  </template>
}
