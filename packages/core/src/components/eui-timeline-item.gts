import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiTimelineItemStyles } from '../utils/eui/styles.generated.ts';
import EuiTimelineItemEvent from './eui-timeline-item-event.gts';
import EuiTimelineItemIcon from './eui-timeline-item-icon.gts';

import type { EuiRenderNode as EuiRenderNodeType } from '../-private/eui-render-node.gts';
import type { EuiIconSignature } from './eui-icon.gts';
import type { EuiCss } from '../utils/eui/styles.ts';

export type EuiTimelineVerticalAlign = 'top' | 'center';
export type EuiTimelineIconType = EuiIconSignature['Args']['type'];

export interface EuiTimelineItemData {
  /** The event's text. Same as `children`, which wins when both are set. */
  content?: string;
  /**
   * The event's content (upstream's `children`): text, or a component for
   * rich content (a template-only component or `(component …)`).
   */
  children?: EuiRenderNodeType;
  /**
   * An icon type, or a component for a custom icon (upstream's `icon` node).
   */
  icon?: EuiTimelineIconType | EuiRenderNodeType;
  iconAriaLabel?: string;
  verticalAlign?: EuiTimelineVerticalAlign;
}

export interface EuiTimelineItemSignature {
  Element: HTMLLIElement;
  Args: {
    /** EuiIcon type rendered in a subdued avatar. */
    icon?: EuiTimelineIconType;
    /** Accessible label for a string icon; an omitted label is decorative. */
    iconAriaLabel?: string;
    /** Align the icon and event at their top or center. Defaults to `'center'`. */
    verticalAlign?: EuiTimelineVerticalAlign;
    /** Extra styles composed last into the list item class. */
    css?: EuiCss;
  };
  Blocks: {
    /** Event content rendered beside the icon. */
    default: [];
    /** Custom icon content instead of the default avatar. */
    icon: [];
  };
}

const ITEM_STYLES = euiTimelineItemStyles();

/** One icon/event pair in an EuiTimeline. */
export default class EuiTimelineItem extends Component<EuiTimelineItemSignature> {
  get verticalAlign(): EuiTimelineVerticalAlign {
    return this.args.verticalAlign === 'top' ? 'top' : 'center';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    return euiClass(
      context,
      ITEM_STYLES.euiTimelineItem,
      ITEM_STYLES[this.verticalAlign],
      this.args.css
    );
  }

  <template>
    <li class="euiTimelineItem {{this.classes}}" ...attributes>
      {{#if (has-block "icon")}}
        <EuiTimelineItemIcon @verticalAlign={{this.verticalAlign}}>
          {{yield to="icon"}}
        </EuiTimelineItemIcon>
      {{else}}
        <EuiTimelineItemIcon
          @icon={{@icon}}
          @iconAriaLabel={{@iconAriaLabel}}
          @verticalAlign={{this.verticalAlign}}
        />
      {{/if}}
      <EuiTimelineItemEvent @verticalAlign={{this.verticalAlign}}>
        {{yield}}
      </EuiTimelineItemEvent>
    </li>
  </template>
}
