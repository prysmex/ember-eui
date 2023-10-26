import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

<template>
  <div
    class={{classNames
      componentName="EuiTextAlign"
      textAlign=(argOrDefault @textAlign "left")
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>
