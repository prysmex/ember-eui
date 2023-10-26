import classNames from '../helpers/class-names';

<template>
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
