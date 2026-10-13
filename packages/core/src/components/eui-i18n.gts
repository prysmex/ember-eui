import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { service } from '@ember/service';

import { notEq } from 'ember-truth-helpers';

import typeOf from '../helpers/type-of.ts';
import Render from './eui-i18n/render.gts';

import type EuiI18n from '../services/eui-i18n';
import type { WithBoundArgs } from '@glint/template';

interface Args {
  /**
   * Looks up several tokens at once (instead of `@token`), with their
   * texts in `@defaults` at the same positions. The block is yielded once
   * with an array of the texts (upstream's `tokens`/`defaults`).
   */
  tokens?: string[];
  /** Texts used when a token of `@tokens` has no translation. */
  defaults?: string[];
  /** Translation key, e.g. `'euiComboBox.noMatchesMessage'`. */
  token?: string;
  /** Text used when the token has no translation; may contain `{placeholders}`. */
  default?: string;
  /**
   * Values for the `{placeholders}` in the text. A value can be text, a
   * number, or a component (rendered in place of the placeholder, e.g.
   * `(component EuiLink href="/")`).
   */
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
    /**
     * With `@token`, yields a component rendering the text: `as |Text|` →
     * `<Text />`. It renders component values in place, or yields the text
     * (a part of it, when the text has component values) to its block.
     * With `@tokens`, yields once an array with the text of each token.
     */
    default: [WithBoundArgs<typeof Render, 'token'>];
  };
}

export default class EuiI18nComponent extends Component<EuiI18nSignature> {
  @service declare euiI18n: EuiI18n;

  lookup(token: string, valueDefault: string) {
    return this.euiI18n._lookupToken({
      token,
      i18nMapping: this.args.i18n?.mapping,
      valueDefault,
      values: this.args.values
    });
  }

  get lookupToken() {
    return this.lookup(this.args.token!, this.args.default!);
  }

  /** Upstream's `tokens`/`defaults` shape: the text of each token. */
  get lookupTokens() {
    const defaults = this.args.defaults ?? [];

    return this.args.tokens!.map((token, index) =>
      this.lookup(token, defaults[index]!)
    );
  }

  get customComponent(): typeof Render | undefined {
    return this.args.i18n?.renderComponent;
  }

  <template>
    {{#if @tokens}}
      {{! `@tokens` yields an array instead of the component. }}
      {{! @glint-expect-error }}
      {{yield this.lookupTokens}}
    {{else}}
    {{#let this.lookupToken as |result|}}
      {{#if this.customComponent}}
        {{~#each
          (if (notEq (typeOf result) "array") (array result) result)
          as |token|
        ~}}
          {{yield (component this.customComponent token=token)}}
        {{~/each~}}
      {{else}}
        {{~#each
          (if (notEq (typeOf result) "array") (array result) result)
          as |token|
        ~}}
          {{yield (component Render token=token)}}
        {{~/each~}}
      {{/if}}
    {{/let}}
    {{/if}}
  </template>
}
