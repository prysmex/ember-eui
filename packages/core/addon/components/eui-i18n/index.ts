import Component from '@glimmer/component';

//@ts-ignore
import { i18n, I18nShape, lookupToken } from '@ember-eui/core/i18n';

interface Args {
  tokens?: string[];
  defaults?: string[];
  token?: string;
  default?: string;
  values?: { [key: string]: any };
  i18n?: I18nShape;
}

export default class EuiI18nComponent extends Component<Args> {
  get isI18nTokensShape() {
    return this.args.tokens != null;
  }

  get i18n() {
    return this.args.i18n || i18n;
  }

  get lookupedTokens() {
    if (this.isI18nTokensShape) {
      return this.args.tokens?.map((token, idx) =>
        lookupToken({
          token,
          i18nMapping: i18n.mapping,
          valueDefault: this.args.defaults![idx]
        })
      );
    } else {
      return lookupToken({
        token: this.args.token!,
        i18nMapping: i18n.mapping,
        valueDefault: this.args.default!,
        values: this.args.values
      });
    }
  }
}
