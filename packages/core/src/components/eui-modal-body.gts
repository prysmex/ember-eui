<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div class="euiModalBody" ...attributes>
    <div class="euiModalBody__overflow">
      {{yield}}
    </div>
  </div>
</template>
