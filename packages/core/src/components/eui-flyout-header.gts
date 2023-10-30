import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class={{classNames
      "euiFlyoutHeader"
      (if @hasBorder "euiFlyoutHeader--hasBorder")
    }}
    ...attributes
  >
    {{yield}}
  </div>
</template>
