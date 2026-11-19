/**
 * `@ember-eui/sheet/search-ui`: the sheet as an EmberSearchUi results view
 * (V02-DESIGN.md 7). Typed against `SheetSearchDriver`, the part of
 * `ember-search-ui-driver`'s `SearchDriver` it uses: neither package
 * depends on the other.
 */
export { SearchRecords, searchRecords } from './search-records.ts';
export type {
  SearchRecordsOptions,
  SheetSearchDriver,
  SheetSearchFieldDefinition,
  SheetSearchPage,
  SheetSearchSnapshot
} from './search-records.ts';
export { fieldsFromSchema } from './fields-from-schema.ts';
export { default as EuiSheetSearch } from './eui-sheet-search.gts';
export type {
  EuiSheetSearchSignature,
  SheetSearchBlockApi
} from './eui-sheet-search.gts';
