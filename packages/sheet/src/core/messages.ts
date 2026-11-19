/**
 * The sheet's built-in messages. Each one has an i18n token (`euiSheet.*`)
 * and an English default with `{placeholders}`, the same shape as
 * `@ember-eui/core`'s `eui-i18n` tokens. The core never reads a locale:
 * `createMessages(translate)` takes the translate function, and the Ember
 * layer passes one backed by the `eui-i18n` service.
 */

export interface SheetMessages {
  /** 'Required' */
  required: () => string;
  /** '"abc" is not a number' */
  notANumber: (text: string) => string;
  /** '"maybe" is not a checkbox value' */
  notACheckbox: (text: string) => string;
  /** '"Purple" is not an option' */
  notAnOption: (text: string) => string;
  /** '"31/02/2026" is not a date' */
  notADate: (text: string) => string;
  /** 'Must be 0 or more' */
  min: (min: number | string) => string;
  /** 'Must be 10 or less' */
  max: (max: number | string) => string;
  /** 'Must be 5 characters or fewer' */
  maxLength: (max: number) => string;
  /** 'Invalid format' */
  pattern: () => string;
  /** '"x" could not be resolved' */
  unresolved: (text: string) => string;
}

export interface SheetMessageToken {
  /** The `eui-i18n` token, e.g. `euiSheet.required`. */
  token: string;
  /** English, with `{name}` placeholders for the parameters. */
  defaultMessage: string;
  /** Names of the message function's parameters, in order. */
  params: readonly string[];
}

/** Token, English default and parameter names of every message. */
export const sheetMessageTokens: Readonly<
  Record<keyof SheetMessages, SheetMessageToken>
> = {
  required: {
    token: 'euiSheet.required',
    defaultMessage: 'Required',
    params: []
  },
  notANumber: {
    token: 'euiSheet.notANumber',
    defaultMessage: '"{text}" is not a number',
    params: ['text']
  },
  notACheckbox: {
    token: 'euiSheet.notACheckbox',
    defaultMessage: '"{text}" is not a checkbox value',
    params: ['text']
  },
  notAnOption: {
    token: 'euiSheet.notAnOption',
    defaultMessage: '"{text}" is not an option',
    params: ['text']
  },
  notADate: {
    token: 'euiSheet.notADate',
    defaultMessage: '"{text}" is not a date',
    params: ['text']
  },
  min: {
    token: 'euiSheet.min',
    defaultMessage: 'Must be {min} or more',
    params: ['min']
  },
  max: {
    token: 'euiSheet.max',
    defaultMessage: 'Must be {max} or less',
    params: ['max']
  },
  maxLength: {
    token: 'euiSheet.maxLength',
    defaultMessage: 'Must be {max} characters or fewer',
    params: ['max']
  },
  pattern: {
    token: 'euiSheet.pattern',
    defaultMessage: 'Invalid format',
    params: []
  },
  unresolved: {
    token: 'euiSheet.unresolved',
    defaultMessage: '"{text}" could not be resolved',
    params: ['text']
  }
};

/** `(token, defaultMessage, values) => text`, e.g. `euiI18n.lookupToken`. */
export type SheetTranslate = (
  token: string,
  defaultMessage: string,
  values: Record<string, unknown>
) => string;

/** Replaces `{name}` with `values[name]` (no escapes, no plurals). */
export function interpolate(
  template: string,
  values: Record<string, unknown>
): string {
  return template.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in values ? String(values[name]) : match
  );
}

const englishTranslate: SheetTranslate = (_token, defaultMessage, values) =>
  interpolate(defaultMessage, values);

/** Messages that go through `translate`; without it, the English defaults. */
export function createMessages(
  translate: SheetTranslate = englishTranslate
): SheetMessages {
  const messages = {} as Record<string, (...args: unknown[]) => string>;
  for (const [key, { token, defaultMessage, params }] of Object.entries(
    sheetMessageTokens
  )) {
    messages[key] = (...args: unknown[]) => {
      const values: Record<string, unknown> = {};
      params.forEach((name, i) => (values[name] = args[i]));
      return translate(token, defaultMessage, values);
    };
  }
  return messages as unknown as SheetMessages;
}

/** The English defaults. */
export const defaultMessages: SheetMessages = createMessages();
