import { EuiIconArgs, IconType } from '../eui-icon';
import { CommonArgs, ExclusiveUnion } from '../common';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs &
  ExclusiveUnion<Omit<HTMLButtonElement, 'type'>, HTMLSpanElement> & {
    type: IconType;
    size?: EuiIconArgs['size'];
    iconRef?:
      | string
      | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
  };
