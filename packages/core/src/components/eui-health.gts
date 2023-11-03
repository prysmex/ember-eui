import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';

<template>
  {{! @glint-nocheck: not typesafe yet }}
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
