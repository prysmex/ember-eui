import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';

/**
 * Keeps its content (an iframe, video, image or map) at a fixed aspect
 * ratio while it takes the available width.
 */
export interface EuiAspectRatioSignature {
  Element: HTMLDivElement;
  Args: {
    /** Width part of the ratio, e.g. `16` for 16:9. */
    width: number;
    /** Height part of the ratio, e.g. `9` for 16:9. */
    height: number;
    /** Maximum width, e.g. `500` (px) or `'50%'`. */
    maxWidth?: number | string;
  };
  Blocks: {
    /** One element that fills the box, e.g. an `<iframe>`. */
    default: [];
  };
}

/**
 * Upstream clones its only child and gives it `aspect-ratio`, `height: auto`,
 * `width: 100%` and `max-width` (logical). Ember cannot clone a block, so the
 * wrapper takes those styles and its content fills it.
 */
export default class EuiAspectRatio extends Component<EuiAspectRatioSignature> {
  @cached
  get classes() {
    const { width, height, maxWidth } = this.args;
    return `euiAspectRatio ${euiClass(getEuiThemeContext(this), {
      boxSizing: 'border-box',
      aspectRatio: `${width} / ${height}`,
      blockSize: 'auto',
      inlineSize: '100%',
      maxInlineSize: typeof maxWidth === 'number' ? `${maxWidth}px` : maxWidth,
      // block, so an inline iframe/img adds no line-box descender space
      '& > *': {
        boxSizing: 'border-box',
        display: 'block',
        inlineSize: '100%',
        blockSize: '100%'
      }
    })}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>{{yield}}</div>
  </template>
}
