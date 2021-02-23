import { CommonArgs } from '../common';

export type EuiRangeSliderArgs = HTMLInputElement &
  CommonArgs & {
    id?: string;
    name?: string;
    min: number;
    max: number;
    step?: number;
    compressed?: boolean;
    hasFocus?: boolean;
    showRange?: boolean;
    showTicks?: boolean;
    disabled?: boolean;
    tabIndex?: number;
    onChange?: InputEvent;
  };
