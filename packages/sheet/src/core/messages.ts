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
  /** 'Add record': the add row. */
  addRecord: () => string;
  /** 'Insert record above' */
  insertAbove: () => string;
  /** 'Insert record below' */
  insertBelow: () => string;
  /** 'Duplicate record' */
  duplicateRecord: () => string;
  /** 'Duplicate 3 records' */
  duplicateRecords: (count: number) => string;
  /** 'Expand record' */
  expandRecord: () => string;
  /** 'Copy row' */
  copyRow: () => string;
  /** 'Copy 3 rows' */
  copyRows: (count: number) => string;
  /** 'Delete record' */
  deleteRecord: () => string;
  /** 'Delete 3 records' */
  deleteRecords: (count: number) => string;
  /** 'Select row': the row's checkbox. */
  selectRow: () => string;
  /** 'Select all rows': the header's checkbox. */
  selectAllRows: () => string;
  /** 'Row 3': the row-number cell's label. */
  rowNumber: (n: number) => string;
  /** 'Record 3': the expanded record's title when its first field is empty. */
  recordTitle: (n: number) => string;
  /** 'Previous record' */
  previousRecord: () => string;
  /** 'Next record' */
  nextRecord: () => string;
  /** 'Close' */
  close: () => string;
  /** 'Filter by this field': the column menu's item with `@onFilterByField`. */
  filterByField: () => string;
  /** 'Re-apply': the EmberSearchUi connector's button that runs the search again after edits. */
  reapply: () => string;
  /** 'Text is not a file': text pasted on an attachment cell. */
  notAnAttachment: () => string;
  /** 'Upload failed' */
  uploadFailed: () => string;
  /** '"x" is not a URL' */
  notAUrl: (text: string) => string;
  /** '"x" is not an email address' */
  notAnEmail: (text: string) => string;
  /** '"x" is not a phone number' */
  notAPhone: (text: string) => string;
  /** '"x" is not a duration' */
  notADuration: (text: string) => string;
  /** 'Open link': the row menu's item and the expanded record's button. */
  openLink: () => string;
  /** 'Remove file' */
  removeFile: () => string;
  /** 'Add files': the attachment editor's file picker. */
  addFiles: () => string;
  /** 'Loading': a picker searching. */
  loading: () => string;
  /** 'No matches': a picker whose search found nothing. */
  noMatches: () => string;
  /** 'Could not load the options': a picker whose search failed. */
  searchFailed: () => string;
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
  },
  addRecord: {
    token: 'euiSheet.addRecord',
    defaultMessage: 'Add record',
    params: []
  },
  insertAbove: {
    token: 'euiSheet.insertAbove',
    defaultMessage: 'Insert record above',
    params: []
  },
  insertBelow: {
    token: 'euiSheet.insertBelow',
    defaultMessage: 'Insert record below',
    params: []
  },
  duplicateRecord: {
    token: 'euiSheet.duplicateRecord',
    defaultMessage: 'Duplicate record',
    params: []
  },
  duplicateRecords: {
    token: 'euiSheet.duplicateRecords',
    defaultMessage: 'Duplicate {count} records',
    params: ['count']
  },
  expandRecord: {
    token: 'euiSheet.expandRecord',
    defaultMessage: 'Expand record',
    params: []
  },
  copyRow: {
    token: 'euiSheet.copyRow',
    defaultMessage: 'Copy row',
    params: []
  },
  copyRows: {
    token: 'euiSheet.copyRows',
    defaultMessage: 'Copy {count} rows',
    params: ['count']
  },
  deleteRecord: {
    token: 'euiSheet.deleteRecord',
    defaultMessage: 'Delete record',
    params: []
  },
  deleteRecords: {
    token: 'euiSheet.deleteRecords',
    defaultMessage: 'Delete {count} records',
    params: ['count']
  },
  selectRow: {
    token: 'euiSheet.selectRow',
    defaultMessage: 'Select row',
    params: []
  },
  selectAllRows: {
    token: 'euiSheet.selectAllRows',
    defaultMessage: 'Select all rows',
    params: []
  },
  rowNumber: {
    token: 'euiSheet.rowNumber',
    defaultMessage: 'Row {n}',
    params: ['n']
  },
  recordTitle: {
    token: 'euiSheet.recordTitle',
    defaultMessage: 'Record {n}',
    params: ['n']
  },
  previousRecord: {
    token: 'euiSheet.previousRecord',
    defaultMessage: 'Previous record',
    params: []
  },
  nextRecord: {
    token: 'euiSheet.nextRecord',
    defaultMessage: 'Next record',
    params: []
  },
  filterByField: {
    token: 'euiSheet.filterByField',
    defaultMessage: 'Filter by this field',
    params: []
  },
  reapply: {
    token: 'euiSheet.reapply',
    defaultMessage: 'Re-apply',
    params: []
  },
  close: {
    token: 'euiSheet.close',
    defaultMessage: 'Close',
    params: []
  },
  notAnAttachment: {
    token: 'euiSheet.notAnAttachment',
    defaultMessage: 'Text is not a file',
    params: []
  },
  uploadFailed: {
    token: 'euiSheet.uploadFailed',
    defaultMessage: 'Upload failed',
    params: []
  },
  notAUrl: {
    token: 'euiSheet.notAUrl',
    defaultMessage: '"{text}" is not a URL',
    params: ['text']
  },
  notAnEmail: {
    token: 'euiSheet.notAnEmail',
    defaultMessage: '"{text}" is not an email address',
    params: ['text']
  },
  notAPhone: {
    token: 'euiSheet.notAPhone',
    defaultMessage: '"{text}" is not a phone number',
    params: ['text']
  },
  notADuration: {
    token: 'euiSheet.notADuration',
    defaultMessage: '"{text}" is not a duration',
    params: ['text']
  },
  openLink: {
    token: 'euiSheet.openLink',
    defaultMessage: 'Open link',
    params: []
  },
  removeFile: {
    token: 'euiSheet.removeFile',
    defaultMessage: 'Remove file',
    params: []
  },
  addFiles: {
    token: 'euiSheet.addFiles',
    defaultMessage: 'Add files',
    params: []
  },
  loading: {
    token: 'euiSheet.loading',
    defaultMessage: 'Loading',
    params: []
  },
  noMatches: {
    token: 'euiSheet.noMatches',
    defaultMessage: 'No matches',
    params: []
  },
  searchFailed: {
    token: 'euiSheet.searchFailed',
    defaultMessage: 'Could not load the options',
    params: []
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
