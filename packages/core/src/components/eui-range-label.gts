import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { concat } from '@ember/helper';

<template>
  <label
    class={{classNames
      "euiRangeLabel"
      (concat "euiRangeLabel--" (argOrDefault @side "max"))
      (if @disabled "euiRangeLabel--isDisabled")
    }}
  >
    {{yield}}
  </label>
</template>