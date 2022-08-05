import Service from '@ember/service';
import { action } from '@ember/object';
import { processStringToChildren } from '../i18n/util';

interface lookupTokenOptions {
  token: string;
  i18nMapping?: Record<string, string>;
  valueDefault: string | ((values: Record<string, unknown>) => string);
  values?: { [key: string]: any };
  //@ts-expect-error TODO: type this?
  render?: I18nShape['render'];
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

export default class EuiI18n extends Service {
  translations = {};
  @action addTranslations(translations: Record<string, unknown>) {
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
    valueDefault: string | ((values: Record<string, unknown>) => string),
    values?: Record<string, any>
  ): string | string[] {
    return this._lookupToken({
      token,
      valueDefault,
      values
    });
  }

  getTokenFromMapping(
    token: lookupTokenOptions['token'],
    i18nMapping: lookupTokenOptions['i18nMapping'],
    valueDefault: lookupTokenOptions['valueDefault']
  ) {
    return (i18nMapping && i18nMapping[token]) || valueDefault;
  }

  @action
  _lookupToken(options: lookupTokenOptions) {
    const {
      token,
      i18nMapping = this.mapping,
      valueDefault,
      values = {}
    } = options;

    let renderable = this.getTokenFromMapping(token, i18nMapping, valueDefault);

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
