import classNames from '@ember-eui/core/helpers/class-names';
import EuiBadge from '@ember-eui/core/components/eui-badge';
import { optional } from 'ember-composable-helpers/helpers/optional';
import { fn } from '@ember/helper';
import { hash } from '@ember/helper';

<template>
  {{#let
    (classNames
      "euiComboBoxPill" (if @asPlainText "euiComboBoxPill--plainText")
    )
    (optional @onClose)
    as |classes onClose|
  }}
    {{#if @onClose}}
      <EuiBadge
        class={{classes}}
        @closeButtonProps={{hash
          tabIndex=-1
          dataSelectedIconIndex=@dataSelectedIconIndex
        }}
        @color={{@color}}
        @iconOnClick={{fn onClose @option}}
        @iconOnClickAriaLabel={{@iconOnClickAriaLabel}}
        @iconSide="right"
        @iconType="cross"
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{else if @asPlainText}}
      <span class={{classes}}>
        {{yield}}
      </span>
    {{else}}
      <EuiBadge
        class={{classes}}
        @color={{@color}}
        @closeButtonProps={{hash dataSelectedIconIndex=@dataSelectedIconIndex}}
        ...attributes
      >
        {{yield}}
      </EuiBadge>
    {{/if}}
  {{/let}}
</template>
