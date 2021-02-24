import { EuiFieldNumberArgs } from '../eui-field-number/types';

export interface EuiRangeInputArgs extends Omit<EuiFieldNumberArgs, 'max' | 'min' | 'value'> {
  autoSize?: boolean;
  digitTolerance: number;
  max: number;
  min: number;
  side?: 'min' | 'max';
  value: string | number;
}
