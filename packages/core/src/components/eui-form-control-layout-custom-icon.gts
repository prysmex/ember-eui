import EuiIcon from './eui-icon';
import { on } from '@ember/modifier';

import { EuiIconArgs, IconType } from './eui-icon';
import { CommonArgs, ExclusiveUnion } from './common';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs &
  ExclusiveUnion<Omit<HTMLButtonElement, 'type'>, HTMLSpanElement> & {
    type: IconType;
    size?: EuiIconArgs['size'];
    iconRef?:
      | string
      | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
  };

<template>
  {{#if @onClick}}
    <button
      type="button"
      class="euiFormControlLayoutCustomIcon euiFormControlLayoutCustomIcon--clickable"
      ...attributes
      {{on "click" @onClick}}
    >
      <EuiIcon
        @iconClasses="euiFormControlLayoutCustomIcon__icon"
        @type={{@type}}
        @size={{@size}}
        aria-hidden="true"
      />
    </button>
  {{else}}
    <span class="euiFormControlLayoutCustomIcon" ...attributes>
      <EuiIcon
        @iconClasses="euiFormControlLayoutCustomIcon__icon"
        @type={{@type}}
        @size={{@size}}
        aria-hidden="true"
      />
    </span>
  {{/if}}
</template>