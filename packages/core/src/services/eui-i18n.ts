import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import Service from '@ember/service';

import { processStringToChildren } from '../i18n/util';

interface LookupTokenOptions {
  token: string;
  i18nMapping?: Record<string, string>;
  valueDefault: string | ((values: Record<string, unknown>) => string);
  values?: Record<string, unknown>;
}

function flatten(
  acc: Record<string, unknown> = {},
  obj: Record<string, unknown>,
  path = ''
) {
  path = path.length > 0 ? path + '.' : path;

  for (const key in obj) {
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      flatten(acc, obj[key] as Record<string, unknown>, path + key);
    } else {
      acc[path + key] = obj[key];
    }
  }

  return acc;
}

const defaultNumberFormat = new Intl.NumberFormat('en');

export default class EuiI18n extends Service {
  translations = {};

  /**
   * Formats numbers for `EuiI18nNumber`. Defaults to English
   * (`1,234.5`); replace it to follow your app's locale, e.g.
   * `this.euiI18n.formatNumber = (n) => new Intl.NumberFormat('de').format(n)`.
   */
  @tracked formatNumber: (value: number) => string = (value) => defaultNumberFormat.format(value);

  @action
  addTranslations(translations: Record<string, unknown>) {
    // TODO: deep merge?
    this.translations = {
      ...this.translations,
      ...flatten({}, translations)
    };
  }

  get mapping() {
    return this.translations;
  }

  @action
  lookupToken(
    token: string,
    valueDefault: string | ((values: { [key: string]: unknown }) => string),
    values?: Record<string, any>
  ): string {
    return this._lookupToken({
      token,
      valueDefault,
      values
    });
  }

  getTokenFromMapping(
    token: LookupTokenOptions['token'],
    valueDefault: LookupTokenOptions['valueDefault'],
    _values: LookupTokenOptions['values'],
    i18nMapping: LookupTokenOptions['i18nMapping']
  ) {
    return (i18nMapping && i18nMapping[token]) || valueDefault;
  }

  @action
  _lookupToken(options: LookupTokenOptions) {
    const {
      token,
      i18nMapping = this.mapping,
      valueDefault,
      values = {}
    } = options;

    let renderable = this.getTokenFromMapping(
      token,
      valueDefault,
      values,
      i18nMapping
    );

    if (typeof renderable === 'function') {
      renderable = renderable(values);
    }

    const children = processStringToChildren(renderable, values);

    return children as string;
  }
}

declare module '@ember/service' {
  interface Registry {
    'eui-i18n': EuiI18n;
  }
}
