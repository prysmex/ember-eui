import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <span
    class={{classNames
      componentName="EuiLoadingSpinner"
      size=(arg-or-default @size "m")
    }}
    ...attributes
  ></span>
</template>
