import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import EuiIcon from '@ember-eui/core/components/eui-icon';

<template>
  <div
    class={{classNames
      componentName="EuiHealth"
      textSize=(argOrDefault @textSize "m")
    }}
    ...attributes
  >
    <div
      class="euiFlexGroup euiFlexGroup--gutterExtraSmall euiFlexGroup--alignItemsCenter euiFlexGroup--directionRow"
    >
      <div class="euiFlexItem euiFlexItem--flexGrowZero">
        <EuiIcon @type="dot" @color={{@color}} />
      </div>
      <div class="euiFlexItem euiFlexItem--flexGrowZero">
        {{yield}}
      </div>
    </div>
  </div>
</template>
