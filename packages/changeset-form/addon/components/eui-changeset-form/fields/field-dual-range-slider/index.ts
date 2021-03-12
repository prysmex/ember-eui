import Base, { BaseArgs } from '../base';
import { action } from '@ember/object';

type MinMax = [number, number];

interface EuiChangesetFormFieldDualRangeSliderArgs extends BaseArgs {
  onInput?: (value: MinMax) => void;
}

export default class EuiChangesetFormFieldDualRangeSlider extends Base<EuiChangesetFormFieldDualRangeSliderArgs> {
  form: HTMLFormElement | null = null;

  @action
  handleInput(e: MinMax) {
    this.args.changeset.set(this.args.fieldName, e);

    this.args.onInput?.(e);
  }
}
