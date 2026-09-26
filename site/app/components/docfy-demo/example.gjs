import EuiSplitPanelInner from '@ember-eui/core/components/eui-split-panel/inner';

<template>
  <EuiSplitPanelInner
    class="docfy-demo__example"
    @borderRadius="none"
    @hasBorder={{false}}
    @hasShadow={{false}}
    @color="plain"
    @paddingSize="m"
    ...attributes
  >
    {{yield}}
  </EuiSplitPanelInner>
</template>
