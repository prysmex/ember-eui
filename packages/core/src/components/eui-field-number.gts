import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import validatableControl from '@ember-eui/core/modifiers/validatable-control';

import optional from 'ember-composable-helpers/helpers/optional';
import { and, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from '../helpers/unique-id';
import EuiFormControlLayout from './eui-form-control-layout';

import type { CommonArgs } from './common';
import type { EuiFormControlLayoutArgs } from './eui-form-control-layout/types';
import type { IconType } from './eui-icon';

export type EuiFieldNumberArgs = Omit<
  HTMLInputElement,
  'min' | 'max' | 'readOnly' | 'step'
> &
  CommonArgs & {
    icon?: IconType;
    isInvalid?: boolean;
    fullWidth?: boolean;
    isLoading?: boolean;
    readOnly?: boolean;
    min?: number;
    max?: number;
    /**
     * Specifies the granularity that the value must adhere to.
     * Accepts a `number` or the string `'any'` for no stepping to allow for any value.
     * Defaults to `1`
     */
    step?: number | 'any';
    inputRef?: HTMLInputElement;

    /**
     * Creates an input group with element(s) coming before input.
     * `string` | `Component` or an array of these
     */
    prepend?: EuiFormControlLayoutArgs['prepend'];

    /**
     * Creates an input group with element(s) coming after input.
     * `string` | `Component` or an array of these
     */
    append?: EuiFormControlLayoutArgs['append'];

    /**
     * Completely removes form control layout wrapper and ignores
     * icon, prepend, and append. Best used inside EuiFormControlLayoutDelimited.
     */
    controlOnly?: boolean;

    /**
     * when `true` creates a shorter height input
     */
    compressed?: boolean;
  };

<template>
  {{#let
    (and (argOrDefault @isPrependProvided true) (has-block "prepend"))
    (and (argOrDefault @isAppendProvided true) (has-block "append"))
    (argOrDefault @id (uniqueId))
    as |hasPrepend hasAppend inputId|
  }}
    {{#let
      (classNames
        (if @icon "euiFieldNumber--withIcon")
        (if @fullWidth "euiFieldNumber--fullWidth")
        (if @compressed "euiFieldNumber--compressed")
        (if (or hasPrepend hasAppend) "euiFieldNumber--inGroup")
        (if @isLoading "euiFieldNumber--isLoading")
        "euiFieldNumber"
      )
      as |classes|
    }}
      {{#if @controlOnly}}
        <input
          id={{@id}}
          class={{classes}}
          value={{@value}}
          min={{@min}}
          max={{@max}}
          disabled={{@disabled}}
          step={{@step}}
          type="number"
          ...attributes
          {{validatableControl @isInvalid}}
          {{didInsert (optional @inputRef)}}
        />
      {{else}}
        <EuiFormControlLayout
          @icon={{@icon}}
          @clear={{@clear}}
          @fullWidth={{@fullWidth}}
          @isLoading={{@isLoading}}
          @compressed={{@compressed}}
          @readOnly={{@readOnly}}
          @disabled={{@disabled}}
          @useGroup={{or hasPrepend hasAppend}}
        >
          <:prepend as |prependClasses|>
            {{yield prependClasses to="prepend"}}
          </:prepend>
          <:field>
            <input
              id={{inputId}}
              class={{classes}}
              value={{@value}}
              min={{@min}}
              max={{@max}}
              disabled={{@disabled}}
              step={{@step}}
              type="number"
              ...attributes
              {{validatableControl @isInvalid}}
            />
          </:field>
          <:append as |appendClasses|>
            {{yield appendClasses to="append"}}
          </:append>
        </EuiFormControlLayout>
      {{/if}}
    {{/let}}
  {{/let}}
</template>
