import Component from '@glimmer/component';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiButtonEmpty from './eui-button-empty.gts';

export type EuiCardSelectProps = {
  /**
   * Is in the selected state
   */
  isSelected?: boolean;
  isDisabled?: boolean;
  color?: string;
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

export default class EuiCardSelectComponent extends Component<EuiCardSelectProps> {
  get selectColorClass() {
    return `euiCardSelect--${euiCardSelectableColor(
      this.args.color,
      this.args.isSelected
    )}`;
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
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
