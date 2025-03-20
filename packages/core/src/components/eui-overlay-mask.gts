import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import setBodyClass from 'ember-set-body-class/helpers/set-body-class';
import { eq } from 'ember-truth-helpers';

import classNames from '../helpers/class-names';

interface EuiOverlayMaskArgs {
  onClick?: (e: Event) => void;
  headerZindexLocation?: 'above' | 'below';
}

export interface EuiOverlayMaskSignature {
  Element: HTMLDivElement;
  Args: EuiOverlayMaskArgs;
  Blocks: {
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
