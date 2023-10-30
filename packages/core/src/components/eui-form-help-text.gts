<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div class="euiFormHelpText" id={{@id}} ...attributes>
    {{yield}}
  </div>
</template>
