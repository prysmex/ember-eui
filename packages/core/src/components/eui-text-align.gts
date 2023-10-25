import classNames from '@ember-eui/core/helpers/class-names';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';

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
