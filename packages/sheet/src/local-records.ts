/**
 * A tracked record array that applies change sets: for tests, demos and
 * apps without a store of their own (PACKAGE-DESIGN.md 5.6).
 */
import { tracked } from '@glimmer/tracking';

import { applyChangeSet, applyNewOptions } from './core/index.ts';

import type { ChangeSet, EuiSheetField, RecordId } from './core/index.ts';

export interface LocalRecordsOptions<
  T,
  F extends EuiSheetField<T> = EuiSheetField<T>
> {
  getRecordId: (record: T) => RecordId;
  /** Default: `{ id: tempId, ...values }`. */
  createRecord?: (values: Record<string, unknown>, tempId: string) => T;
  /** Optional: lets the store add options created on paste. */
  fields?: F[];
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
}

export function localRecords<
  T extends object,
  F extends EuiSheetField<T> = EuiSheetField<T>
>(initial: T[], options: LocalRecordsOptions<T, F>): LocalRecords<T, F> {
  return new LocalRecords(initial, options);
}
