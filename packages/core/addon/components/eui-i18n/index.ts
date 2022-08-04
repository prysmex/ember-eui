import Component from '@glimmer/component';
import { inject as service } from '@ember/service';

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
  // @ts-expect-error TODO: type
  @service euiI18n;

  get isI18nTokensShape() {
    return this.args.tokens != null;
  }

  get i18n() {
    return this.args.i18n || i18n;
  }

  get lookupedTokens() {
    const _lookupToken = this.euiI18n.lookupFn || lookupToken;

    if (this.isI18nTokensShape) {
      return this.args.tokens?.map((token, idx) =>
        _lookupToken({
          token,
          i18nMapping: i18n.mapping,
          valueDefault: this.args.defaults![idx]
        })
      );
    } else {
      return _lookupToken({
        token: this.args.token!,
        i18nMapping: i18n.mapping,
        valueDefault: this.args.default!,
        values: this.args.values
      });
    }
  }
}
