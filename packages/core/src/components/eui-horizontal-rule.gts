import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <hr
    class={{classNames
      componentName="EuiHorizontalRule"
      margin=(argOrDefault @margin "l")
      size=(argOrDefault @size "full")
    }}
    ...attributes
  />
</template>
