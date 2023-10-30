import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class={{classNames
      componentName="EuiHeaderSectionItem"
      borderSide=(argOrDefault @border "left")
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>
