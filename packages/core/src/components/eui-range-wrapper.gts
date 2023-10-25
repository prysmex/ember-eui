import classNames from '@ember-eui/core/helpers/class-names';

<template>
  <div
    class={{classNames
      "euiRangeWrapper"
      (if @fullWidth "euiRangeWrapper--fullWidth")
      (if @compressed "euiRangeWrapper--compressed")
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>
