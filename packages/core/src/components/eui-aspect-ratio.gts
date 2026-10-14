import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

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
  /**
   * The ratio and max width go inline, as upstream's `style`: a class per
   * ratio would stay in the style cache for good.
   */
  get inlineStyle(): Record<string, string> {
    const { width, height, maxWidth } = this.args;
    const inline: Record<string, string> = {
      aspectRatio: `${width} / ${height}`
    };
    if (maxWidth !== undefined) {
      inline['maxInlineSize'] =
        typeof maxWidth === 'number' ? `${maxWidth}px` : maxWidth;
    }
    return inline;
  }

  @cached
  get classes() {
    return `euiAspectRatio ${euiClass(getEuiThemeContext(this), {
      boxSizing: 'border-box',
      blockSize: 'auto',
      inlineSize: '100%',
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
    <div class={{this.classes}} ...attributes {{style this.inlineStyle}}>{{yield}}</div>
  </template>
}
