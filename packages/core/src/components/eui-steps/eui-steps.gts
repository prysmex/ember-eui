import classNames from '@ember-eui/core/helpers/class-names';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';

<template>
  <div
    class={{classNames "euiSteps" status=(argOrDefault @status "incomplete")}}
    ...attributes
  >
    {{yield}}
  </div>
</template>
