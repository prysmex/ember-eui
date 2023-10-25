import EuiBreadcrumbs from '@ember-eui/core/components/eui-breadcrumbs';

<template>
  <EuiBreadcrumbs
    @max={{4}}
    @truncate={{true}}
    @breadcrumbs={{@breadcrumbs}}
    class="euiHeaderBreadcrumbs"
    ...attributes
  />
</template>
