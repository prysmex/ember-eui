import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import { concat } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import EuiCheckbox from '@ember-eui/core/components/eui-checkbox';
import EuiRadio from '@ember-eui/core/components/eui-radio';

<template>
  {{#let (argOrDefault @id (unique-id)) as |id|}}
    <div
      class={{classNames
        "euiPanel euiPanel--borderRadiusMedium euiPanel--plain euiPanel--hasShadow euiPanel--hasBorder euiPanel--flexGrowZero euiSplitPanel euiSplitPanel--row euiCheckableCard"
        (if @checked "euiCheckableCard-isChecked")
        (if @disabled "euiCheckableCard__label-isDisabled")
      }}
    >
      <div
        class={{classNames
          "euiPanel euiPanel--paddingMedium euiPanel--borderRadiusNone euiPanel--subdued euiPanel--noShadow euiPanel--noBorder euiPanel--flexGrowZero euiPanel--isClickable euiSplitPanel__inner"
          (if @checked "euiPanel--primary")
        }}
      >
        {{#if (eq @checkableType "checkbox")}}
          <EuiCheckbox
            @id={{id}}
            @checked={{@checked}}
            disabled={{@disabled}}
            ...attributes
          />
        {{else}}
          <EuiRadio
            @id={{id}}
            @checked={{@checked}}
            disabled={{@disabled}}
            ...attributes
          />
        {{/if}}
      </div>
      <div
        class="euiPanel euiPanel--paddingMedium euiPanel--borderRadiusNone euiPanel--transparent euiPanel--noShadow euiPanel--noBorder euiSplitPanel__inner"
      >
        <label
          class={{classNames
            "euiCheckableCard__label"
            (if @disabled "euiCheckableCard__label-isDisabled")
          }}
          for={{id}}
          aria-describedby={{if (has-block "content") (concat id "-details")}}
        >
          {{#if (has-block "label")}}
            {{yield to="label"}}
          {{else}}
            {{@label}}
          {{/if}}
        </label>

        {{#if (has-block "content")}}

          {{! Empty div for left side background color only }}

          <div id={{concat id "-details"}} class="euiCheckableCard__children">
            {{yield to="content"}}
          </div>

        {{/if}}

      </div>
    </div>
  {{/let}}
</template>
