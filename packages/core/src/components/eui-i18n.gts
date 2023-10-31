import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import type EuiI18n from '../services/eui-i18n';
import Render from './eui-i18n/render';
import typeOf from '../helpers/type-of';
import { notEq } from 'ember-truth-helpers';

import { EnsureSafeComponentHelper } from '@embroider/util';
import type { ComponentLike } from '@glint/template';

import { array } from '@ember/helper';

interface Args {
  tokens?: string[];
  defaults?: string[];
  token?: string;
  default?: string;
  values?: { [key: string]: any };
  i18n?: { mapping: { [key: string]: any }; renderComponent?: ComponentLike };
}

export interface EuiI18nSignature {
  Args: Args;
  Blocks: {
    default: [
      ComponentLike<{
        Args: {
          token: string;
        };
      }>,
      number?,
      any?
    ];
    tokens: [string[]];
  };
}

export default class EuiI18nComponent extends Component<EuiI18nSignature> {
  @service declare euiI18n: EuiI18n;

  get isI18nTokensShape() {
    return this.args.tokens !== null;
  }

  get lookupedTokens() {
    const lookupToken = this.euiI18n._lookupToken;

    if (this.isI18nTokensShape) {
      return this.args.tokens?.map((token, idx) =>
        lookupToken({
          token,
          i18nMapping: this.args.i18n?.mapping,
          valueDefault: this.args.defaults![idx]!
        })
      );
    } else {
      return lookupToken({
        token: this.args.token!,
        i18nMapping: this.args.i18n?.mapping,
        valueDefault: this.args.default!,
        values: this.args.values
      });
    }
  }

  <template>
    {{#let this.lookupedTokens as |result|}}
      {{#if this.isI18nTokensShape}}
        {{#if @i18n.renderComponent}}
          {{yield
            (component
              (EnsureSafeComponentHelper @i18n.renderComponent) tokens=result
            )
          }}
        {{else}}
          {{#each
            (if (notEq (typeOf result) "array") (array result) result)
            as |token index|
          }}
            {{yield (component Render token=token) index result}}
          {{/each}}
        {{/if}}
      {{else}}
        {{#if @i18n.renderComponent}}
          {{yield
            (component
              (EnsureSafeComponentHelper @i18n.renderComponent) tokens=result
            )
          }}
        {{else}}
          {{#each
            (if (notEq (typeOf result) "array") (array result) result)
            as |token index|
          }}
            {{yield (component Render token=token) index result}}
          {{/each}}
        {{/if}}
      {{/if}}
    {{/let}}
  </template>
}
