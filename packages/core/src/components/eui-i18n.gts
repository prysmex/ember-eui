import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import type EuiI18n from '../services/eui-i18n';
import Render from './eui-i18n/render';

import { ensureSafeComponent } from '@embroider/util';
import type { WithBoundArgs } from '@glint/template';

import { array } from '@ember/helper';

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
        {{yield (component this.customComponent token=result)}}
      {{else}}
        {{yield (component Render token=result)}}
      {{/if}}
    {{/let}}
  </template>
}
