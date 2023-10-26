import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  <span
    class={{classNames
      componentName="EuiNotificationBadge"
      size=(argOrDefault @size "s")
      color=(argOrDefault @color "accent")
    }}
    ...attributes
  >
    {{yield}}
  </span>
</template>
