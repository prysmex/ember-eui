import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { eq } from 'ember-truth-helpers';

import setBodyClass from '../-private/set-body-class.ts';
import classNames from '../helpers/class-names.ts';

interface EuiOverlayMaskArgs {
  /** Called when the mask itself (not its content) is clicked. */
  onClick?: (e: Event) => void;
  /**
   * Whether the mask covers the page header (`'above'`) or leaves it
   * visible (`'below'`). Defaults to `'above'`.
   */
  headerZindexLocation?: 'above' | 'below';
}

/**
 * A dark overlay covering the page, rendered in a portal, e.g. behind a
 * modal. Prevents scrolling the page while shown.
 */
export interface EuiOverlayMaskSignature {
  Element: HTMLDivElement;
  Args: EuiOverlayMaskArgs;
  Blocks: {
    /** Content shown above the mask. */
    default: [];
  };
}

export default class EuiOverlayMaskComponent extends Component<EuiOverlayMaskSignature> {
  @tracked overlayMaskNode: HTMLDivElement | undefined;

  destinationElement = document.body;

  @action
  onClick(e: MouseEvent) {
    if (e.target === this.overlayMaskNode) {
      this.args.onClick?.(e);
    }
  }

  @action
  setOverlayMaskNode(node: HTMLDivElement) {
    this.overlayMaskNode = node;
  }

  willDestroy(): void {
    super.willDestroy();

    this.overlayMaskNode = undefined;
  }

  <template>
    {{(setBodyClass "euiBody-hasOverlayMask")}}
    {{#in-element this.destinationElement insertBefore=null}}
      <div
        class={{classNames
          "euiOverlayMask"
          (unless
            (eq @headerZindexLocation "below")
            "euiOverlayMask--aboveHeader"
            "euiOverlayMask--belowHeader"
          )
        }}
        {{didInsert this.setOverlayMaskNode}}
        {{! template-lint-disable }}
        {{on "click" this.onClick}}
        ...attributes
      >
        {{yield}}
      </div>
    {{/in-element}}
  </template>
}
