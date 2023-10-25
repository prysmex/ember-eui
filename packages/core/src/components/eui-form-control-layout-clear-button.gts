import classNames from '@ember-eui/core/helpers/class-names';
import EuiIcon from '@ember-eui/core/components/eui-icon';

import { CommonArgs, keysOf } from '@ember-eui/core/components/common';

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
