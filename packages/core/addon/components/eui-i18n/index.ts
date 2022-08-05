import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import type EuiI18n from 'core/services/eui-i18n';

interface Args {
  tokens?: string[];
  defaults?: string[];
  token?: string;
  default?: string;
  values?: { [key: string]: any };
  i18n?: { mapping: { [key: string]: any } };
}

export default class EuiI18nComponent extends Component<Args> {
  @service declare euiI18n: EuiI18n;

  get isI18nTokensShape() {
    return this.args.tokens != null;
  }

  get lookupedTokens() {
    const lookupToken = this.euiI18n._lookupToken;

    if (this.isI18nTokensShape) {
      return this.args.tokens?.map((token, idx) =>
        lookupToken({
          token,
          i18nMapping: this.args.i18n?.mapping,
          valueDefault: this.args.defaults![idx]
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
}
