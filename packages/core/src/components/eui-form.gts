import argOrDefault from '../helpers/arg-or-default';
import isArray from 'ember-truth-helpers/helpers/is-array';
import { array } from '@ember/helper';
import { eq, and, gt } from 'ember-truth-helpers';
import EuiCallOut from './eui-call-out';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  {{#let
    (argOrDefault @invalidCallout "above")
    (if (isArray @error) @error (if @array (array @error)))
    as |invalidCallout errors|
  }}
    {{#if (eq @tagName "form")}}
      <form class="euiForm" ...attributes>
        {{#if
          (and (eq invalidCallout "above") (gt errors.length 0) @isInvalid)
        }}
          <EuiCallOut
            class="euiForm__errors"
            role="alert"
            aria-live="assertive"
            @title={{argOrDefault @errorTitle "Please correct the fields"}}
            @color="danger"
          >
            <:body>
              {{#each errors as |error|}}
                <li class="euiForm__error">
                  {{#if (has-block "error")}}
                    {{yield error to="error"}}
                  {{else}}
                    {{error}}
                  {{/if}}
                </li>
              {{/each}}
            </:body>
          </EuiCallOut>
        {{/if}}
        {{#if (has-block "content")}}
          {{yield to="content"}}
        {{else}}
          {{yield}}
        {{/if}}
      </form>
    {{else}}
      <div class="euiForm" ...attributes>
        {{#if
          (and (eq invalidCallout "above") (gt errors.length 0) @isInvalid)
        }}
          <EuiCallOut
            class="euiForm__errors"
            role="alert"
            aria-live="assertive"
            @title={{argOrDefault @errorTitle "Please correct the fields"}}
            @color="danger"
          >
            <:body>
              {{#each errors as |error|}}
                <li class="euiForm__error">
                  {{#if (has-block "error")}}
                    {{yield error to="error"}}
                  {{else}}
                    {{error}}
                  {{/if}}
                </li>
              {{/each}}
            </:body>
          </EuiCallOut>
        {{/if}}
        {{#if (has-block "content")}}
          {{yield to="content"}}
        {{else}}
          {{yield}}
        {{/if}}
      </div>
    {{/if}}
  {{/let}}
</template>
