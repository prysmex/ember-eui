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
  /** 'Keyboard shortcuts': the shortcut list's title (Ctrl/Cmd+/). */
  shortcuts: () => string;
  /** 'Navigation': a section of the shortcut list. */
  shortcutsNavigation: () => string;
  /** 'Selection' */
  shortcutsSelection: () => string;
  /** 'Editing' */
  shortcutsEditing: () => string;
  /** 'Records and fields' */
  shortcutsRecords: () => string;
  /** 'Clipboard and history' */
  shortcutsClipboard: () => string;
  /** 'Move to the next cell': a row of the shortcut list. */
  shortcutMove: () => string;
  /** 'Go to the first or last field of the row' */
  shortcutRowEdges: () => string;
  /** 'Go to the first or last cell' */
  shortcutDataEdges: () => string;
  /** 'Jump to the edge of the data' */
  shortcutJump: () => string;
  /** 'Move by the rows in view' */
  shortcutPage: () => string;
  /** 'Leave the grid' */
  shortcutLeave: () => string;
  /** 'Extend the selection' */
  shortcutExtend: () => string;
  /** 'Extend to the first or last field of the row' */
  shortcutExtendRow: () => string;
  /** 'Extend to the first or last record' */
  shortcutExtendRecords: () => string;
  /** 'Extend to the edge of the data' */
  shortcutExtendJump: () => string;
  /** 'Select every cell' */
  shortcutSelectAll: () => string;
  /** 'Select rows (on a row number)' */
  shortcutSelectRows: () => string;
  /** 'Edit the cell' */
  shortcutEdit: () => string;
  /** 'Type to replace the value' */
  shortcutType: () => string;
  /** 'Save and go down (in an editor)' */
  shortcutSaveDown: () => string;
  /** 'Save and go right or left (in an editor)' */
  shortcutSaveRight: () => string;
  /** 'Close the editor without saving' */
  shortcutCancelEdit: () => string;
  /** 'Clear the selected cells' */
  shortcutClear: () => string;
  /** 'Toggle a checkbox, or expand the record' */
  shortcutSpace: () => string;
  /** 'Fill down' */
  shortcutFillDown: () => string;
  /** 'Fill right' */
  shortcutFillRight: () => string;
  /** 'Add a record below' */
  shortcutInsertBelow: () => string;
  /** 'Add a record (on the add row)' */
  shortcutAddRecord: () => string;
  /** 'Expand the record (on a row number)' */
  shortcutExpand: () => string;
  /** 'Check the row (on a row number)' */
  shortcutCheckRow: () => string;
  /** 'Open the row menu' */
  shortcutRowMenu: () => string;
  /** 'Open the field menu (on a header)' */
  shortcutFieldMenu: () => string;
  /** 'Move the field: Space, the arrows, Space (on a header)' */
  shortcutMoveField: () => string;
  /** 'Copy' */
  shortcutCopy: () => string;
  /** 'Cut' */
  shortcutCut: () => string;
  /** 'Paste' */
  shortcutPaste: () => string;
  /** 'Undo' */
  shortcutUndo: () => string;
  /** 'Redo' */
  shortcutRedo: () => string;
  /** 'Show this list' */
  shortcutShowList: () => string;
  /** 'Ctrl': a key name in the shortcut list. */
  shortcutKeyCtrl: () => string;
  /** 'Shift' */
  shortcutKeyShift: () => string;
  /** 'Alt' */
  shortcutKeyAlt: () => string;
  /** 'Enter' */
  shortcutKeyEnter: () => string;
  /** 'Esc' */
  shortcutKeyEscape: () => string;
  /** 'Tab' */
  shortcutKeyTab: () => string;
  /** 'Space' */
  shortcutKeySpace: () => string;
  /** 'Delete' */
  shortcutKeyDelete: () => string;
  /** 'Backspace' */
  shortcutKeyBackspace: () => string;
  /** 'Home' */
  shortcutKeyHome: () => string;
  /** 'End' */
  shortcutKeyEnd: () => string;
  /** 'Page Up' */
  shortcutKeyPageUp: () => string;
  /** 'Page Down' */
  shortcutKeyPageDown: () => string;
  /** 'Arrows' */
  shortcutKeyArrows: () => string;
  /** 'Menu' */
  shortcutKeyMenu: () => string;
  /** 'A letter or digit' */
  shortcutKeyCharacter: () => string;
  /** 'or': between two keys of one row. */
  shortcutOr: () => string;
  /** 'Right-click, long press': the row and header menus by pointer, in the shortcut list. */
  shortcutKeyRightClick: () => string;
  /** 'No records': the sheet with an empty `@records` (V03 batch 1). */
  noRecords: () => string;
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
  },
  shortcuts: {
    token: 'euiSheet.shortcuts',
    defaultMessage: 'Keyboard shortcuts',
    params: []
  },
  shortcutsNavigation: {
    token: 'euiSheet.shortcutsNavigation',
    defaultMessage: 'Navigation',
    params: []
  },
  shortcutsSelection: {
    token: 'euiSheet.shortcutsSelection',
    defaultMessage: 'Selection',
    params: []
  },
  shortcutsEditing: {
    token: 'euiSheet.shortcutsEditing',
    defaultMessage: 'Editing',
    params: []
  },
  shortcutsRecords: {
    token: 'euiSheet.shortcutsRecords',
    defaultMessage: 'Records and fields',
    params: []
  },
  shortcutsClipboard: {
    token: 'euiSheet.shortcutsClipboard',
    defaultMessage: 'Clipboard and history',
    params: []
  },
  shortcutMove: {
    token: 'euiSheet.shortcutMove',
    defaultMessage: 'Move to the next cell',
    params: []
  },
  shortcutRowEdges: {
    token: 'euiSheet.shortcutRowEdges',
    defaultMessage: 'Go to the first or last field of the row',
    params: []
  },
  shortcutDataEdges: {
    token: 'euiSheet.shortcutDataEdges',
    defaultMessage: 'Go to the first or last cell',
    params: []
  },
  shortcutJump: {
    token: 'euiSheet.shortcutJump',
    defaultMessage: 'Jump to the edge of the data',
    params: []
  },
  shortcutPage: {
    token: 'euiSheet.shortcutPage',
    defaultMessage: 'Move by the rows in view',
    params: []
  },
  shortcutLeave: {
    token: 'euiSheet.shortcutLeave',
    defaultMessage: 'Leave the grid',
    params: []
  },
  shortcutExtend: {
    token: 'euiSheet.shortcutExtend',
    defaultMessage: 'Extend the selection',
    params: []
  },
  shortcutExtendRow: {
    token: 'euiSheet.shortcutExtendRow',
    defaultMessage: 'Extend to the first or last field of the row',
    params: []
  },
  shortcutExtendRecords: {
    token: 'euiSheet.shortcutExtendRecords',
    defaultMessage: 'Extend to the first or last record',
    params: []
  },
  shortcutExtendJump: {
    token: 'euiSheet.shortcutExtendJump',
    defaultMessage: 'Extend to the edge of the data',
    params: []
  },
  shortcutSelectAll: {
    token: 'euiSheet.shortcutSelectAll',
    defaultMessage: 'Select every cell',
    params: []
  },
  shortcutSelectRows: {
    token: 'euiSheet.shortcutSelectRows',
    defaultMessage: 'Select rows (on a row number)',
    params: []
  },
  shortcutEdit: {
    token: 'euiSheet.shortcutEdit',
    defaultMessage: 'Edit the cell',
    params: []
  },
  shortcutType: {
    token: 'euiSheet.shortcutType',
    defaultMessage: 'Type to replace the value',
    params: []
  },
  shortcutSaveDown: {
    token: 'euiSheet.shortcutSaveDown',
    defaultMessage: 'Save and go down (in an editor)',
    params: []
  },
  shortcutSaveRight: {
    token: 'euiSheet.shortcutSaveRight',
    defaultMessage: 'Save and go right or left (in an editor)',
    params: []
  },
  shortcutCancelEdit: {
    token: 'euiSheet.shortcutCancelEdit',
    defaultMessage: 'Close the editor without saving',
    params: []
  },
  shortcutClear: {
    token: 'euiSheet.shortcutClear',
    defaultMessage: 'Clear the selected cells',
    params: []
  },
  shortcutSpace: {
    token: 'euiSheet.shortcutSpace',
    defaultMessage: 'Toggle a checkbox, or expand the record',
    params: []
  },
  shortcutFillDown: {
    token: 'euiSheet.shortcutFillDown',
    defaultMessage: 'Fill down',
    params: []
  },
  shortcutFillRight: {
    token: 'euiSheet.shortcutFillRight',
    defaultMessage: 'Fill right',
    params: []
  },
  shortcutInsertBelow: {
    token: 'euiSheet.shortcutInsertBelow',
    defaultMessage: 'Add a record below',
    params: []
  },
  shortcutAddRecord: {
    token: 'euiSheet.shortcutAddRecord',
    defaultMessage: 'Add a record (on the add row)',
    params: []
  },
  shortcutExpand: {
    token: 'euiSheet.shortcutExpand',
    defaultMessage: 'Expand the record (on a row number)',
    params: []
  },
  shortcutCheckRow: {
    token: 'euiSheet.shortcutCheckRow',
    defaultMessage: 'Check the row (on a row number)',
    params: []
  },
  shortcutRowMenu: {
    token: 'euiSheet.shortcutRowMenu',
    defaultMessage: 'Open the row menu',
    params: []
  },
  shortcutFieldMenu: {
    token: 'euiSheet.shortcutFieldMenu',
    defaultMessage: 'Open the field menu (on a header)',
    params: []
  },
  shortcutMoveField: {
    token: 'euiSheet.shortcutMoveField',
    defaultMessage: 'Move the field: Space, the arrows, Space (on a header)',
    params: []
  },
  shortcutCopy: {
    token: 'euiSheet.shortcutCopy',
    defaultMessage: 'Copy',
    params: []
  },
  shortcutCut: {
    token: 'euiSheet.shortcutCut',
    defaultMessage: 'Cut',
    params: []
  },
  shortcutPaste: {
    token: 'euiSheet.shortcutPaste',
    defaultMessage: 'Paste',
    params: []
  },
  shortcutUndo: {
    token: 'euiSheet.shortcutUndo',
    defaultMessage: 'Undo',
    params: []
  },
  shortcutRedo: {
    token: 'euiSheet.shortcutRedo',
    defaultMessage: 'Redo',
    params: []
  },
  shortcutShowList: {
    token: 'euiSheet.shortcutShowList',
    defaultMessage: 'Show this list',
    params: []
  },
  shortcutKeyCtrl: {
    token: 'euiSheet.shortcutKeyCtrl',
    defaultMessage: 'Ctrl',
    params: []
  },
  shortcutKeyShift: {
    token: 'euiSheet.shortcutKeyShift',
    defaultMessage: 'Shift',
    params: []
  },
  shortcutKeyAlt: {
    token: 'euiSheet.shortcutKeyAlt',
    defaultMessage: 'Alt',
    params: []
  },
  shortcutKeyEnter: {
    token: 'euiSheet.shortcutKeyEnter',
    defaultMessage: 'Enter',
    params: []
  },
  shortcutKeyEscape: {
    token: 'euiSheet.shortcutKeyEscape',
    defaultMessage: 'Esc',
    params: []
  },
  shortcutKeyTab: {
    token: 'euiSheet.shortcutKeyTab',
    defaultMessage: 'Tab',
    params: []
  },
  shortcutKeySpace: {
    token: 'euiSheet.shortcutKeySpace',
    defaultMessage: 'Space',
    params: []
  },
  shortcutKeyDelete: {
    token: 'euiSheet.shortcutKeyDelete',
    defaultMessage: 'Delete',
    params: []
  },
  shortcutKeyBackspace: {
    token: 'euiSheet.shortcutKeyBackspace',
    defaultMessage: 'Backspace',
    params: []
  },
  shortcutKeyHome: {
    token: 'euiSheet.shortcutKeyHome',
    defaultMessage: 'Home',
    params: []
  },
  shortcutKeyEnd: {
    token: 'euiSheet.shortcutKeyEnd',
    defaultMessage: 'End',
    params: []
  },
  shortcutKeyPageUp: {
    token: 'euiSheet.shortcutKeyPageUp',
    defaultMessage: 'Page Up',
    params: []
  },
  shortcutKeyPageDown: {
    token: 'euiSheet.shortcutKeyPageDown',
    defaultMessage: 'Page Down',
    params: []
  },
  shortcutKeyArrows: {
    token: 'euiSheet.shortcutKeyArrows',
    defaultMessage: 'Arrows',
    params: []
  },
  shortcutKeyMenu: {
    token: 'euiSheet.shortcutKeyMenu',
    defaultMessage: 'Menu',
    params: []
  },
  shortcutKeyCharacter: {
    token: 'euiSheet.shortcutKeyCharacter',
    defaultMessage: 'A letter or digit',
    params: []
  },
  shortcutOr: {
    token: 'euiSheet.shortcutOr',
    defaultMessage: 'or',
    params: []
  },
  shortcutKeyRightClick: {
    token: 'euiSheet.shortcutKeyRightClick',
    defaultMessage: 'Right-click, long press',
    params: []
  },
  noRecords: {
    token: 'euiSheet.noRecords',
    defaultMessage: 'No records',
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
