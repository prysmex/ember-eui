import classNames from '@ember-eui/core/helpers/class-names';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';

<template>
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
