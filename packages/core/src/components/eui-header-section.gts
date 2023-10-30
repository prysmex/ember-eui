import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class={{classNames
      componentName="EuiHeaderSection"
      alignItems=(argOrDefault @side "left")
      grow=(argOrDefault @grow false)
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>
