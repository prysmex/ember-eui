import { IconType } from '../eui-icon';
import { DistributiveOmit } from '../common';
import { EuiFormControlLayoutCustomIconArgs } from '../eui-form-control-layout-custom-icon/types';
import { EuiFormControlLayoutClearButtonArgs } from '../eui-form-control-layout-clear-button/types';

export const ICON_SIDES: ['left', 'right'] = ['left', 'right'];

type IconShape = DistributiveOmit<EuiFormControlLayoutCustomIconArgs, 'type' | 'iconRef'> & {
  type: IconType;
  side?: typeof ICON_SIDES[number];
  ref?: EuiFormControlLayoutCustomIconArgs['iconRef'];
};

export interface EuiFormControlLayoutIconsArgs {
  icon?: IconType | IconShape;
  clear?: EuiFormControlLayoutClearButtonArgs;
  isLoading?: boolean;
  compressed?: boolean;
}
