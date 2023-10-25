import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import EuiFlexGroup from '@ember-eui/core/components/eui-flex-group';
import EuiFlexItem from '@ember-eui/core/components/eui-flex-item';
import EuiText from '@ember-eui/core/components/eui-text';
import EuiTitle from '@ember-eui/core/components/eui-title';

<template>
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
