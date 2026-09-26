import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { service } from '@ember/service';

import { notEq } from 'ember-truth-helpers';

import typeOf from '../helpers/type-of.ts';
import Render from './eui-i18n/render.gts';

import type EuiI18n from '../services/eui-i18n';
import type { WithBoundArgs } from '@glint/template';

interface Args {
  /** @deprecated Has no effect, use one `EuiI18n` per token. */
  tokens?: string[];
  /** @deprecated Has no effect. */
  defaults?: string[];
  /** Translation key, e.g. `'euiComboBox.noMatchesMessage'`. */
  token?: string;
  /** Text used when the token has no translation; may contain `{placeholders}`. */
  default?: string;
  /** Values for the `{placeholders}` in the text. */
  values?: { [key: string]: any };
  /**
   * Translations for this instance, `{ mapping: { token: 'text' } }`, and
   * an optional component to render the text with.
   */
  i18n?: { mapping: { [key: string]: any }; renderComponent?: typeof Render };
}

/**
 * Looks up a translated string in the `euiI18n` service (see the i18n docs
 * page) and yields a component rendering it.
 */
export interface EuiI18nSignature {
  Args: Args;
  Blocks: {
    /** Yields a component rendering the text: `as |Text|` → `<Text />`. */
    default: [WithBoundArgs<typeof Render, 'token'>];
  };
}

export default class EuiI18nComponent extends Component<EuiI18nSignature> {
  @service declare euiI18n: EuiI18n;

  get lookupToken() {
    const lookupToken = this.euiI18n._lookupToken;

    return lookupToken({
      token: this.args.token!,
      i18nMapping: this.args.i18n?.mapping,
      valueDefault: this.args.default!,
      values: this.args.values
    });
  }

  get customComponent(): typeof Render | undefined {
    return this.args.i18n?.renderComponent;
  }

  <template>
    {{#let this.lookupToken as |result|}}
      {{#if this.customComponent}}
        {{#each
          (if (notEq (typeOf result) "array") (array result) result)
          as |token|
        }}
          {{yield (component this.customComponent token=token)}}
        {{/each}}
      {{else}}
        {{#each
          (if (notEq (typeOf result) "array") (array result) result)
          as |token|
        }}
          {{yield (component Render token=token)}}
        {{/each}}
      {{/if}}
    {{/let}}
  </template>
}
