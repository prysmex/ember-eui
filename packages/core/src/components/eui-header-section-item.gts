import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';

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
