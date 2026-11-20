/** The fields: visible, hidden, their order, and the field lookups (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { next } from '@ember/runloop';

import { resolveType, sameFieldValue } from '../../core/index.ts';
import { sameIds } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField } from '../../core/index.ts';
import type { EuiSheetFieldType } from '../../types.ts';
import type { EuiDataGridColumnVisibility } from '@ember-eui/core/utils/data-grid/types';

export default class SheetFields<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Field order without `@onFieldOrderChange`; null: the order of `@fields`. */
  @tracked localOrder: string[] | null = null;
  /**
   * Hidden or shown without `@onHiddenFieldsChange`, by field id: `true`
   * hides a field of `@fields`, `false` shows one of `@hiddenFields`.
   */
  @tracked localHidden: ReadonlyMap<string, boolean> = new Map();
  /**
   * Bumped when the grid shows an order the sheet did not apply (a no-op
   * drop, an owner that ignores the intent): a new columns array resets
   * the grid's own order state (V03 5.3).
   */
  @tracked orderEpoch = 0;

  /* -------------------------------------------------------------------- */
  /* Fields: visible, hidden, order (V02-DESIGN.md 3.5, 6.4)               */
  /* -------------------------------------------------------------------- */

  /**
   * The visible fields, in display order: `@fields` as given, with the
   * sheet's own hidden set and order applied for the parts the owner has
   * no handler for.
   */
  @cached
  get visibleFields(): EuiSheetField<T>[] {
    let fields = this.sheet.args.fields;
    if (!this.sheet.args.onHiddenFieldsChange && this.localHidden.size) {
      const local = this.localHidden;
      fields = [
        ...fields.filter((field) => local.get(field.id) !== true),
        ...(this.sheet.args.hiddenFields ?? []).filter(
          (field) => local.get(field.id) === false
        )
      ];
    }
    const order = this.sheet.args.onFieldOrderChange ? null : this.localOrder;
    if (order) {
      const rank = new Map(order.map((id, i) => [id, i]));
      fields = fields
        .map((field, i) => ({ field, i }))
        .sort(
          (a, b) =>
            (rank.get(a.field.id) ?? order.length + a.i) -
            (rank.get(b.field.id) ?? order.length + b.i)
        )
        .map(({ field }) => field);
    }
    return fields;
  }

  @cached
  get visibleFieldIds(): string[] {
    return this.visibleFields.map((field) => field.id);
  }

  /** The fields that are not shown: `@hiddenFields`, or the sheet's own hidden ones. */
  @cached
  get hiddenFields(): EuiSheetField<T>[] {
    const hidden = this.sheet.args.hiddenFields ?? [];
    if (this.sheet.args.onHiddenFieldsChange || !this.localHidden.size)
      return hidden;
    const visible = new Set(this.visibleFieldIds);
    return [...this.sheet.args.fields, ...hidden].filter(
      (field) => !visible.has(field.id)
    );
  }

  /** Whether the header menu and `hideField` may hide this field: never the first one. */
  canHide(fieldId: string): boolean {
    const index = this.visibleFieldIds.indexOf(fieldId);
    return index > 0 && this.visibleFields[index]!.hideable !== false;
  }

  /** "Hide": `@onHiddenFieldsChange`, or the sheet's own hidden set (C6). */
  hideField = (fieldId: string): void => {
    if (!this.canHide(fieldId)) return;
    this.hideFields([fieldId]);
  };

  hideFields(fieldIds: string[]): void {
    const handler = this.sheet.args.onHiddenFieldsChange;
    if (handler) {
      const ids = this.hiddenFields.map((field) => field.id);
      this.expectUpdate('hiddenFields');
      handler([...ids, ...fieldIds.filter((id) => !ids.includes(id))]);
      return;
    }
    const next = new Map(this.localHidden);
    for (const id of fieldIds) {
      if (this.sheet.args.fields.some((field) => field.id === id))
        next.set(id, true);
      else next.delete(id);
    }
    this.localHidden = next;
  }

  /** A block's `showField`: `@onHiddenFieldsChange`, or the sheet's own hidden set. */
  showField = (fieldId: string): void => {
    if (!this.hiddenFields.some((field) => field.id === fieldId)) return;
    const handler = this.sheet.args.onHiddenFieldsChange;
    if (handler) {
      this.expectUpdate('hiddenFields');
      handler(
        this.hiddenFields
          .map((field) => field.id)
          .filter((id) => id !== fieldId)
      );
      return;
    }
    const next = new Map(this.localHidden);
    if (this.sheet.args.fields.some((field) => field.id === fieldId)) {
      next.delete(fieldId);
    } else {
      next.set(fieldId, false);
    }
    this.localHidden = next;
  };

  /** "Move left/right": `@onFieldOrderChange`, or the sheet's own order. */
  setFieldOrder(fieldIds: string[]): void {
    const handler = this.sheet.args.onFieldOrderChange;
    if (handler) {
      this.expectUpdate('fields');
      handler(fieldIds);
      return;
    }
    this.localOrder = fieldIds;
  }

  /** Drag a header to reorder (V03 5.3): `@fieldDrag`, default true, with more than one field. */
  get fieldDrag(): boolean {
    return (this.sheet.args.fieldDrag ?? true) && this.visibleFields.length > 1;
  }

  @cached
  get columnVisibility(): EuiDataGridColumnVisibility {
    return {
      visibleColumns: this.visibleFieldIds,
      setVisibleColumns: this.setVisibleColumns,
      canDragAndDropColumns: this.fieldDrag
    };
  }

  /**
   * The grid's "Hide column" and "Move left/right" call this with the new
   * visible ids: an id missing is a hide intent, another order an order
   * intent (6.3).
   */
  setVisibleColumns = (ids: string[]): void => {
    const current = this.visibleFieldIds;
    const removed = current.filter((id) => !ids.includes(id));
    if (removed.length) {
      const hideable = removed.filter((id) => this.canHide(id));
      if (hideable.length) this.hideFields(hideable);
      return;
    }
    // the first field stays first (6.3); a drag can send any order (V03 5.3)
    const first = current[0];
    const kept = ids.filter((id) => current.includes(id) && id !== first);
    if (first !== undefined) kept.unshift(first);
    if (!sameIds(kept, current)) this.setFieldOrder(kept);
    this.checkOrderShown(ids);
  };

  /**
   * After the next render: when the visible order is not the one the grid
   * sent (the order above was a no-op, or the owner ignored it), the
   * grid's own order state is stale and the next drag would start from it.
   * A new columns array resets it (V03 5.3).
   */
  checkOrderShown(sent: string[]): void {
    next(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      if (!sameIds(this.visibleFieldIds, sent)) this.orderEpoch++;
    });
  }

  /* A handler was called and its argument did not change (6.11) */

  warnedUnchanged = new Set<string>();

  /**
   * In development, warns once per argument when a presentation handler
   * was called and the argument is the same after the next render: the
   * owner passed the handler but does not update the argument, so nothing
   * changes on screen.
   */
  expectUpdate(
    name: 'fields' | 'hiddenFields' | 'fieldWidths' | 'rowHeight'
  ): void {
    if (this.warnedUnchanged.has(name)) return;
    const read = (): unknown =>
      name === 'hiddenFields'
        ? [this.sheet.args.fields, this.sheet.args.hiddenFields]
        : this.sheet.args[name];
    const before = read();
    next(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      const after = read();
      const same = Array.isArray(before)
        ? before.every((value, i) => value === (after as unknown[])[i])
        : before === after;
      if (!same || this.warnedUnchanged.has(name)) return;
      this.warnedUnchanged.add(name);
      warn(
        `EuiSheet: a handler for @${name} was called, but @${name} did not change. With the handler the sheet shows exactly the argument: update it.`,
        false,
        { id: 'ember-eui.sheet.controlled-argument' }
      );
    });
  }

  /** The visible fields, then the hidden ones: the expanded record, duplicate, undo. */
  @cached
  get allFields(): EuiSheetField<T>[] {
    return [...this.visibleFields, ...this.hiddenFields];
  }

  typeOf(field: EuiSheetField): EuiSheetFieldType {
    return resolveType(this.sheet.types, field) as EuiSheetFieldType;
  }

  /** The field's type's `equals`, else `Object.is` (by field id, visible or hidden). */
  valueEquals(fieldId: string, a: unknown, b: unknown): boolean {
    const field = this.allFields.find((f) => f.id === fieldId);
    if (!field) return Object.is(a, b);
    return sameFieldValue(this.typeOf(field), a, b);
  }

  /* The shortcut list (V03 5.5) */

  /* -------------------------------------------------------------------- */
  /* Field management (V03 6)                                              */
  /* -------------------------------------------------------------------- */

  /** A field of `@fields` or `@hiddenFields` (shown or not) by id. */
  fieldById(fieldId: string | undefined): EuiSheetField<T> | undefined {
    if (fieldId === undefined) return undefined;
    return (
      this.allFields.find((field) => field.id === fieldId) ??
      [...this.sheet.args.fields, ...(this.sheet.args.hiddenFields ?? [])].find(
        (field) => field.id === fieldId
      )
    );
  }
}
