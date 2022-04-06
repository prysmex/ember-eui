import Component from '@glimmer/component';
import { EuiButtomBarArgs } from '../eui-bottom-bar';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';

export const TEMPLATES = [
  'default',
  'centeredBody',
  'centeredContent',
  'empty',
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
  @argOrDefault('default') template!: typeof TEMPLATES[number];

  get classes() {
    return 'euiPageTemplate '.concat(this.fullHeightClass);
  }

  get fullHeightClass() {
    return this.fullHeight && this.canFullHeight
      ? 'eui-fullHeight eui-yScroll'
      : '';
  }

  get canFullHeight() {
    return this.template === 'default' || this.template === 'empty';
  }
}
