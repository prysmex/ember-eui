import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
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
