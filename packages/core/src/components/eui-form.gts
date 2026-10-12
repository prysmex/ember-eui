import Component from '@glimmer/component';
import { provide } from 'ember-provide-consume-context';
import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';

import { EUI_FORM_CONTEXT } from '../-private/eui-form-context.ts';
import EuiCallOut from './eui-call-out.gts';
import EuiSpacer from './eui-spacer.gts';

import type { EuiFormContext } from '../-private/eui-form-context.ts';

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
     * Default `@fullWidth` of every EuiFormRow and EuiDescribedFormGroup
     * inside the form (their own `@fullWidth` wins). Defaults to `false`.
     */
    fullWidth?: boolean;
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

export default class EuiForm extends Component<EuiFormSignature> implements EuiFormContext {
  @provide(EUI_FORM_CONTEXT)
  get formContext(): EuiFormContext {
    return this;
  }

  get defaultFullWidth(): boolean {
    return this.args.fullWidth ?? false;
  }

  get errors(): string[] {
    const { error } = this.args;
    if (Array.isArray(error)) return error;
    return this.args.array && error !== undefined ? [error] : [];
  }

  get showsCallout(): boolean {
    return (
      (this.args.invalidCallout ?? 'above') === 'above' &&
      this.errors.length > 0 &&
      Boolean(this.args.isInvalid)
    );
  }

  <template>
    {{#let (element (if (eq @tagName "form") "form" "div")) as |Tag|}}
      <Tag class="euiForm" ...attributes>
        {{#if this.showsCallout}}
          <EuiCallOut
            class="euiForm__errors"
            role="alert"
            aria-live="assertive"
            @title={{argOrDefault @errorTitle "Please correct the fields"}}
            @color="danger"
          >
            <:body>
              <ul>
                {{#each this.errors as |error|}}
                  <li class="euiForm__error">
                    {{#if (has-block "error")}}
                      {{yield error to="error"}}
                    {{else}}
                      {{error}}
                    {{/if}}
                  </li>
                {{/each}}
              </ul>
            </:body>
          </EuiCallOut>
          <EuiSpacer @size="m" />
        {{/if}}
        {{#if (has-block "content")}}
          {{yield to="content"}}
        {{else}}
          {{yield}}
        {{/if}}
      </Tag>
    {{/let}}
  </template>
}
