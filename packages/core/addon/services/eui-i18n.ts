import Service from '@ember/service';
import { action } from '@ember/object';

interface LookupOptions {
  token: string;
  valueDefault: string;
  i18nMapping?: Record<string, unknown>;
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

export default class EuiI18n extends Service {
  translations = {};
  lookupFn: ((opts: LookupOptions) => string) | null = null;

  get mapping() {
    return this.translations;
  }

  @action setLookupFn(fn: (opts: LookupOptions) => string) {
    this.lookupFn = fn;
  }

  @action addTranslations(translations: Record<string, unknown>) {
    // TODO: deep merge?
    this.translations = {
      ...this.translations,
      ...flatten({}, translations)
    };
  }
}

declare module '@ember/service' {
  interface Registry {
    'eui-i18n': EuiI18n;
  }
}
