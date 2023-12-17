import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiButtonEmpty from './eui-button-empty.gts';

import type { EuiButtonEmptySignature } from './eui-button-empty';

export type EuiCardSelectProps = {
  /**
   * Is in the selected state
   */
  isSelected?: boolean;
  isDisabled?: boolean;
  buttonId?: string;
  color?: EuiButtonEmptySignature['Args']['color'];
  isLoading?: EuiButtonEmptySignature['Args']['isLoading'];
  href?: EuiButtonEmptySignature['Args']['href'];
  iconSide?: EuiButtonEmptySignature['Args']['iconSide'];
  flush?: EuiButtonEmptySignature['Args']['flush'];
  type?: EuiButtonEmptySignature['Args']['type'];
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
      aria-checked={{@isSelected}}
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
