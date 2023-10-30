import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon';

import { CommonArgs, keysOf } from './common';

const sizeToClassNameMap = {
  s: 'euiFormControlLayoutClearButton--small',
  m: null
};

export const SIZES = keysOf(sizeToClassNameMap);

export type EuiFormControlLayoutClearButtonArgs = CommonArgs &
  HTMLButtonElement & {
    size?: (typeof SIZES)[number];
  };

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <button
    class={{classNames "euiFormControlLayoutClearButton" size=@size}}
    type="button"
    aria-label={{@label}}
    ...attributes
  >
    <EuiIcon
      @iconClasses="euiFormControlLayoutClearButton__icon"
      @type="cross"
    />
  </button>
</template>
