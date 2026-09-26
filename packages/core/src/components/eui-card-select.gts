import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiButtonEmptySignature } from './eui-button-empty';

export type EuiCardSelectProps = {
  /**
   * Is in the selected state: shows a check icon, the "Selected" text and
   * the `success` color.
   */
  isSelected?: boolean;
  /** Disables the button and shows "Unavailable". */
  isDisabled?: boolean;
  /** Id of the button (EuiCard sets one). */
  buttonId?: string;
  /**
   * `EuiButtonEmpty` color. Defaults to `'success'` when selected, `'text'`
   * otherwise.
   */
  color?: EuiButtonEmptySignature['Args']['color'];
  /** Shows a spinner in the button. */
  isLoading?: EuiButtonEmptySignature['Args']['isLoading'];
  /** Makes the button a link. */
  href?: EuiButtonEmptySignature['Args']['href'];
  /** Side of the check icon. */
  iconSide?: EuiButtonEmptySignature['Args']['iconSide'];
  /** Removes the button's padding on `'left'`, `'right'` or `'both'` sides. */
  flush?: EuiButtonEmptySignature['Args']['flush'];
  /** `type` of the button. */
  type?: EuiButtonEmptySignature['Args']['type'];
  /** Called when the button (or the whole card, in EuiCard) is clicked; toggle `isSelected` here. */
  onClick?: (e: MouseEvent) => void;
};

export function euiCardSelectableColor(
  color: string | undefined,
  isSelected: boolean | undefined
): string {
  let calculatedColor;

  if (color) {
    calculatedColor = color;
  } else if (isSelected) {
    calculatedColor = 'success';
  } else {
    calculatedColor = 'text';
  }

  return calculatedColor;
}

export interface EuiCardSelectSignature {
  Element: EuiButtonEmptySignature['Element'];
  Args: EuiCardSelectProps;
  Blocks: {
    default: [];
  };
}

export default class EuiCardSelectComponent extends Component<EuiCardSelectSignature> {
  get selectColorClass() {
    return `euiCardSelect--${euiCardSelectableColor(
      this.args.color,
      this.args.isSelected
    )}`;
  }

  <template>
    <EuiButtonEmpty
      class={{classNames this.selectColorClass componentName="EuiCardSelect"}}
      id={{@buttonId}}
      @color={{argOrDefault @color "text"}}
      @size="xs"
      @isDisabled={{@isDisabled}}
      @iconType={{if @isSelected "check" undefined}}
      @isLoading={{@isLoading}}
      @href={{@href}}
      @iconSide={{@iconSide}}
      @flush={{@flush}}
      @type={{@type}}
      role="switch"
      aria-checked={{if @isSelected "true" "false"}}
      {{on "click" (optional @onClick)}}
      ...attributes
    >
      {{#if (has-block)}}
        {{yield}}
      {{else if @isSelected}}
        Selected
      {{else if @isDisabled}}
        Unavailable
      {{else}}
        Select
      {{/if}}
    </EuiButtonEmpty>
  </template>
}
