import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

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
