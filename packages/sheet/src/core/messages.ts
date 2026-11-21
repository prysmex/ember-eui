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
  /** 'Copy with field names': the row menu's item with `@copyWithFieldNames` (v0.4 05). */
  copyWithFieldNames: () => string;
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
  /** 'Fit to content': the column menu's item that fits the column's width to its content (v0.4 01). */
  fitToContent: () => string;
  /** 'Fit all fields': for an app's button that calls `api.fitFields()` (v0.4 01). */
  fitAllFields: () => string;
  /** 'Full screen': for an app's toolbar button (v0.4 02). */
  enterFullScreen: () => string;
  /** 'Exit full screen': the same button while full screen (v0.4 02). */
  exitFullScreen: () => string;
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
  /** 'Read only': the focused cell's message box when a key would edit a read-only cell (V03 batch 2). */
  cellReadOnly: () => string;
  /** 'Add field': the "+" column and the field editor's title on create (V03 6.3) */
  addField: () => string;
  /** 'Edit field': the header menu item and the field editor's title */
  editField: () => string;
  /** 'Insert left': the header menu: a new field to the left */
  insertFieldLeft: () => string;
  /** 'Insert right' */
  insertFieldRight: () => string;
  /** 'Duplicate field' */
  duplicateField: () => string;
  /** 'Name copy': the label of a duplicated field */
  duplicateFieldLabel: (label: string) => string;
  /** 'Delete field': the header menu item and the confirm button */
  deleteField: () => string;
  /** 'Delete "{label}" and its values in every record? This cannot be undone.' */
  deleteFieldConfirm: (label: string) => string;
  /** 'Name': the field editor's name input */
  fieldName: () => string;
  /** 'Type' */
  fieldType: () => string;
  /** 'Description' */
  fieldDescription: () => string;
  /** 'Required' */
  fieldRequired: () => string;
  /** 'Options': a select field's options in the field editor */
  fieldOptions: () => string;
  /** 'Add option' */
  addOption: () => string;
  /** 'Remove option' */
  removeOption: () => string;
  /** 'Option {n}': 'Option 2': an option's name input (V03 batch 2) */
  optionLabel: (n: number) => string;
  /** 'Color': an option's colour (V03 batch 2) */
  optionColor: () => string;
  /** 'No color' */
  colorNone: () => string;
  /** 'Gray': EuiBadge's named colours in the options form (V03 batch 2) */
  color_default: () => string;
  /** 'Outline' */
  color_hollow: () => string;
  /** 'Blue' */
  color_primary: () => string;
  /** 'Pink' */
  color_accent: () => string;
  /** 'Green' */
  color_success: () => string;
  /** 'Yellow' */
  color_warning: () => string;
  /** 'Red' */
  color_danger: () => string;
  /** 'Currency code': a currency field's ISO code (V03 batch 2) */
  fieldCurrency: () => string;
  /** 'Decimals': currency and percent (V03 batch 2) */
  fieldPrecision: () => string;
  /** 'Stars': a rating's maximum (V03 batch 2) */
  fieldRatingMax: () => string;
  /** 'Date format': a date's day/month order (V03 batch 2) */
  fieldDateOrder: () => string;
  /** 'Day/Month/Year' */
  dateOrderDmy: () => string;
  /** 'Month/Day/Year' */
  dateOrderMdy: () => string;
  /** 'Format': a duration's format (V03 batch 2) */
  fieldDurationFormat: () => string;
  /** 'Save' */
  save: () => string;
  /** 'Cancel' */
  cancel: () => string;
  /** 'Give the field a name' */
  fieldNameRequired: () => string;
  /** 'Changing the type may change or clear values the new type cannot read.' */
  fieldTypeChangeWarning: () => string;
  /** 'Single line text': a type's name in the field editor (V03 6.4) */
  fieldType_text: () => string;
  /** 'Long text' */
  fieldType_longText: () => string;
  /** 'Number' */
  fieldType_number: () => string;
  /** 'Currency' */
  fieldType_currency: () => string;
  /** 'Percent' */
  fieldType_percent: () => string;
  /** 'Checkbox' */
  fieldType_checkbox: () => string;
  /** 'Single select' */
  fieldType_singleSelect: () => string;
  /** 'Multiple select' */
  fieldType_multiSelect: () => string;
  /** 'Date' */
  fieldType_date: () => string;
  /** 'Duration' */
  fieldType_duration: () => string;
  /** 'Rating' */
  fieldType_rating: () => string;
  /** 'URL' */
  fieldType_url: () => string;
  /** 'Email' */
  fieldType_email: () => string;
  /** 'Phone number' */
  fieldType_phone: () => string;
  /** 'Link to another record' */
  fieldType_linkedRecord: () => string;
  /** 'User' */
  fieldType_user: () => string;
  /** 'Attachment' */
  fieldType_attachment: () => string;
  /** 'Group by this field': the header menu's item with `@onGroupByChange` (V03 8.3) */
  groupByField: () => string;
  /** 'Remove grouping': the grouped field's header menu item */
  removeGrouping: () => string;
  /** '{field}: {value}': 'Status: Open', a group header's name for screen readers (V03 8.4) */
  groupLabel: (field: string, value: string) => string;
  /** '(Empty)': the label of the group of records with an empty value */
  groupEmpty: () => string;
  /** '{count}': a group header's record count, after its label (an app may translate it to 'Count {count}') */
  groupCount: (count: number) => string;
  /** '(continued)': a group that began on an earlier page */
  groupContinued: () => string;
  /** 'Expand group': a collapsed header's toggle */
  expandGroup: () => string;
  /** 'Collapse group': an expanded header's toggle */
  collapseGroup: () => string;
  /** 'Drag to move the record': the row drag grip's title (V03 10.1) */
  moveRecord: () => string;
  /** 'Drag to move 3 records': the grip of a row among checked or selected rows */
  moveRecords: (count: number) => string;
  /** 'Move the rows up or down (on a row number, with @canMove)' */
  shortcutMoveRecords: () => string;
  /** '"32/11/2026 25:00" is not a date and time': a dateTime field (V03 10.3) */
  notADateTime: (text: string) => string;
  /** 'Unknown time zone "Mars/Base"': a dateTime field whose timeZone the browser does not know */
  unknownTimeZone: (zone: string) => string;
  /** 'Date and time' */
  fieldType_dateTime: () => string;
  /** 'Time zone': the dateTime options of the field editor ('local', 'utc' or an IANA name) */
  fieldTimeZone: () => string;
  /** 'local, utc, or a name like America/Mexico_City' */
  fieldTimeZoneHelp: () => string;
  /** 'Clock' */
  fieldClock: () => string;
  /** '24-hour' */
  clock24: () => string;
  /** '12-hour (am/pm)' */
  clock12: () => string;
  /** 'Show seconds' */
  fieldSeconds: () => string;
  /** 'A button has no value': text pasted or typed on a button field (V03 10.3.1) */
  buttonNoValue: () => string;
  /** 'Button' */
  fieldType_button: () => string;
  /** 'Button text': the button options of the field editor (empty: the field's name) */
  fieldButtonLabel: () => string;
  /** 'Icon (an EUI icon name)' */
  fieldButtonIcon: () => string;
  /** 'Colour' */
  fieldButtonColor: () => string;
  /** 'Barcode' */
  fieldType_barcode: () => string;
  /** 'Scan a code': the barcode editor's camera button and scan panel (V03 10.3.2) */
  scanBarcode: () => string;
  /** 'The camera is not available or was not allowed': the scan panel */
  cameraDenied: () => string;
  /** 'Uploading… 40%': the title of an attachment cell whose upload reports progress (V03 11.4) */
  uploading: (percent: number) => string;
  /** 'Drag to change the selection': a touch selection handle (V03 11.3) */
  selectionHandle: () => string;
  /** 'Copy': the touch menu's item that copies the selected cells (V03 11.3) */
  copyCells: () => string;
  /** 'Paste': the touch menu's item that pastes over the selected cells (V03 11.3) */
  pasteCells: () => string;
  /** 'File': the import screen's first part (v0.4 10) */
  importFile: () => string;
  /** 'Encoding': the file's encoding found */
  importEncoding: () => string;
  /** 'Delimiter': the delimiter select */
  importDelimiter: () => string;
  /** 'Comma (,)' */
  importDelimiterComma: () => string;
  /** 'Semicolon (;)' */
  importDelimiterSemicolon: () => string;
  /** 'Tab' */
  importDelimiterTab: () => string;
  /** 'First line is the header': the switch */
  importHeaderLine: () => string;
  /** '3 lines': the file's data lines */
  importLineCount: (n: number) => string;
  /** '1 line': `importLineCount` for one line */
  importLineCountOne: (n: number) => string;
  /** 'Reading the file…': while a file is read */
  importReading: () => string;
  /** 'The file has no lines to import' */
  importNoLines: () => string;
  /** 'Columns': the second part */
  importColumns: () => string;
  /** 'Column 3': a column with no header */
  importColumnN: (n: number) => string;
  /** 'In the file': the columns table's first header */
  importFileColumn: () => string;
  /** 'Type': the guessed type's header */
  importType: () => string;
  /** 'Goes to': the target's header */
  importTarget: () => string;
  /** 'Where "Precio" goes': the target select's label */
  importTargetFor: (header: string) => string;
  /** 'Skip': the target "nowhere" */
  importSkip: () => string;
  /** 'New field…': the target that creates a field */
  importNewField: () => string;
  /** 'New field: Estado (Single select)': a new field target */
  importNewFieldNamed: (label: string, type: string) => string;
  /** 'Edit the new field': the button that opens its form */
  importEditNewField: () => string;
  /** 'Price (in use by "Precio")': a field another column goes to */
  importTakenBy: (field: string, header: string) => string;
  /** 'Its field already gets "Precio"': a column whose header names a taken field */
  importTaken: (header: string) => string;
  /** 'Transform': the transform's header */
  importTransform: () => string;
  /** 'Transform for "Precio"': the transform select's label */
  importTransformFor: (header: string) => string;
  /** 'None': no transform */
  importNoTransform: () => string;
  /** 'Options': the built-in options' header */
  importOptions: () => string;
  /** 'Trim spaces' */
  importTrim: () => string;
  /** 'Empty is no value' */
  importEmptyIsNull: () => string;
  /** 'Decimal separator' */
  importDecimalSeparator: () => string;
  /** 'Point (1.5)' */
  importDecimalPoint: () => string;
  /** 'Comma (1,5)' */
  importDecimalComma: () => string;
  /** 'Values (3 mapped)': the value map's button */
  importValues: (n: number) => string;
  /** 'Values (1 mapped)': `importValues` for one text */
  importValuesOne: (n: number) => string;
  /** 'Values of "Precio"': the value map table's caption */
  importValueMapFor: (header: string) => string;
  /** 'In the file': the value map's first header */
  importValueInFile: () => string;
  /** 'Becomes': the value map's second header */
  importValueBecomes: () => string;
  /** 'As in the file': a text left as it is */
  importValueAsIs: () => string;
  /** 'No value' */
  importValueNone: () => string;
  /** '(empty)': an empty text in the value map */
  importValueEmpty: () => string;
  /** 'new': a new field's preview header */
  importNew: () => string;
  /** 'Checked' */
  importValueChecked: () => string;
  /** 'Unchecked' */
  importValueUnchecked: () => string;
  /** 'Status': the status header */
  importStatus: () => string;
  /** '197 of 200 read': a column's status */
  importRead: (read: number, total: number) => string;
  /** '1 of 1 read': `importRead` for a column of one line */
  importReadOne: (read: number, total: number) => string;
  /** '3 can’t be read': a column's status, a link that filters the preview */
  importCantRead: (n: number) => string;
  /** '1 can’t be read': `importCantRead` for one */
  importCantReadOne: (n: number) => string;
  /** 'Single select · 98%': the guessed type's badge */
  importGuess: (type: string, percent: number) => string;
  /** 'Preview': the third part */
  importPreview: () => string;
  /** 'The first 3 of 200 lines': the preview's caption */
  importPreviewOf: (n: number, total: number) => string;
  /** 'The only line': `importPreviewOf` for a file of one line */
  importPreviewOfOne: (n: number, total: number) => string;
  /** 'Lines where "Precio" can’t be read': the filtered preview's caption */
  importPreviewErrors: (header: string) => string;
  /** 'Show the first lines': clears the filter */
  importShowFirstLines: () => string;
  /** 'Line': the preview's line number header */
  importLine: () => string;
  /** 'linked on import': a linked record or user in the preview */
  importLinkedOnImport: () => string;
  /** 'new option': a select value that creates one */
  importNewOption: () => string;
  /** '3 lines ready': the dry run's total */
  importLinesReady: (n: number) => string;
  /** '1 line ready': `importLinesReady` for one line */
  importLinesReadyOne: (n: number) => string;
  /** '3 with errors' */
  importLinesWithErrors: (n: number) => string;
  /** '1 with errors': `importLinesWithErrors` for one line */
  importLinesWithErrorsOne: (n: number) => string;
  /** 'Download the lines with errors' */
  importDownloadErrors: () => string;
  /** 'Import all (errors stay as rejections)' */
  importAll: () => string;
  /** 'Skip lines with errors' */
  importSkipErrors: () => string;
  /** 'Import 3 lines': the import button */
  importLines: (n: number) => string;
  /** 'Import 1 line': `importLines` for one line */
  importLinesOne: (n: number) => string;
  /** 'No column goes to a field': why Import is disabled */
  importNoTarget: () => string;
  /** 'The new fields could not be created': `@onCreateFields` resolved with another number of fields */
  importCreateMismatch: () => string;
  /** 'Checking the lines…': the totals while the first dry run of a file waits for the preview to show */
  importChecking: () => string;
  /** 'Row 3, checked': the row-number cell's label when its row is checked. */
  rowNumberChecked: (n: number) => string;
  /** 'Row number': the row-number column's header, for screen readers. */
  rowNumberHeader: () => string;
  /** 'Checked': a checkbox cell's label when checked. */
  cellChecked: () => string;
  /** 'Not checked': a checkbox cell's label when not checked. */
  cellUnchecked: () => string;
  /** 'Row menu': the row menu's name, for screen readers. */
  rowMenu: () => string;
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
  copyWithFieldNames: {
    token: 'euiSheet.copyWithFieldNames',
    defaultMessage: 'Copy with field names',
    params: []
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
  fitToContent: {
    token: 'euiSheet.fitToContent',
    defaultMessage: 'Fit to content',
    params: []
  },
  fitAllFields: {
    token: 'euiSheet.fitAllFields',
    defaultMessage: 'Fit all fields',
    params: []
  },
  enterFullScreen: {
    token: 'euiSheet.enterFullScreen',
    defaultMessage: 'Full screen',
    params: []
  },
  exitFullScreen: {
    token: 'euiSheet.exitFullScreen',
    defaultMessage: 'Exit full screen',
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
  },
  cellReadOnly: {
    token: 'euiSheet.cellReadOnly',
    defaultMessage: 'Read only',
    params: []
  },
  addField: {
    token: 'euiSheet.addField',
    defaultMessage: 'Add field',
    params: []
  },
  editField: {
    token: 'euiSheet.editField',
    defaultMessage: 'Edit field',
    params: []
  },
  insertFieldLeft: {
    token: 'euiSheet.insertFieldLeft',
    defaultMessage: 'Insert left',
    params: []
  },
  insertFieldRight: {
    token: 'euiSheet.insertFieldRight',
    defaultMessage: 'Insert right',
    params: []
  },
  duplicateField: {
    token: 'euiSheet.duplicateField',
    defaultMessage: 'Duplicate field',
    params: []
  },
  duplicateFieldLabel: {
    token: 'euiSheet.duplicateFieldLabel',
    defaultMessage: '{label} copy',
    params: ['label']
  },
  deleteField: {
    token: 'euiSheet.deleteField',
    defaultMessage: 'Delete field',
    params: []
  },
  deleteFieldConfirm: {
    token: 'euiSheet.deleteFieldConfirm',
    defaultMessage:
      'Delete "{label}" and its values in every record? This cannot be undone.',
    params: ['label']
  },
  fieldName: {
    token: 'euiSheet.fieldName',
    defaultMessage: 'Name',
    params: []
  },
  fieldType: {
    token: 'euiSheet.fieldType',
    defaultMessage: 'Type',
    params: []
  },
  fieldDescription: {
    token: 'euiSheet.fieldDescription',
    defaultMessage: 'Description',
    params: []
  },
  fieldRequired: {
    token: 'euiSheet.fieldRequired',
    defaultMessage: 'Required',
    params: []
  },
  fieldOptions: {
    token: 'euiSheet.fieldOptions',
    defaultMessage: 'Options',
    params: []
  },
  addOption: {
    token: 'euiSheet.addOption',
    defaultMessage: 'Add option',
    params: []
  },
  removeOption: {
    token: 'euiSheet.removeOption',
    defaultMessage: 'Remove option',
    params: []
  },
  optionLabel: {
    token: 'euiSheet.optionLabel',
    defaultMessage: 'Option {n}',
    params: ['n']
  },
  optionColor: {
    token: 'euiSheet.optionColor',
    defaultMessage: 'Color',
    params: []
  },
  colorNone: {
    token: 'euiSheet.colorNone',
    defaultMessage: 'No color',
    params: []
  },
  color_default: {
    token: 'euiSheet.color_default',
    defaultMessage: 'Gray',
    params: []
  },
  color_hollow: {
    token: 'euiSheet.color_hollow',
    defaultMessage: 'Outline',
    params: []
  },
  color_primary: {
    token: 'euiSheet.color_primary',
    defaultMessage: 'Blue',
    params: []
  },
  color_accent: {
    token: 'euiSheet.color_accent',
    defaultMessage: 'Pink',
    params: []
  },
  color_success: {
    token: 'euiSheet.color_success',
    defaultMessage: 'Green',
    params: []
  },
  color_warning: {
    token: 'euiSheet.color_warning',
    defaultMessage: 'Yellow',
    params: []
  },
  color_danger: {
    token: 'euiSheet.color_danger',
    defaultMessage: 'Red',
    params: []
  },
  fieldCurrency: {
    token: 'euiSheet.fieldCurrency',
    defaultMessage: 'Currency code',
    params: []
  },
  fieldPrecision: {
    token: 'euiSheet.fieldPrecision',
    defaultMessage: 'Decimals',
    params: []
  },
  fieldRatingMax: {
    token: 'euiSheet.fieldRatingMax',
    defaultMessage: 'Stars',
    params: []
  },
  fieldDateOrder: {
    token: 'euiSheet.fieldDateOrder',
    defaultMessage: 'Date format',
    params: []
  },
  dateOrderDmy: {
    token: 'euiSheet.dateOrderDmy',
    defaultMessage: 'Day/Month/Year',
    params: []
  },
  dateOrderMdy: {
    token: 'euiSheet.dateOrderMdy',
    defaultMessage: 'Month/Day/Year',
    params: []
  },
  fieldDurationFormat: {
    token: 'euiSheet.fieldDurationFormat',
    defaultMessage: 'Format',
    params: []
  },
  save: {
    token: 'euiSheet.save',
    defaultMessage: 'Save',
    params: []
  },
  cancel: {
    token: 'euiSheet.cancel',
    defaultMessage: 'Cancel',
    params: []
  },
  fieldNameRequired: {
    token: 'euiSheet.fieldNameRequired',
    defaultMessage: 'Give the field a name',
    params: []
  },
  fieldTypeChangeWarning: {
    token: 'euiSheet.fieldTypeChangeWarning',
    defaultMessage:
      'Changing the type may change or clear values the new type cannot read.',
    params: []
  },
  fieldType_text: {
    token: 'euiSheet.fieldType_text',
    defaultMessage: 'Single line text',
    params: []
  },
  fieldType_longText: {
    token: 'euiSheet.fieldType_longText',
    defaultMessage: 'Long text',
    params: []
  },
  fieldType_number: {
    token: 'euiSheet.fieldType_number',
    defaultMessage: 'Number',
    params: []
  },
  fieldType_currency: {
    token: 'euiSheet.fieldType_currency',
    defaultMessage: 'Currency',
    params: []
  },
  fieldType_percent: {
    token: 'euiSheet.fieldType_percent',
    defaultMessage: 'Percent',
    params: []
  },
  fieldType_checkbox: {
    token: 'euiSheet.fieldType_checkbox',
    defaultMessage: 'Checkbox',
    params: []
  },
  fieldType_singleSelect: {
    token: 'euiSheet.fieldType_singleSelect',
    defaultMessage: 'Single select',
    params: []
  },
  fieldType_multiSelect: {
    token: 'euiSheet.fieldType_multiSelect',
    defaultMessage: 'Multiple select',
    params: []
  },
  fieldType_date: {
    token: 'euiSheet.fieldType_date',
    defaultMessage: 'Date',
    params: []
  },
  fieldType_duration: {
    token: 'euiSheet.fieldType_duration',
    defaultMessage: 'Duration',
    params: []
  },
  fieldType_rating: {
    token: 'euiSheet.fieldType_rating',
    defaultMessage: 'Rating',
    params: []
  },
  fieldType_url: {
    token: 'euiSheet.fieldType_url',
    defaultMessage: 'URL',
    params: []
  },
  fieldType_email: {
    token: 'euiSheet.fieldType_email',
    defaultMessage: 'Email',
    params: []
  },
  fieldType_phone: {
    token: 'euiSheet.fieldType_phone',
    defaultMessage: 'Phone number',
    params: []
  },
  fieldType_linkedRecord: {
    token: 'euiSheet.fieldType_linkedRecord',
    defaultMessage: 'Link to another record',
    params: []
  },
  fieldType_user: {
    token: 'euiSheet.fieldType_user',
    defaultMessage: 'User',
    params: []
  },
  fieldType_attachment: {
    token: 'euiSheet.fieldType_attachment',
    defaultMessage: 'Attachment',
    params: []
  },
  groupByField: {
    token: 'euiSheet.groupByField',
    defaultMessage: 'Group by this field',
    params: []
  },
  removeGrouping: {
    token: 'euiSheet.removeGrouping',
    defaultMessage: 'Remove grouping',
    params: []
  },
  groupLabel: {
    token: 'euiSheet.groupLabel',
    defaultMessage: '{field}: {value}',
    params: ['field', 'value']
  },
  groupEmpty: {
    token: 'euiSheet.groupEmpty',
    defaultMessage: '(Empty)',
    params: []
  },
  groupCount: {
    token: 'euiSheet.groupCount',
    defaultMessage: '{count}',
    params: ['count']
  },
  groupContinued: {
    token: 'euiSheet.groupContinued',
    defaultMessage: '(continued)',
    params: []
  },
  expandGroup: {
    token: 'euiSheet.expandGroup',
    defaultMessage: 'Expand group',
    params: []
  },
  collapseGroup: {
    token: 'euiSheet.collapseGroup',
    defaultMessage: 'Collapse group',
    params: []
  },
  moveRecord: {
    token: 'euiSheet.moveRecord',
    defaultMessage: 'Drag to move the record',
    params: []
  },
  moveRecords: {
    token: 'euiSheet.moveRecords',
    defaultMessage: 'Drag to move {count} records',
    params: ['count']
  },
  shortcutMoveRecords: {
    token: 'euiSheet.shortcutMoveRecords',
    defaultMessage: 'Move the rows up or down (on a row number)',
    params: []
  },
  notADateTime: {
    token: 'euiSheet.notADateTime',
    defaultMessage: '"{text}" is not a date and time',
    params: ['text']
  },
  unknownTimeZone: {
    token: 'euiSheet.unknownTimeZone',
    defaultMessage: 'Unknown time zone "{zone}"',
    params: ['zone']
  },
  fieldType_dateTime: {
    token: 'euiSheet.fieldType_dateTime',
    defaultMessage: 'Date and time',
    params: []
  },
  fieldTimeZone: {
    token: 'euiSheet.fieldTimeZone',
    defaultMessage: 'Time zone',
    params: []
  },
  fieldTimeZoneHelp: {
    token: 'euiSheet.fieldTimeZoneHelp',
    defaultMessage: 'local, utc, or a name like America/Mexico_City',
    params: []
  },
  fieldClock: {
    token: 'euiSheet.fieldClock',
    defaultMessage: 'Clock',
    params: []
  },
  clock24: {
    token: 'euiSheet.clock24',
    defaultMessage: '24-hour',
    params: []
  },
  clock12: {
    token: 'euiSheet.clock12',
    defaultMessage: '12-hour (am/pm)',
    params: []
  },
  fieldSeconds: {
    token: 'euiSheet.fieldSeconds',
    defaultMessage: 'Show seconds',
    params: []
  },
  buttonNoValue: {
    token: 'euiSheet.buttonNoValue',
    defaultMessage: 'A button has no value',
    params: []
  },
  fieldType_button: {
    token: 'euiSheet.fieldType_button',
    defaultMessage: 'Button',
    params: []
  },
  fieldButtonLabel: {
    token: 'euiSheet.fieldButtonLabel',
    defaultMessage: 'Button text',
    params: []
  },
  fieldButtonIcon: {
    token: 'euiSheet.fieldButtonIcon',
    defaultMessage: 'Icon (an EUI icon name)',
    params: []
  },
  fieldButtonColor: {
    token: 'euiSheet.fieldButtonColor',
    defaultMessage: 'Colour',
    params: []
  },
  fieldType_barcode: {
    token: 'euiSheet.fieldType_barcode',
    defaultMessage: 'Barcode',
    params: []
  },
  scanBarcode: {
    token: 'euiSheet.scanBarcode',
    defaultMessage: 'Scan a code',
    params: []
  },
  cameraDenied: {
    token: 'euiSheet.cameraDenied',
    defaultMessage: 'The camera is not available or was not allowed',
    params: []
  },
  uploading: {
    token: 'euiSheet.uploading',
    defaultMessage: 'Uploading… {percent}%',
    params: ['percent']
  },
  selectionHandle: {
    token: 'euiSheet.selectionHandle',
    defaultMessage: 'Drag to change the selection',
    params: []
  },
  copyCells: {
    token: 'euiSheet.copyCells',
    defaultMessage: 'Copy',
    params: []
  },
  pasteCells: {
    token: 'euiSheet.pasteCells',
    defaultMessage: 'Paste',
    params: []
  },
  importFile: {
    token: 'euiSheet.importFile',
    defaultMessage: 'File',
    params: []
  },
  importEncoding: {
    token: 'euiSheet.importEncoding',
    defaultMessage: 'Encoding',
    params: []
  },
  importDelimiter: {
    token: 'euiSheet.importDelimiter',
    defaultMessage: 'Delimiter',
    params: []
  },
  importDelimiterComma: {
    token: 'euiSheet.importDelimiterComma',
    defaultMessage: 'Comma (,)',
    params: []
  },
  importDelimiterSemicolon: {
    token: 'euiSheet.importDelimiterSemicolon',
    defaultMessage: 'Semicolon (;)',
    params: []
  },
  importDelimiterTab: {
    token: 'euiSheet.importDelimiterTab',
    defaultMessage: 'Tab',
    params: []
  },
  importHeaderLine: {
    token: 'euiSheet.importHeaderLine',
    defaultMessage: 'First line is the header',
    params: []
  },
  importLineCount: {
    token: 'euiSheet.importLineCount',
    defaultMessage: '{n} lines',
    params: ['n']
  },
  importLineCountOne: {
    token: 'euiSheet.importLineCountOne',
    defaultMessage: '{n} line',
    params: ['n']
  },
  importReading: {
    token: 'euiSheet.importReading',
    defaultMessage: 'Reading the file…',
    params: []
  },
  importNoLines: {
    token: 'euiSheet.importNoLines',
    defaultMessage: 'The file has no lines to import',
    params: []
  },
  importColumns: {
    token: 'euiSheet.importColumns',
    defaultMessage: 'Columns',
    params: []
  },
  importColumnN: {
    token: 'euiSheet.importColumnN',
    defaultMessage: 'Column {n}',
    params: ['n']
  },
  importFileColumn: {
    token: 'euiSheet.importFileColumn',
    defaultMessage: 'In the file',
    params: []
  },
  importType: {
    token: 'euiSheet.importType',
    defaultMessage: 'Type',
    params: []
  },
  importTarget: {
    token: 'euiSheet.importTarget',
    defaultMessage: 'Goes to',
    params: []
  },
  importTargetFor: {
    token: 'euiSheet.importTargetFor',
    defaultMessage: 'Where "{header}" goes',
    params: ['header']
  },
  importSkip: {
    token: 'euiSheet.importSkip',
    defaultMessage: 'Skip',
    params: []
  },
  importNewField: {
    token: 'euiSheet.importNewField',
    defaultMessage: 'New field…',
    params: []
  },
  importNewFieldNamed: {
    token: 'euiSheet.importNewFieldNamed',
    defaultMessage: 'New field: {label} ({type})',
    params: ['label', 'type']
  },
  importEditNewField: {
    token: 'euiSheet.importEditNewField',
    defaultMessage: 'Edit the new field',
    params: []
  },
  importTakenBy: {
    token: 'euiSheet.importTakenBy',
    defaultMessage: '{field} (in use by "{header}")',
    params: ['field', 'header']
  },
  importTaken: {
    token: 'euiSheet.importTaken',
    defaultMessage: 'Its field already gets "{header}"',
    params: ['header']
  },
  importTransform: {
    token: 'euiSheet.importTransform',
    defaultMessage: 'Transform',
    params: []
  },
  importTransformFor: {
    token: 'euiSheet.importTransformFor',
    defaultMessage: 'Transform for "{header}"',
    params: ['header']
  },
  importNoTransform: {
    token: 'euiSheet.importNoTransform',
    defaultMessage: 'None',
    params: []
  },
  importOptions: {
    token: 'euiSheet.importOptions',
    defaultMessage: 'Options',
    params: []
  },
  importTrim: {
    token: 'euiSheet.importTrim',
    defaultMessage: 'Trim spaces',
    params: []
  },
  importEmptyIsNull: {
    token: 'euiSheet.importEmptyIsNull',
    defaultMessage: 'Empty is no value',
    params: []
  },
  importDecimalSeparator: {
    token: 'euiSheet.importDecimalSeparator',
    defaultMessage: 'Decimal separator',
    params: []
  },
  importDecimalPoint: {
    token: 'euiSheet.importDecimalPoint',
    defaultMessage: 'Point (1.5)',
    params: []
  },
  importDecimalComma: {
    token: 'euiSheet.importDecimalComma',
    defaultMessage: 'Comma (1,5)',
    params: []
  },
  importValues: {
    token: 'euiSheet.importValues',
    defaultMessage: 'Values ({n} mapped)',
    params: ['n']
  },
  importValuesOne: {
    token: 'euiSheet.importValuesOne',
    defaultMessage: 'Values ({n} mapped)',
    params: ['n']
  },
  importValueMapFor: {
    token: 'euiSheet.importValueMapFor',
    defaultMessage: 'Values of "{header}"',
    params: ['header']
  },
  importValueInFile: {
    token: 'euiSheet.importValueInFile',
    defaultMessage: 'In the file',
    params: []
  },
  importValueBecomes: {
    token: 'euiSheet.importValueBecomes',
    defaultMessage: 'Becomes',
    params: []
  },
  importValueAsIs: {
    token: 'euiSheet.importValueAsIs',
    defaultMessage: 'As in the file',
    params: []
  },
  importValueNone: {
    token: 'euiSheet.importValueNone',
    defaultMessage: 'No value',
    params: []
  },
  importValueEmpty: {
    token: 'euiSheet.importValueEmpty',
    defaultMessage: '(empty)',
    params: []
  },
  importNew: {
    token: 'euiSheet.importNew',
    defaultMessage: 'new',
    params: []
  },
  importValueChecked: {
    token: 'euiSheet.importValueChecked',
    defaultMessage: 'Checked',
    params: []
  },
  importValueUnchecked: {
    token: 'euiSheet.importValueUnchecked',
    defaultMessage: 'Unchecked',
    params: []
  },
  importStatus: {
    token: 'euiSheet.importStatus',
    defaultMessage: 'Status',
    params: []
  },
  importRead: {
    token: 'euiSheet.importRead',
    defaultMessage: '{read} of {total} read',
    params: ['read', 'total']
  },
  importReadOne: {
    token: 'euiSheet.importReadOne',
    defaultMessage: '{read} of {total} read',
    params: ['read', 'total']
  },
  importCantRead: {
    token: 'euiSheet.importCantRead',
    defaultMessage: '{n} can’t be read',
    params: ['n']
  },
  importCantReadOne: {
    token: 'euiSheet.importCantReadOne',
    defaultMessage: '{n} can’t be read',
    params: ['n']
  },
  importGuess: {
    token: 'euiSheet.importGuess',
    defaultMessage: '{type} · {percent}%',
    params: ['type', 'percent']
  },
  importPreview: {
    token: 'euiSheet.importPreview',
    defaultMessage: 'Preview',
    params: []
  },
  importPreviewOf: {
    token: 'euiSheet.importPreviewOf',
    defaultMessage: 'The first {n} of {total} lines',
    params: ['n', 'total']
  },
  importPreviewOfOne: {
    token: 'euiSheet.importPreviewOfOne',
    defaultMessage: 'The only line',
    params: ['n', 'total']
  },
  importPreviewErrors: {
    token: 'euiSheet.importPreviewErrors',
    defaultMessage: 'Lines where "{header}" can’t be read',
    params: ['header']
  },
  importShowFirstLines: {
    token: 'euiSheet.importShowFirstLines',
    defaultMessage: 'Show the first lines',
    params: []
  },
  importLine: {
    token: 'euiSheet.importLine',
    defaultMessage: 'Line',
    params: []
  },
  importLinkedOnImport: {
    token: 'euiSheet.importLinkedOnImport',
    defaultMessage: 'linked on import',
    params: []
  },
  importNewOption: {
    token: 'euiSheet.importNewOption',
    defaultMessage: 'new option',
    params: []
  },
  importLinesReady: {
    token: 'euiSheet.importLinesReady',
    defaultMessage: '{n} lines ready',
    params: ['n']
  },
  importLinesReadyOne: {
    token: 'euiSheet.importLinesReadyOne',
    defaultMessage: '{n} line ready',
    params: ['n']
  },
  importLinesWithErrors: {
    token: 'euiSheet.importLinesWithErrors',
    defaultMessage: '{n} with errors',
    params: ['n']
  },
  importLinesWithErrorsOne: {
    token: 'euiSheet.importLinesWithErrorsOne',
    defaultMessage: '{n} with errors',
    params: ['n']
  },
  importDownloadErrors: {
    token: 'euiSheet.importDownloadErrors',
    defaultMessage: 'Download the lines with errors',
    params: []
  },
  importAll: {
    token: 'euiSheet.importAll',
    defaultMessage: 'Import all (errors stay as rejections)',
    params: []
  },
  importSkipErrors: {
    token: 'euiSheet.importSkipErrors',
    defaultMessage: 'Skip lines with errors',
    params: []
  },
  importLines: {
    token: 'euiSheet.importLines',
    defaultMessage: 'Import {n} lines',
    params: ['n']
  },
  importLinesOne: {
    token: 'euiSheet.importLinesOne',
    defaultMessage: 'Import {n} line',
    params: ['n']
  },
  importNoTarget: {
    token: 'euiSheet.importNoTarget',
    defaultMessage: 'No column goes to a field',
    params: []
  },
  importCreateMismatch: {
    token: 'euiSheet.importCreateMismatch',
    defaultMessage: 'The new fields could not be created',
    params: []
  },
  importChecking: {
    token: 'euiSheet.importChecking',
    defaultMessage: 'Checking the lines…',
    params: []
  },
  rowNumberChecked: {
    token: 'euiSheet.rowNumberChecked',
    defaultMessage: 'Row {n}, checked',
    params: ['n']
  },
  rowNumberHeader: {
    token: 'euiSheet.rowNumberHeader',
    defaultMessage: 'Row number',
    params: []
  },
  cellChecked: {
    token: 'euiSheet.cellChecked',
    defaultMessage: 'Checked',
    params: []
  },
  cellUnchecked: {
    token: 'euiSheet.cellUnchecked',
    defaultMessage: 'Not checked',
    params: []
  },
  rowMenu: {
    token: 'euiSheet.rowMenu',
    defaultMessage: 'Row menu',
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
