/**
 * A tracked record array that applies change sets: for tests, demos and
 * apps without a store of their own (PACKAGE-DESIGN.md 5.6).
 */
import { tracked } from '@glimmer/tracking';

import {
  applyChangeSet,
  applyNewOptions,
  convertField,
  defaultMessages
} from './core/index.ts';
import { builtInSheetFieldTypes } from './field-types.ts';

import type {
  ChangeSet,
  EuiSheetField,
  FieldTypeRegistry,
  RecordId,
  RecordInsert,
  SheetFieldDraft,
  SheetMessages
} from './core/index.ts';

export interface LocalRecordsOptions<
  T,
  F extends EuiSheetField<T> = EuiSheetField<T>
> {
  getRecordId: (record: T) => RecordId;
  /** Default: `{ id: tempId, ...values }`. */
  createRecord?: (values: Record<string, unknown>, tempId: string) => T;
  /** The record an undo of a delete puts back. Default: the deleted object, as it was (`insert.restore.record`). */
  restoreRecord?: (insert: RecordInsert) => T;
  /** Lets the store add options created on paste; needed by the field operations (`createField`, …). */
  fields?: F[];
  /** The types `updateField` converts values with. Default: the built-ins; pass the sheet's `@fieldTypes` merged over them. */
  types?: FieldTypeRegistry;
  /** The messages of the conversion's rejections. Default: English. */
  messages?: SheetMessages;
}

/** A field id from a label: lower case, accents and symbols dropped, words joined by `-`. */
function slugOf(label: string): string {
  const slug = label
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'field';
}

export class LocalRecords<
  T extends object,
  F extends EuiSheetField<T> = EuiSheetField<T>
> {
  @tracked records: T[];
  @tracked fields: F[];
  readonly log: ChangeSet[] = [];
  private options: LocalRecordsOptions<T, F>;

  constructor(initial: T[], options: LocalRecordsOptions<T, F>) {
    this.records = initial;
    this.fields = options.fields ?? [];
    this.options = options;
  }

  /** Bound: `@onChange={{store.apply}}`. */
  apply = (changeSet: ChangeSet): void => {
    this.records = applyChangeSet(this.records, changeSet, this.options);
    const fields = applyNewOptions(this.fields, changeSet);
    if (fields !== this.fields) this.fields = fields;
    this.log.push(changeSet);
  };

  /* Field operations (V03 6.7): `@onFieldCreate={{store.createField}}`, … */

  /**
   * Bound: adds the field. Its id is a slug of the label made unique
   * (`estado`, `estado-2`). It goes after `position.after` when that field
   * is in `fields`, else at `position.index`. With `copyOf` every record
   * gets that field's value.
   */
  createField = (
    draft: SheetFieldDraft,
    position: { index: number; after?: string; copyOf?: string }
  ): void => {
    const taken = new Set(this.fields.map((field) => field.id));
    const base = slugOf(draft.label);
    let id = base;
    for (let n = 2; taken.has(id); n++) id = `${base}-${n}`;
    const field = { ...draft, id } as unknown as F;
    const after =
      position.after === undefined
        ? -1
        : this.fields.findIndex((existing) => existing.id === position.after);
    const at =
      after >= 0
        ? after + 1
        : Math.min(Math.max(position.index, 0), this.fields.length);
    const fields = [...this.fields];
    fields.splice(at, 0, field);
    this.fields = fields;
    const copyOf = position.copyOf;
    if (copyOf !== undefined) {
      this.records = this.records.map((record) =>
        copyOf in record
          ? ({
              ...record,
              [id]: (record as Record<string, unknown>)[copyOf]
            } as T)
          : record
      );
    }
  };

  /**
   * Bound: `{ ...field, ...draft }`. On a type change the values are
   * converted (`convertField`): the change set is applied and kept in
   * `log`, with what could not be converted in its `rejected`.
   */
  updateField = (fieldId: string, draft: SheetFieldDraft): void => {
    const index = this.fields.findIndex((field) => field.id === fieldId);
    if (index < 0) return;
    const previous = this.fields[index]!;
    const next = { ...previous, ...draft, id: fieldId } as F;
    let fields = [...this.fields];
    fields[index] = next;
    if ((previous.type ?? 'text') !== (next.type ?? 'text')) {
      const changeSet = convertField(
        {
          types: { ...builtInSheetFieldTypes, ...this.options.types },
          messages: this.options.messages ?? defaultMessages,
          getRecordId: this.options.getRecordId
        },
        this.records,
        previous,
        next
      );
      this.records = applyChangeSet(this.records, changeSet, this.options);
      fields = applyNewOptions(fields, changeSet);
      this.log.push(changeSet);
    }
    this.fields = fields;
  };

  /** Bound: removes the field and its key from every record. */
  deleteField = (fieldId: string): void => {
    if (!this.fields.some((field) => field.id === fieldId)) return;
    this.fields = this.fields.filter((field) => field.id !== fieldId);
    this.records = this.records.map((record) => {
      if (!(fieldId in record)) return record;
      const copy = { ...record } as Record<string, unknown>;
      delete copy[fieldId];
      return copy as T;
    });
  };
}

export function localRecords<
  T extends object,
  F extends EuiSheetField<T> = EuiSheetField<T>
>(initial: T[], options: LocalRecordsOptions<T, F>): LocalRecords<T, F> {
  return new LocalRecords(initial, options);
}
