import Component from '@glimmer/component';
import { action } from '@ember/object';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import { uniqueId } from 'ember-eui/helpers/unique-id';
import { tracked } from '@glimmer/tracking';
import { findPopoverPosition } from 'ember-eui/utils/popover';
import { keys } from 'ember-eui/utils/keys';
import { later, cancel, scheduleOnce } from '@ember/runloop';

export type ToolTipPositions = 'top' | 'right' | 'bottom' | 'left';

export type ToolTipDelay = 'regular' | 'long';

const delayToMsMap: { [key in ToolTipDelay]: number } = {
  regular: 250,
  long: 250 * 5,
};

interface ToolTipStyles {
  top: string;
  left: string | 'auto';
  right?: string | 'auto';
  opacity?: string;
  visibility?: 'hidden';
}

const displayToClassNameMap = {
  inlineBlock: undefined,
  block: 'euiToolTipAnchor--displayBlock',
};

const DEFAULT_TOOLTIP_STYLES: ToolTipStyles = {
  // position the tooltip content near the top-left
  // corner of the window so it can't create scrollbars
  // 50,50 because who knows what negative margins, padding, etc
  top: '50px',
  left: '50px',
  // just in case, avoid any potential flicker by hiding
  // the tooltip before it is positioned
  opacity: '0',
  // prevent accidental mouse interaction while positioning
  visibility: 'hidden',
};

type EuiTooltipArgs = {
  /**
   * Passes onto the the trigger.
   */
  anchorClassName?: string;
  /**
   * Passes onto the tooltip itself, not the trigger.
   */
  className?: string;
  /**
   * The main content of your tooltip.
   */
  content?: Component;
  /**
   * Common display alternatives for the anchor wrapper
   */
  display?: keyof typeof displayToClassNameMap;
  /**
   * Delay before showing tooltip. Good for repeatable items.
   */
  delay: ToolTipDelay;
  /**
   * An optional title for your tooltip.
   */
  title?: Component;
  /**
   * Unless you provide one, this will be randomly generated.
   */
  id?: string;
  /**
   * Suggested position. If there is not enough room for it this will be changed.
   */
  position: ToolTipPositions;

  /**
   * If supplied, called when mouse movement causes the tool tip to be
   * hidden.
   */
  onMouseOut?: (event: MouseEvent) => void;
};

export default class EuiToolTip extends Component<EuiTooltipArgs> {
  anchor: null | HTMLElement = null;
  popover: null | HTMLElement = null;

  @argOrDefault('top') position!: ToolTipPositions;
  @argOrDefault('regular') delay!: ToolTipDelay;

  //STATE
  @tracked visible: boolean = false;
  @tracked calculatedPosition: ToolTipPositions = this.position;
  @tracked toolTipStyles: ToolTipStyles = DEFAULT_TOOLTIP_STYLES;
  @tracked arrowStyles: undefined | { left: string; top: string };
  @tracked id: string = this.args.id || uniqueId();

  private timeoutId?: ReturnType<typeof later>;

  @action
  clearAnimationTimeout() {
    if (this.timeoutId) {
      cancel(this.timeoutId);
      this.timeoutId = undefined;
    }
  }

  @action
  visibleDidUpdate(value: boolean) {
    if (this.visible === false && value === true) {
      requestAnimationFrame(this.testAnchor);
    }
  }

  willDestroy() {
    super.willDestroy();
    this.clearAnimationTimeout();
    window.removeEventListener('mousemove', this.hasFocusMouseMoveListener);
  }

  @action
  testAnchor() {
    // when the tooltip is visible, this checks if the anchor is still part of document
    // this fixes when the react root is removed from the dom without unmounting
    // https://github.com/elastic/eui/issues/1105
    if (document.body.contains(this.anchor) === false) {
      // the anchor is no longer part of `document`
      this.hideToolTip();
    } else {
      if (this.visible) {
        // if still visible, keep checking
        requestAnimationFrame(this.testAnchor);
      }
    }
  }

  @action
  didInsertAnchor(ref: HTMLElement) {
    this.anchor = ref;
  }

  @action
  setPopoverRef(ref: HTMLElement) {
    this.popover = ref;

    // if the popover has been unmounted, clear
    // any previous knowledge about its size
    if (ref == null) {
      this.toolTipStyles = DEFAULT_TOOLTIP_STYLES;
      this.arrowStyles = undefined;
    } else {
      this.positionToolTip();
    }
  }

  @action
  showToolTip() {
    if (!this.timeoutId) {
      this.timeoutId = later(
        this,
        () => {
          scheduleOnce('afterRender', this, () => {
            this.visible = true;
          });
        },
        delayToMsMap[this.delay]
      );
    }
  }

  @action
  positionToolTip() {
    const requestedPosition = this.position;

    if (!this.anchor || !this.popover) {
      return;
    }
    const { position, left, top, arrow } = findPopoverPosition({
      anchor: this.anchor,
      popover: this.popover,
      position: requestedPosition,
      offset: 16, // offset popover 16px from the anchor
      arrowConfig: {
        arrowWidth: 12,
        arrowBuffer: 4,
      },
    });

    const windowWidth = document.documentElement.clientWidth || window.innerWidth;
    const useRightValue = windowWidth / 2 < left;

    const toolTipStyles: ToolTipStyles = {
      top: `${top}px`,
      left: useRightValue ? 'auto' : `${left}px`,
      right: useRightValue ? `${windowWidth - left - this.popover.offsetWidth}px` : 'auto',
    };

    this.visible = true;
    this.calculatedPosition = position;
    this.toolTipStyles = toolTipStyles;
    if (arrow) {
      this.arrowStyles = {
        left: `${arrow.left}px`,
        top: `${arrow?.top}px`,
      };
    }
  }

  @action
  hideToolTip() {
    this.clearAnimationTimeout();
    scheduleOnce('afterRender', this, () => {
      if (!this.isDestroying || !this.isDestroyed) {
        this.visible = false;
      }
    });
  }

  @action
  hasFocusMouseMoveListener() {
    this.hideToolTip();
    window.removeEventListener('mousemove', this.hasFocusMouseMoveListener);
  }

  @action
  onKeyUp(event: KeyboardEvent) {
    if (event.key === keys.TAB) {
      window.addEventListener('mousemove', this.hasFocusMouseMoveListener);
    }
  }

  @action
  onMouseOut(event: MouseEvent) {
    // Prevent mousing over children from hiding the tooltip by testing for whether the mouse has
    // left the anchor for a non-child.
    if (
      this.anchor === event.relatedTarget ||
      (this.anchor != null && !this.anchor.contains(event.relatedTarget as Node))
    ) {
      this.hideToolTip();
    }

    if (this.args.onMouseOut) {
      this.args.onMouseOut(event);
    }
  }
}
