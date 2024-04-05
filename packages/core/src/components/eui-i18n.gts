import Component from '@glimmer/component';
import { array } from '@ember/helper';
import { inject as service } from '@ember/service';
import { ensureSafeComponent } from '@embroider/util';

import { notEq } from 'ember-truth-helpers';

import typeOf from '../helpers/type-of';
import Render from './eui-i18n/render.gts';

import type EuiI18n from '../services/eui-i18n';
import type { WithBoundArgs } from '@glint/template';

interface Args {
  tokens?: string[];
  defaults?: string[];
  token?: string;
  default?: string;
  values?: { [key: string]: any };
  i18n?: { mapping: { [key: string]: any }; renderComponent?: typeof Render };
}

export interface EuiI18nSignature {
  Args: Args;
  Blocks: {
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
    if (!this.args.i18n?.renderComponent) return undefined;

    return ensureSafeComponent(this.args.i18n?.renderComponent, this);
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
