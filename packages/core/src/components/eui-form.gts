import { array } from '@ember/helper';

import { and, eq, gt } from 'ember-truth-helpers';
import isArray from 'ember-truth-helpers/helpers/is-array';

import argOrDefault from '../helpers/arg-or-default.ts';
import EuiCallOut from './eui-call-out.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Wraps a form's rows and shows its errors in a callout. For validation
 * built on it see `@ember-eui/changeset-form` and
 * `@ember-eui/validated-form`.
 */
export interface EuiFormSignature {
  Element: HTMLDivElement | HTMLFormElement;
  Args: {
    /** Title of the errors callout. Defaults to "Please correct the fields". */
    errorTitle?: string;
    /**
     * `'above'` shows `@error` in a callout above the form while
     * `@isInvalid`; `'none'` hides it. Defaults to `'above'`.
     */
    invalidCallout?: 'above' | 'none';
    /**
     * The form's errors, listed in the callout: an array of messages, or a
     * single message with `@array={{true}}`.
     */
    error?: string | string[];
    /** Shows the errors callout (with `@error`). */
    isInvalid?: boolean;
    /** Treats a single string `@error` as a one-item list. */
    array?: boolean;
    /**
     * `'form'` renders a `<form>` (add `{{on "submit" …}}`); `'div'` for
     * forms without native submission. Defaults to `'div'`.
     */
    tagName?: 'form' | 'div';
  };
  Blocks: {
    /** The form's content, usually `EuiFormRow`s and a submit button. */
    default?: [];
    /** Same as the default block. */
    content?: [];
    /** Renders each error in the callout; yields the error. */
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
