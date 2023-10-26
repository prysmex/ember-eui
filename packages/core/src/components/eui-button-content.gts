import { eq } from 'ember-truth-helpers';
import EuiLoadingSpinner from './eui-loading-spinner';
import EuiIcon from './eui-icon';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

<template>
  <span
    class={{classNames
      "euiButtonContent"
      (if (eq @iconSide "right") "euiButtonContent--iconRight")
    }}
    ...attributes
  >
    {{#if @isLoading}}
      <EuiLoadingSpinner
        class="euiButtonContent__spinner"
        @size={{argOrDefault @iconSize "m"}}
      />
    {{else if @iconType}}
      <EuiIcon
        @iconClasses="euiButtonContent__icon {{@iconClasses}}"
        @type={{@iconType}}
        @size={{argOrDefault @iconSize "m"}}
        @useSvg={{@useSvg}}
        @useComponent={{@useComponent}}
        @color="inherit"
      />
    {{/if}}
    <span class={{@textClasses}}>
      {{yield}}
    </span>
  </span>
</template>
