import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import { and, eq } from 'ember-truth-helpers';
import EuiButtonGroupButton from '@ember-eui/core/components/eui-button-group-button';
import { guidFor } from '@ember/object/internals';
import { get } from '@ember/object';

<template>
  {{#let
    (argOrDefault @buttonSize "s")
    (argOrDefault @color "text")
    (argOrDefault @isFullWidth false)
    (argOrDefault @isDisabled false)
    (argOrDefault @type "single")
    as |buttonSize color isFullWidth isDisabled type|
  }}
    {{#let
      (if (and (eq buttonSize "compressed") (eq color "ghost")) "text" color)
      (eq type "single")
      as |resolvedColor typeIsSingle|
    }}

      <fieldset
        class={{classNames
          "euiButtonGroup"
          (if isFullWidth "euiButtonGroup--fullWidth")
          (if isDisabled "euiButtonGroup--fullWidth")
          @className
          componentName="EuiButtonGroup"
          size=(argOrDefault buttonSize "s")
          color=resolvedColor
        }}
        disabled={{isDisabled}}
        ...attributes
      >
        <legend {{screen-reader-only}}>{{@legend}}</legend>
        <div class="euiButtonGroup__buttons">
          {{#let (argOrDefault @name (guidFor)) as |name|}}
            {{#each @options as |option|}}
              <EuiButtonGroupButton
                @name={{name}}
                @isDisabled={{if
                  (not-eq option.isDisabled undefined)
                  option.isDisabled
                  isDisabled
                }}
                @element={{if typeIsSingle "label" "button"}}
                @isSelected={{if
                  typeIsSingle
                  (eq option.id @idSelected)
                  (get @idToSelectedMap option.id)
                }}
                @color={{resolvedColor}}
                @size={{buttonSize}}
                @isIconOnly={{@isIconOnly}}
                @onChange={{@onChange}}
                @iconType={{option.iconType}}
                @value={{option.value}}
                @label={{option.label}}
                @id={{option.id}}
                @isLoading={{option.isLoading}}
                @iconSide={{option.iconSide}}
                @iconSize={{option.iconSize}}
                @textClasses={{option.textClasses}}
                @contentClasses={{option.contentClasses}}
                @iconClasses={{option.iconClasses}}
                @type={{option.type}}
                class={{option.className}}
                aria-label={{option.aria-label}}
              />
            {{/each}}
          {{/let}}
        </div>
      </fieldset>
    {{/let}}
  {{/let}}
</template>
