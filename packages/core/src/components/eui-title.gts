import TextBlock from '@ember-eui/core/components/text-block';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';

<template>
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
