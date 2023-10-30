<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    class="ember-power-select-group"
    aria-disabled={{if @group.disabled "true"}}
    ...attributes
  >
    <div
      class="ember-power-select-group-name euiComboBoxTitle"
    >{{@group.groupName}}</div>
    {{yield}}
  </div>
</template>
