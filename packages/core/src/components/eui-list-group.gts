import inlineStyles from '@ember-eui/core/helpers/inline-styles';
import { and } from 'ember-truth-helpers';
import { hash } from '@ember/helper';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';

<template>
  {{#let
    (if
      (and @maxWidth (not-eq @maxWidth true))
      (inlineStyles
        componentName="EuiListGroup" componentArgs=(hash maxWidth=@maxWidth)
      )
      (hash)
    )
    as |inlineStyles|
  }}
    <ul
      class={{classNames
        (if (eq @maxWidth true) "euiListGroup-maxWidthDefault")
        (if @bordered "euiListGroup-bordered")
        (if @flush "euiListGroup-flush")
        componentName="EuiListGroup"
        gutterSize=(argOrDefault @gutterSize "s")
      }}
      ...attributes
      {{style inlineStyles}}
    >
      {{yield}}
    </ul>
  {{/let}}
</template>
