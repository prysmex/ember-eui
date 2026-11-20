/** The sheet's API (`@registerApi`) and the blocks' API (V03C-DESIGN.md 3.2). */
import { cached } from '@glimmer/tracking';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { SheetApi, SheetBlockApi } from '../../types.ts';

export default class SheetApiModule<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The sheet's API for its owner (`@registerApi`): one stable object. */
  sheetApi: SheetApi = {
    undo: () => this.sheet.history.undo(),
    redo: () => this.sheet.history.redo(),
    focusCell: (cell) => this.sheet.selection.focusRecordCell(cell),
    scrollToCell: (cell) => this.sheet.scroll.scrollToCell(cell),
    getSelection: () => this.sheet.selection.current,
    remapIds: (ids) => this.sheet.history.remapIds(ids),
    clearHistory: () => this.sheet.history.clearHistory(),
    expandRecord: (recordId) => {
      if (recordId === null) this.sheet.expanded.closeExpanded();
      else this.sheet.expanded.expandRecord(recordId, null);
    },
    insertRecord: (options = {}) => this.sheet.records.insertFromApi(options),
    deleteRecords: (ids) => this.sheet.records.deleteRecordIds(ids, false),
    showShortcuts: () => this.sheet.keys.showShortcuts(),
    editField: (fieldId) => this.sheet.fieldEditor.editField(fieldId),
    addField: (options = {}) => this.sheet.fieldEditor.addField(options.index),
    moveRecords: (ids, target) => this.sheet.rowDrag.moveFromApi(ids, target),
    fitField: (fieldId) => this.sheet.gridColumns.fitField(fieldId),
    fitFields: () => this.sheet.gridColumns.fitFields()
  };

  /* Blocks (3.6) */

  @cached
  get blockApi(): SheetBlockApi<T> {
    const selection = this.sheet.selection;
    return {
      // a getter: the block API object does not change with the selection,
      // only what reads `selection` does (V03 11.2)
      get selection() {
        return selection.current;
      },
      api: this.sheetApi,
      fields: this.sheet.fields.visibleFields,
      hiddenFields: this.sheet.fields.hiddenFields,
      sort: this.sheet.args.sort ?? [],
      rowHeight: this.sheet.gridOptions.rowHeight,
      checkedRecords: this.sheet.checked.checkedRecords,
      hideField: this.sheet.fields.hideField,
      showField: this.sheet.fields.showField,
      setRowHeight: this.sheet.gridOptions.setRowHeight,
      setSort: this.sheet.gridColumns.setSort,
      showShortcuts: this.sheet.keys.showShortcuts,
      addField: () => this.sheet.fieldEditor.addField(),
      groupBy: this.sheet.args.groupBy ?? [],
      groups: this.sheet.args.groups ?? [],
      setGroupBy: this.sheet.groupHeaders.setGroupBy,
      toggleGroup: this.sheet.groupHeaders.toggleGroupByKey
    };
  }
}
