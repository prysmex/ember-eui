/**
 * `@ember-eui/sheet`: an Airtable-like data-entry grid on `EuiDataGrid`.
 * The Ember-free core is also importable alone as `@ember-eui/sheet/core`.
 */
export * from './core/index.ts';

export { default as EuiSheet } from './components/eui-sheet.gts';
export type { CellView } from './components/eui-sheet.gts';
export { LocalRecords, localRecords } from './local-records.ts';
export type { LocalRecordsOptions } from './local-records.ts';
export {
  builtInSheetFieldTypes,
  checkboxType,
  dateType,
  numberType,
  SheetInputEditor,
  singleSelectType,
  textType
} from './field-types.ts';
export type {
  EuiSheetFieldType,
  EuiSheetSignature,
  SheetApi,
  SheetCellSignature,
  SheetEditorRect,
  SheetEditorResult,
  SheetEditorSignature,
  SheetRowAction
} from './types.ts';
