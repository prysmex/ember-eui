import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';

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
