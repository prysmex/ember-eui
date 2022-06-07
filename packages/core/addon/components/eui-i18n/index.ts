import Component from '@glimmer/component';
import { processStringToChildren } from './util';
//@ts-ignore
import { i18n, I18nShape } from '@ember-eui/core/i18n';

interface Args {
  tokens?: string[];
  defaults?: string[];
  token?: string;
  default?: string;
  values?: { [key: string]: any };
  i18n?: I18nShape;
}

interface lookupTokenOptions {
  token: string;
  i18nMapping: I18nShape['mapping'];
  valueDefault: string;
  i18nMappingFunc?: (token: string) => string;
  values?: { [key: string]: any };
  render?: I18nShape['render'];
}

function lookupToken(options: lookupTokenOptions) {
  const {
    token,
    i18nMapping,
    valueDefault,
    i18nMappingFunc,
    values = {}
  } = options;

  let renderable = (i18nMapping && i18nMapping[token]) || valueDefault;

  const children = processStringToChildren(renderable, values, i18nMappingFunc);
  if (typeof children === 'string') {
    // likewise, `processStringToChildren` returns a string or ReactChild[] depending on
    // the type of `values`, so we will make the assumption that the default value is correct.
    return children;
  }

  // same reasons as above, we can't promise the transforms match the default's type
  return children;
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
