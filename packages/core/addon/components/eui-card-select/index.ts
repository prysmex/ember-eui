import Component from '@glimmer/component';

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
}
