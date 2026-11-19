/**
 * EuiSheet spike (DESIGN.md, section 5.3): a tracked record array that
 * applies change sets, for tests and demos. A product would apply change
 * sets to its own store.
 */
import { tracked } from '@glimmer/tracking';

import type { ChangeSet, RecordId } from './change-set.ts';

export interface LocalRecordsOptions<T> {
  getRecordId: (record: T) => RecordId;
  /** Default: `{ id: tempId, ...values }`. */
  createRecord?: (values: Record<string, unknown>, tempId: string) => T;
}

export class LocalRecords<T extends object> {
  @tracked records: T[];
  readonly log: ChangeSet[] = [];

  constructor(
    initial: T[],
    private options: LocalRecordsOptions<T>
  ) {
    this.records = initial;
  }

  apply = (changeSet: ChangeSet): void => {
    const { getRecordId, createRecord } = this.options;
    const byId = new Map<RecordId, Record<string, unknown>>();
    for (const patch of changeSet.patches) {
      const values = byId.get(patch.recordId) ?? {};
      values[patch.fieldId] = patch.to;
      byId.set(patch.recordId, values);
    }
    const next = this.records.map((record) => {
      const values = byId.get(getRecordId(record));
      return values ? ({ ...record, ...values } as T) : record;
    });
    const inserts = [...changeSet.inserts].sort((a, b) => a.index - b.index);
    for (const insert of inserts) {
      next.push(
        createRecord
          ? createRecord(insert.values, insert.tempId)
          : ({ id: insert.tempId, ...insert.values } as unknown as T)
      );
    }
    this.records = next;
    this.log.push(changeSet);
  };
}

export function localRecords<T extends object>(
  initial: T[],
  options: LocalRecordsOptions<T>
): LocalRecords<T> {
  return new LocalRecords(initial, options);
}
