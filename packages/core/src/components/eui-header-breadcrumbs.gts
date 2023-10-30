import EuiBreadcrumbs from './eui-breadcrumbs';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <EuiBreadcrumbs
    @max={{4}}
    @truncate={{true}}
    @breadcrumbs={{@breadcrumbs}}
    class="euiHeaderBreadcrumbs"
    ...attributes
  />
</template>
