import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class={{classNames "euiSteps" status=(argOrDefault @status "incomplete")}}
    ...attributes
  >
    {{yield}}
  </div>
</template>
