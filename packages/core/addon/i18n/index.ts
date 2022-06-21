import { processStringToChildren } from '../components/eui-i18n/util';

export interface I18nShape {
  mapping: { [key: string]: string };
}

interface lookupTokenOptions {
  token: string;
  i18nMapping: I18nShape['mapping'];
  valueDefault: string;
  i18nMappingFunc?: (token: string) => string;
  values?: { [key: string]: any };
  render?: I18nShape['render'];
}

const i18n: I18nShape = {
  mapping: {}
};

function useEuiI18n<T extends Record<string, unknown>, DEFAULT extends string>(
  token: string,
  defaultValue: DEFAULT,
  values?: T
): string | any[];
function useEuiI18n<DEFAULTS extends string[]>(
  tokens: string[],
  defaultValues: DEFAULTS
): string | any[];
function useEuiI18n(...args: any[]): string | any[] {
  if (typeof args[0] === 'string') {
    const [token, defaultValue, values] = args;
    return lookupToken({
      token,
      i18nMapping: i18n.mapping,
      valueDefault: defaultValue,
      values
    });
  } else {
    const [tokens, defaultValues] = args as [string[], string[]];
    return tokens.map((token, idx) =>
      lookupToken({
        token,
        i18nMapping: i18n.mapping,
        valueDefault: defaultValues[idx],
      })
    );
  }
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

export { i18n, useEuiI18n, lookupToken };
