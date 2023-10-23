import Component from '@glimmer/component';
import { EuiButtomBarArgs } from '../eui-bottom-bar';
import { tracked } from '@glimmer/tracking';
// import { action } from '@ember/object';
// import { tracked } from '@glimmer/tracking';
// import {
//   getTransitionTimings,
//   getWaitDuration,
//   performOnFrame
// } from '../../utils/transition';
// import { findPopoverPosition, getElementZIndex } from '../../utils/popover';
// import { EuiPopoverPosition } from '../../utils/popover/types';
// import { cascadingMenuKeys } from '../../utils/accesibility';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
// import { tabbable } from 'tabbable';
// import {
//   anchorPositionMapping,
//   displayMapping
// } from '../../utils/css-mappings/eui-popover';
// import { paddingSizeMapping } from '../../utils/css-mappings/eui-panel';
// import { scheduleOnce, later, cancel } from '@ember/runloop';
// import { assert } from '@ember/debug';
// import { htmlSafe } from '@ember/template';

export const TEMPLATES = [
  'default',
  'centeredBody',
  'centeredContent',
  'empty'
] as const;

interface NormalProps {
  className?: string;
}

export type EuiPageTemplateProps = {
  template?: typeof TEMPLATES[number];

  pageBodyProps: NormalProps;
  pageContentProps: NormalProps;
  pageContentBodyProps: NormalProps;
  /**
  //  * Gets passed along to the #EuiBottomBar component if `bottomBar` has contents
  //  */
  bottomBarProps?: EuiButtomBarArgs;
  //  * Stretches or restricts the height to 100% of the parent;
  //  * `true`: scrolls the EuiPageContentBody;
  //  * `noscroll`: removes all scroll ability;
  //  * Only works when `template = 'default | empty'` and breakpoint is `m` and above
  //  */
  fullHeight?: boolean;
  /**
   * Minimum height in which to enforce scrolling
   */
  minHeight?: number;

  restrictWidth?: boolean | number | string;
};

export default class EuiPageTemplate extends Component<EuiPageTemplateProps> {
  // Defaults
  @argOrDefault(false) fullHeight!: boolean;
  @argOrDefault('default') template!: typeof TEMPLATES[number];

  @tracked isWithinBreakpoints = false;

  setIsWithinBreakpoints = (value: boolean) => {
    this.isWithinBreakpoints = value;
  };

  get minHeight() {
    const minHeight = this.args.minHeight ?? 460;
    if (typeof this.args.minHeight === 'number') {
      return `${minHeight}px`;
    }
    return minHeight;
  }

  get restrictWidth() {
    const width = this.args.restrictWidth ?? true;
    if (typeof this.args.restrictWidth === 'number') {
      return `${width}px`;
    }
    return width;
  }

  get classes() {
    return `euiPageTemplate ${this.fullHeightClass}`;
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-fullHeight ' : '';
  }

  get yScrollClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-yScroll ' : '';
  }

  get canFullHeight() {
    return (
      this.isWithinBreakpoints &&
      (this.template === 'default' || this.template === 'empty')
    );
  }

  get pageBodyPropsClass() {
    return `${this.fullHeightClass} ${this.args.pageBodyProps?.className}`;
  }

  get pageContentPropsClass() {
    return `${this.yScrollClass} ${this.args.pageContentProps?.className}`;
  }

  get pageContentBodyPropsClass() {
    return `${this.fullHeightClass} ${this.args.pageContentBodyProps?.className}`;
  }
}
