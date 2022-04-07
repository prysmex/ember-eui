import Component from '@glimmer/component';
import { EuiButtomBarArgs } from '../eui-bottom-bar';
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

export type EuiPageTemplateProps = {
  template?: typeof TEMPLATES[number];
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
};

export default class EuiPageTemplate extends Component<EuiPageTemplateProps> {
  // Defaults
  @argOrDefault(460) minHeight!: number;
  @argOrDefault(false) fullHeight!: boolean;
  @argOrDefault('l') paddingSize!: string;
  @argOrDefault('default') template!: typeof TEMPLATES[number];

  get classes() {
    return 'euiPageTemplate '.concat(this.fullHeightClass);
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-fullHeight ' : '';
  }

  get yScrollClass() {
    return this.fullHeight && this.canFullHeight ? 'eui-yScroll ' : '';
  }

  get canFullHeight() {
    return this.template === 'default' || this.template === 'empty';
  }

  get pageBodyProps() {
    return this.fullHeightClass;
    // ...pageBodyProps,
    // className: classNames(fullHeightClass, pageBodyProps?.className),
  }

  get pageContentProps() {
    return this.yScrollClass;
    // ...pageContentProps,
    // className: classNames(yScrollClass, pageContentProps?.className),
  }

  get pageContentBodyProps() {
    return this.fullHeightClass;
    // ...pageContentBodyProps,
    //className: classNames(fullHeightClass, pageContentBodyProps?.className),
  }
}
