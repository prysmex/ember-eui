import { CommonArgs, keysOf } from '../common';

const sizeToClassNameMap = {
  s: 'euiFormControlLayoutClearButton--small',
  m: null,
};

export const SIZES = keysOf(sizeToClassNameMap);

export type EuiFormControlLayoutClearButtonArgs = CommonArgs &
  HTMLButtonElement & {
    size?: typeof SIZES[number];
  };
