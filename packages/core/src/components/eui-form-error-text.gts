<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div class="euiFormErrorText" aria-live="polite" ...attributes>
    {{yield}}
  </div>
</template>
