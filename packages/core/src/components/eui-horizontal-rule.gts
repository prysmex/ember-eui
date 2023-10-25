import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';

<template>
  <hr
    class={{classNames
      componentName="EuiHorizontalRule"
      margin=(argOrDefault @margin "l")
      size=(argOrDefault @size "full")
    }}
    ...attributes
  />
</template>
