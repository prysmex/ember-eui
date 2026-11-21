/**
 * The names of every `EuiSheet` argument and named block, kept next to
 * its signature (READINESS.md item 5): `satisfies` makes `lint:types` fail
 * when an argument or block is added to `EuiSheetSignature` and not here,
 * and the connector's test (`EuiSheetSearch`) checks each one is passed
 * on. Not exported from the package.
 */
import type { EuiSheetSignature } from '../types.ts';

type Args = EuiSheetSignature<object>['Args'];
type Blocks = EuiSheetSignature<object>['Blocks'];

const ARGS = {
  fields: true,
  records: true,
  getRecordId: true,
  onChange: true,
  cellErrors: true,
  height: true,
  fieldTypes: true,
  readOnly: true,
  messages: true,
  ariaLabel: true,
  validate: true,
  registerApi: true,
  hiddenFields: true,
  onHiddenFieldsChange: true,
  onFieldOrderChange: true,
  fieldDrag: true,
  headerLines: true,
  onFieldCreate: true,
  onFieldUpdate: true,
  onFieldDelete: true,
  fieldEditor: true,
  creatableFieldTypes: true,
  fieldWidths: true,
  onFieldWidthChange: true,
  rowHeight: true,
  onRowHeightChange: true,
  sort: true,
  onSortChange: true,
  onFilterByField: true,
  highlight: true,
  currentMatch: true,
  onSelectionChange: true,
  onVisibleRangeChange: true,
  fullScreen: true,
  onFullScreenChange: true,
  isLoading: true,
  summary: true,
  frozenFields: true,
  rowNumbers: true,
  rowLabel: true,
  rowNumberOffset: true,
  groups: true,
  groupBy: true,
  onGroupByChange: true,
  onGroupToggle: true,
  canInsert: true,
  canDelete: true,
  canMove: true,
  rowColor: true,
  cellColor: true,
  onButtonPress: true,
  newRecordValues: true,
  checkedRecordIds: true,
  onCheckedChange: true,
  expandedRecordId: true,
  onExpandedRecordChange: true,
  expandedRecord: true,
  rowActions: true,
  fieldActions: true,
  copyWithFieldNames: true,
  onResolve: true,
  editIn: true
} as const satisfies Record<keyof Args, true>;

const BLOCKS = {
  toolbar: true,
  footer: true,
  empty: true,
  recordFooter: true
} as const satisfies Record<keyof Blocks, true>;

/** Every `EuiSheet` argument's name. */
export const SHEET_ARG_NAMES = Object.keys(ARGS) as Array<keyof Args>;

/** Every `EuiSheet` named block's name. */
export const SHEET_BLOCK_NAMES = Object.keys(BLOCKS) as Array<keyof Blocks>;
