import TextBlock from './text-block';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <TextBlock
    @tagName={{argOrDefault @tagName "h2"}}
    class={{classNames
      componentName="EuiTitle"
      size=(argOrDefault @size "m")
      textTransform=@textTransform
    }}
    ...attributes
  >
    {{yield}}
  </TextBlock>
</template>
