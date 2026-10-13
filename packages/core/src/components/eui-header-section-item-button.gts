import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { eq } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiBreakpointsMedia,
  euiOutsideBreakpointsMedia
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiHeaderSectionItemButtonStyles,
  euiMaxBreakpoint
} from '../utils/eui/styles.generated.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiIcon from './eui-icon.gts';
import EuiNotificationBadge from './eui-notification-badge.gts';

import type { EuiNotificationBadgeSignature } from './eui-notification-badge';
import type { EuiButtonEmptySignature } from './eui-button-empty';
import type { EuiCss } from '../utils/eui/styles.ts';

const keyframes: Keyframe[] = [
  { transform: 'rotate(0)', offset: 0, easing: 'ease-in-out' },
  {
    transform: 'rotate(30deg)',
    offset: 0.01,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-28deg)',
    offset: 0.03,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(34deg)',
    offset: 0.05,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-32deg)',
    offset: 0.07,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(30deg)',
    offset: 0.09,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-28deg)',
    offset: 0.11,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(26deg)',
    offset: 0.13,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-24deg)',
    offset: 0.15,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(22deg)',
    offset: 0.17,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-20deg)',
    offset: 0.19,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(18deg)',
    offset: 0.21,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-16deg)',
    offset: 0.23,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(14deg)',
    offset: 0.25,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-12deg)',
    offset: 0.27,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(10deg)',
    offset: 0.29,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-8deg)',
    offset: 0.31,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(6deg)',
    offset: 0.33,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-4deg)',
    offset: 0.35,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(2deg)',
    offset: 0.37,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-1deg)',
    offset: 0.39,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(1deg)',
    offset: 0.41,
    easing: 'ease-in-out'
  },
  { transform: 'rotate(0)', offset: 0.43, easing: 'ease-in-out' },
  { transform: 'rotate(0)', offset: 1, easing: 'ease-in-out' }
];

/**
 * An icon button for the header (e.g. help, notifications, user menu),
 * with an optional notification dot or count. Give it an `aria-label`.
 */
export interface EuiHeaderSectionItemButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    /**
     * Called with `{ euiAnimate }`; call `euiAnimate()` to wiggle the
     * button, e.g. when a new notification arrives.
     */
    ref?: (api: { euiAnimate: () => void }) => void;
    /** Disables the button. */
    disabled?: boolean;
    /** Same as `@disabled` (upstream's name, from EuiButtonEmpty). */
    isDisabled?: boolean;
    /** EuiButtonEmpty color. Defaults to `'text'`. */
    color?: EuiButtonEmptySignature['Args']['color'];
    /** EuiButtonEmpty `contentProps`: class, css and attributes of the content element. */
    contentProps?: EuiButtonEmptySignature['Args']['contentProps'];
    /** EuiButtonEmpty `textProps`: class, css and attributes of the text element. */
    textProps?: EuiButtonEmptySignature['Args']['textProps'];
    /** Pulls the button to an edge, see `EuiButtonEmpty`. */
    flush?: EuiButtonEmptySignature['Args']['flush'];
    /** Beta: `aria-disabled` instead of `disabled`, see `EuiButtonEmpty`. */
    hasAriaDisabled?: boolean;
    /** Side of the icon, see `EuiButtonEmpty`. */
    iconSide?: EuiButtonEmptySignature['Args']['iconSide'];
    /** Size of the icon, see `EuiButtonEmpty`. */
    iconSize?: EuiButtonEmptySignature['Args']['iconSize'];
    /** Icon next to the content, see `EuiButtonEmpty`. */
    iconType?: EuiButtonEmptySignature['Args']['iconType'];
    /** Shows a spinner and disables the button. */
    isLoading?: boolean;
    /** Sets `aria-pressed` for toggle buttons. */
    isSelected?: boolean;
    /** `'xs'`, `'s'` or `'m'`, see `EuiButtonEmpty`. */
    size?: EuiButtonEmptySignature['Args']['size'];
    /** Extra styles composed last into the button's class. */
    css?: EuiCss;
    /** Renders a link instead of a button. */
    href?: string;
    /** Called on click. */
    onClick?: (event: MouseEvent) => void;
    /**
     * `true` shows a dot; a number shows a count badge, which becomes a dot
     * below the theme's `m` breakpoint (as upstream; formerly only `xs`).
     */
    notification?: boolean | number | string;
    /** `'accent'`, `'subdued'` or `'success'`. Defaults to `'accent'`. */
    notificationColor?: EuiNotificationBadgeSignature['Args']['color'];
  };
  Blocks: {
    /** The button's content, usually an `EuiIcon` or `EuiAvatar`. */
    default: [];
  };
}

/** Upstream small-screen check (`useIsWithinMaxBreakpoint('s')`), as CSS. */
const SMALL_SCREENS = ['xs', 's'] as const;

/**
 * Upstream `EuiHeaderSectionItemButton` (`euiHeaderSectionItemButtonStyles`
 * composed over EuiButtonEmpty). Upstream swaps a count badge for a dot on
 * small screens in JS; here both are rendered and media queries pick one.
 */
export default class EuiHeaderSectionItemButtonComponent extends Component<EuiHeaderSectionItemButtonSignature> {
  @tracked buttonRef: HTMLButtonElement | HTMLAnchorElement | undefined;
  @tracked animationTargetRef: HTMLSpanElement | undefined;

  setAnimationTargetRef = (ele: HTMLSpanElement) => {
    this.animationTargetRef = ele;
    this.args.ref?.({ euiAnimate: this.animate });
  };

  animate = () => {
    this.animationTargetRef?.animate(keyframes, { duration: 5000 });
  };

  setButtonRef = (ele: HTMLButtonElement | HTMLAnchorElement) => {
    this.buttonRef = ele;
  };

  willDestroy(): void {
    super.willDestroy();
    this.buttonRef = undefined;
    this.animationTargetRef = undefined;
  }

  get notificationColor() {
    return this.args.notificationColor ?? 'accent';
  }

  /**
   * Upstream's `css` for the notification dot (EuiIcon) and badge
   * (EuiNotificationBadge), composed last into their own classes through
   * `@css`.
   */
  @cached
  get notificationCss() {
    const context = getEuiThemeContext(this);
    const { notification } = useEuiBorealisStyles(
      context,
      euiHeaderSectionItemButtonStyles
    );
    const small = euiBreakpointsMedia(context.upstream, SMALL_SCREENS);
    const large = euiOutsideBreakpointsMedia(context.upstream, SMALL_SCREENS);
    const { size } = context.upstream.euiTheme;
    // Upstream's `dot` shrinks the icon below `s`.
    const dotSize = {
      [euiMaxBreakpoint(context.upstream, 's')]: {
        inlineSize: size.base,
        blockSize: size.base
      }
    };
    const hidden = (media: string | undefined) =>
      media ? { [media]: { display: 'none' } } : undefined;
    const dot = [
      notification.euiHeaderSectionItemButton__notification,
      notification.dot,
      dotSize
    ];
    return {
      dot,
      // A count: badge on larger screens, dot on small ones.
      badge: [
        notification.euiHeaderSectionItemButton__notification,
        notification.badge,
        hidden(small)
      ],
      smallDot: [...dot, hidden(large)]
    };
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiHeaderSectionItemButtonStyles
    );
    return {
      // Upstream's `css` on EuiButtonEmpty.
      button: [styles.euiHeaderSectionItemButton, this.args.css],
      content: euiClass(context, styles.euiHeaderSectionItemButton__content)
    };
  }

  <template>
    <EuiButtonEmpty
      class="euiHeaderSectionItemButton"
      @css={{this.styles.button}}
      @isDisabled={{if @isDisabled @isDisabled @disabled}}
      @href={{@href}}
      @color={{if @color @color "text"}}
      @contentProps={{@contentProps}}
      @textProps={{@textProps}}
      @flush={{@flush}}
      @hasAriaDisabled={{@hasAriaDisabled}}
      @iconSide={{@iconSide}}
      @iconSize={{@iconSize}}
      @iconType={{@iconType}}
      @isLoading={{@isLoading}}
      @isSelected={{@isSelected}}
      @size={{@size}}
      {{didInsert this.setButtonRef}}
      {{on "click" (optional @onClick)}}
      ...attributes
    >
      <span
        {{didInsert this.setAnimationTargetRef}}
        class="euiHeaderSectionItemButton__content {{this.styles.content}}"
      >
        {{yield}}
      </span>
      {{#if @notification}}
        {{#if (eq @notification true)}}
          <EuiIcon
            @iconClasses="euiHeaderSectionItemButton__notification euiHeaderSectionItemButton__notification--dot"
            @css={{this.notificationCss.dot}}
            @color={{this.notificationColor}}
            @type="dot"
            @size="l"
          />
        {{else}}
          <EuiNotificationBadge
            class="euiHeaderSectionItemButton__notification euiHeaderSectionItemButton__notification--badge"
            @css={{this.notificationCss.badge}}
            @color={{this.notificationColor}}
          >
            {{@notification}}
          </EuiNotificationBadge>
          <EuiIcon
            @iconClasses="euiHeaderSectionItemButton__notification euiHeaderSectionItemButton__notification--dot"
            @css={{this.notificationCss.smallDot}}
            @color={{this.notificationColor}}
            @type="dot"
            @size="l"
          />
        {{/if}}
      {{/if}}
    </EuiButtonEmpty>
  </template>
}
