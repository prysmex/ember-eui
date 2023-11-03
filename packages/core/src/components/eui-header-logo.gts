import argOrDefault from '../helpers/arg-or-default';
import EuiIcon from './eui-icon.gts';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <a class="euiHeaderLogo" href={{@href}} target={{@target}} ...attributes>
    <EuiIcon
      aria-label={{@iconTitle}}
      @iconClasses="euiHeaderLogo__icon"
      @size="l"
      @type={{argOrDefault @iconType "logoElastic"}}
    />
    {{#if (has-block)}}
      <span class="euiHeaderLogo__text">
        {{yield}}
      </span>
    {{/if}}
  </a>
</template>
