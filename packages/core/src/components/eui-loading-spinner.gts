import classNames from '@ember-eui/core/helpers/class-names';

<template>
  <span
    class={{classNames
      componentName="EuiLoadingSpinner"
      size=(arg-or-default @size "m")
    }}
    ...attributes
  ></span>
</template>
