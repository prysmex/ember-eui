/** The header menu's group and field items (V03C-DESIGN.md 3.2). */
import { next } from '@ember/runloop';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField } from '../../core/index.ts';
import type { EuiDataGridColumnActions } from '@ember-eui/core/utils/data-grid/types';

export default class SheetHeaderMenu<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /**
   * The header menu's group item (V03 8.3), only with `@onGroupByChange`
   * and not on a field with `groupable: false`: "Remove grouping" (`[]`)
   * on a field of `@groupBy`, else "Group by this field" (one level,
   * ascending).
   */
  groupMenuItems(
    field: EuiSheetField<T>
  ): NonNullable<EuiDataGridColumnActions['additional']> {
    const handler = this.sheet.args.onGroupByChange;
    if (!handler || field.groupable === false) return [];
    const grouped = (this.sheet.args.groupBy ?? []).some(
      (level) => level.field === field.id
    );
    const messages = this.sheet.messages;
    return [
      grouped
        ? {
            label: messages.removeGrouping(),
            iconType: 'cross',
            color: 'text',
            onClick: () => next(() => handler([])),
            'data-test-subj': `euiSheetRemoveGrouping-${field.id}`
          }
        : {
            label: messages.groupByField(),
            iconType: 'aggregate',
            color: 'text',
            onClick: () =>
              next(() => handler([{ field: field.id, direction: 'asc' }])),
            'data-test-subj': `euiSheetGroupByField-${field.id}`
          }
    ];
  }

  /**
   * The header menu's field items (V03 6.3): Edit, Duplicate, Insert
   * left, Insert right, Delete last, each only with its handler. Not on a
   * field with `manageable: false` (Edit, Duplicate, Delete); the first
   * field cannot be deleted and nothing goes to its left.
   */
  fieldMenuItems(
    field: EuiSheetField<T>,
    index: number,
    fields: readonly EuiSheetField<T>[]
  ): NonNullable<EuiDataGridColumnActions['additional']> {
    const { onFieldCreate, onFieldUpdate, onFieldDelete } = this.sheet.args;
    const manageable = field.manageable !== false;
    const messages = this.sheet.messages;
    const items: NonNullable<EuiDataGridColumnActions['additional']> = [];
    const item = (
      id: string,
      label: string,
      iconType: string,
      onClick: () => void
    ) =>
      items.push({
        label,
        iconType,
        color: 'text',
        // after the popover has closed and returned focus to its button
        onClick: () => next(onClick),
        'data-test-subj': `euiSheet${id}-${field.id}`
      });
    if (onFieldUpdate && manageable) {
      item('EditField', messages.editField(), 'pencil', () =>
        this.sheet.editField(field.id)
      );
    }
    if (onFieldCreate && manageable) {
      item('DuplicateField', messages.duplicateField(), 'copy', () =>
        this.sheet.duplicateField(field.id)
      );
    }
    if (onFieldCreate) {
      if (index > 0) {
        item('InsertFieldLeft', messages.insertFieldLeft(), 'arrowLeft', () =>
          this.sheet.addField(index, field.id, fields[index - 1]!.id)
        );
      }
      item('InsertFieldRight', messages.insertFieldRight(), 'arrowRight', () =>
        this.sheet.addField(index + 1, field.id, field.id)
      );
    }
    if (onFieldDelete && manageable && index > 0) {
      item('DeleteField', messages.deleteField(), 'trash', () =>
        this.sheet.askDeleteField(field.id)
      );
    }
    return items;
  }
}
