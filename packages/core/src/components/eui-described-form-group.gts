import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiFlexGroup from './eui-flex-group';
import EuiFlexItem from './eui-flex-item';
import EuiText from './eui-text';
import EuiTitle from './eui-title';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    role="group"
    class={{classNames
      "euiDescribedFormGroup"
      (if @fullWidth "euiDescribedFormGroup--fullWidth")
    }}
    ...attributes
  >
    <EuiFlexGroup @gutterSize={{argOrDefault @gutterSize "l"}}>
      <EuiFlexItem @grow={{@descriptionFlexItemProps.grow}}>
        <EuiTitle
          class="euiDescribedFormGroup__title"
          @size={{@titleSize}}
          @tagName={{@titleTagName}}
        >
          {{yield to="title"}}
        </EuiTitle>
        <EuiText
          class="euiDescribedFormGroup__description"
          @size="s"
          @color="subdued"
        >
          {{yield to="description"}}
        </EuiText>
      </EuiFlexItem>
      <EuiFlexItem
        class={{classNames
          "euiDescribedFormGroup__fields"
          componentName="EuiDescribedFormGroup"
          paddingSize=(argOrDefault @titleSize "xs")
        }}
        @grow={{@fieldFlexItemProps.grow}}
      >
        {{yield}}
      </EuiFlexItem>
    </EuiFlexGroup>
  </div>
</template>
