/**
 * Button fields (V03 10.3.1, D17): pressing a button cell calls
 * `@onButtonPress` (or opens `field.url`); a returned promise keeps the
 * cell pending, and its rejection is the cell's error until the next press.
 * A press is not a change set and is not undoable.
 */
import { tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { isDestroyed, isDestroying } from '@ember/destroyable';

import { cellKey, safeLink, valueOf } from '../../core/index.ts';
import { isPromise } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField, Pos, RecordId } from '../../core/index.ts';
import type { EuiSheetFieldType } from '../../types.ts';

/** A rejection's text: its message, else the value as text. */
function messageOf(reason: unknown): string {
  if (reason instanceof Error) return reason.message || reason.name;
  return typeof reason === 'string' ? reason : String(reason);
}

export default class SheetButtons<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Cells whose press is pending (by cellKey), with the signal's controller. */
  @tracked pending: ReadonlyMap<string, AbortController> = new Map();
  /** The last press's rejection per cell, until the next press. */
  @tracked errors: ReadonlyMap<string, string> = new Map();
  /** The "no handler and no url" warning was given. */
  warned = false;

  /** A type whose cells are buttons: its `onCellClick` answers `{ press: true }`. */
  pressable(type: EuiSheetFieldType, field: EuiSheetField, record: T): boolean {
    const click = type.onCellClick;
    if (!click) return false;
    const result = click(valueOf(record, field.id) as never, field, record);
    return !!result && 'press' in result && result.press === true;
  }

  /** `field.url(record)`, when it is a link the sheet opens. */
  urlOf(field: EuiSheetField, record: T): string | undefined {
    const url = field['url'];
    return typeof url === 'function'
      ? safeLink((url as (record: T) => string | undefined)(record))
      : undefined;
  }

  /**
   * No press for this record: `field.disabled(record)`, or neither
   * `@onButtonPress` nor a `field.url` (then a warning, once).
   */
  isDisabled(field: EuiSheetField, record: T): boolean {
    const disabled = field['disabled'];
    if (
      typeof disabled === 'function' &&
      (disabled as (r: T) => boolean)(record)
    )
      return true;
    if (this.sheet.args.onButtonPress || this.urlOf(field, record))
      return false;
    if (!this.warned) {
      this.warned = true;
      warn(
        `EuiSheet: the button field "${field.id}" has no action: pass @onButtonPress or give the field a url. It is drawn disabled.`,
        false,
        { id: 'ember-eui.sheet.button-no-action' }
      );
    }
    return true;
  }

  isPending(recordId: RecordId, fieldId: string): boolean {
    return this.pending.has(cellKey(recordId, fieldId));
  }

  errorOf(recordId: RecordId, fieldId: string): string | undefined {
    return this.errors.get(cellKey(recordId, fieldId));
  }

  /** The button cell at a grid position is pressed; false when it is not a button cell. */
  pressAt(pos: Pos): boolean {
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    if (!this.pressable(this.sheet.fields.typeOf(field), field, record))
      return false;
    this.press(record, field);
    return true;
  }

  /**
   * Presses a record's button: nothing when disabled or pending; else the
   * error is cleared and `@onButtonPress` called (it wins over `url`), or
   * the url opened in a new tab.
   */
  press(record: T, field: EuiSheetField): void {
    if (this.isDisabled(field, record)) return;
    const recordId = this.sheet.args.getRecordId(record);
    const key = cellKey(recordId, field.id);
    if (this.pending.has(key)) return;
    if (this.errors.has(key)) {
      const errors = new Map(this.errors);
      errors.delete(key);
      this.errors = errors;
    }
    const handler = this.sheet.args.onButtonPress;
    if (!handler) {
      this.sheet.cells.openLink(this.urlOf(field, record));
      return;
    }
    const controller = new AbortController();
    let result: unknown;
    try {
      result = handler(
        { recordId, fieldId: field.id, record },
        { signal: controller.signal }
      );
    } catch (error) {
      this.errors = new Map(this.errors).set(key, messageOf(error));
      return;
    }
    if (!isPromise(result)) return;
    this.pending = new Map(this.pending).set(key, controller);
    result.then(
      () => this.settle(key, controller, undefined),
      (reason: unknown) => this.settle(key, controller, messageOf(reason))
    );
  }

  /** A press's promise settled: the cell is no longer pending; a rejection is its error. */
  settle(
    key: string,
    controller: AbortController,
    error: string | undefined
  ): void {
    if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
    if (this.pending.get(key) !== controller) return;
    const pending = new Map(this.pending);
    pending.delete(key);
    this.pending = pending;
    if (error !== undefined) this.errors = new Map(this.errors).set(key, error);
  }

  /** The sheet is destroyed: every pending press's signal is aborted. */
  abortAll(): void {
    for (const controller of this.pending.values()) controller.abort();
  }
}
