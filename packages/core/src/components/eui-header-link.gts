import classNames from '../helpers/class-names';
import EuiButtonEmpty from './eui-button-empty.gts';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <EuiButtonEmpty
    class={{classNames "euiHeaderLink" (if @isActive "euiHeaderLink-isActive")}}
    @color={{if @isActive "primary" "text"}}
    @href={{@href}}
    @isLoading={{@isLoading}}
    @isDisabled={{@isDisabled}}
    @target={{@target}}
    @iconType={{@iconType}}
    @iconSide={{@iconSide}}
    @iconClasses={{@iconClasses}}
    @textClasses={{@textClasses}}
    ...attributes
  >
    {{yield}}
  </EuiButtonEmpty>
</template>
