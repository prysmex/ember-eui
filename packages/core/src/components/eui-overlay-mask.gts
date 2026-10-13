import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { modifier } from 'ember-modifier';

import setBodyClass from '../-private/set-body-class.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiOverlayMaskStyles } from '../utils/eui/utilities.ts';

interface EuiOverlayMaskArgs {
  /** Called when the mask itself (not its content) is clicked. */
  onClick?: (e: MouseEvent) => void;
  /**
   * Whether the mask covers the page header (`'above'`, z-index
   * `levels.mask`) or leaves it visible (`'below'`, z-index
   * `levels.maskBelowHeader`, starting below `--euiFixedHeadersOffset`).
   * Defaults to `'above'`.
   */
  headerZindexLocation?: 'above' | 'below';
  /** Fades the mask in. Defaults to `true`. */
  hasAnimation?: boolean;
  /** Called with the mask element once it is rendered. */
  maskRef?: (element: HTMLDivElement) => void;
}

/**
 * A dark overlay covering the page, rendered at the end of `<body>`, e.g.
 * behind a modal. Prevents scrolling the page while shown.
 */
export interface EuiOverlayMaskSignature {
  Element: HTMLDivElement;
  Args: EuiOverlayMaskArgs;
  Blocks: {
    /** Content shown above the mask. */
    default: [];
  };
}

const callWith = modifier(
  (element: HTMLDivElement, [callback]: [((el: HTMLDivElement) => void)?]) => {
    callback?.(element);
  }
);

export default class EuiOverlayMaskComponent extends Component<EuiOverlayMaskSignature> {
  destinationElement = document.body;

  get headerZindexLocation() {
    return this.args.headerZindexLocation === 'below' ? 'below' : 'above';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiOverlayMaskStyles);
    return `euiOverlayMask ${euiClass(
      context,
      styles.euiOverlayMask,
      styles[`${this.headerZindexLocation}Header`],
      this.args.hasAnimation === false ? styles.noAnimation : undefined
    )}`;
  }

  /** Upstream renders a global `body { overflow: hidden }`; a ref-counted body class here. */
  @cached
  get bodyClasses() {
    return `euiBody-hasOverlayMask ${euiClass(getEuiThemeContext(this), {
      overflow: 'hidden'
    })}`;
  }

  onClick = (e: MouseEvent) => {
    if (e.target === e.currentTarget) this.args.onClick?.(e);
  };

  <template>
    {{(setBodyClass this.bodyClasses)}}
    {{#in-element this.destinationElement insertBefore=null}}
      <div
        class={{this.classes}}
        data-relative-to-header={{this.headerZindexLocation}}
        {{callWith @maskRef}}
        {{! template-lint-disable no-invalid-interactive }}
        {{on "click" this.onClick}}
        ...attributes
      >
        {{yield}}
      </div>
    {{/in-element}}
  </template>
}
