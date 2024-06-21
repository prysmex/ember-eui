import { array } from '@ember/helper';

import { and, eq, gt } from 'ember-truth-helpers';
import isArray from 'ember-truth-helpers/helpers/is-array';

import argOrDefault from '../helpers/arg-or-default.ts';
import EuiCallOut from './eui-call-out.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFormSignature {
  Element: HTMLDivElement | HTMLFormElement;
  Args: {
    errorTitle?: string;
    invalidCallout?: 'above' | 'none';
    error?: string | string[];
    isInvalid?: boolean;
    array?: boolean;
    tagName?: 'form' | 'div';
  };
  Blocks: {
    default?: [];
    content?: [];
    error?: [string];
  };
}

const EuiForm: TemplateOnlyComponent<EuiFormSignature> = <template>
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
                    {{!@glint-expect-error}}
                    {{yield error to="error"}}
                  {{else}}
                    {{!@glint-expect-error}}
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
                    {{!@glint-expect-error}}
                    {{yield error to="error"}}
                  {{else}}
                    {{!@glint-expect-error}}
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
</template>;

export default EuiForm;
