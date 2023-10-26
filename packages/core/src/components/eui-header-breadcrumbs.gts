import EuiBreadcrumbs from './eui-breadcrumbs';

<template>
  <EuiBreadcrumbs
    @max={{4}}
    @truncate={{true}}
    @breadcrumbs={{@breadcrumbs}}
    class="euiHeaderBreadcrumbs"
    ...attributes
  />
</template>
