/** `@validate`: debounced runs and their result (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { debounce } from '@ember/runloop';
import { buildWaiter } from '@ember/test-waiters';

import { findRecords } from '../../core/record-lookup.ts';
import { isPromise } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { CellErrors, RecordId } from '../../core/index.ts';
import type { Validation } from './types.ts';

/** Debounce of `@validate` runs, in ms. */
const VALIDATE_DEBOUNCE = 50;

const validateWaiter = buildWaiter('@ember-eui/sheet:validate');

export default class SheetValidate<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The last applied `@validate` result. */
  @tracked validation: Validation | null = null;

  /* `@validate` runs */
  validateTimer: ReturnType<typeof debounce> | null = null;
  validateSeq = 0;
  validateController: AbortController | null = null;
  validateToken: unknown = null;
  changedSinceRun: Array<{ recordId: RecordId; fieldId: string }> = [];

  /* -------------------------------------------------------------------- */
  /* @validate (PACKAGE-DESIGN.md 9.4, layers 4-6)                         */
  /* -------------------------------------------------------------------- */

  scheduleValidate(): void {
    if (!this.sheet.args.validate) return;
    this.validateTimer = debounce(this, this.runValidate, VALIDATE_DEBOUNCE);
  }

  endValidateWaiter(): void {
    if (this.validateToken !== null) {
      validateWaiter.endAsync(this.validateToken);
      this.validateToken = null;
    }
  }

  /**
   * A run's result and, by id, the records it ran on that have errors (as
   * a map of every record by `String(id)` would give them: the last of two
   * records with one id).
   */
  validationOf(
    errors: CellErrors,
    records: readonly T[],
    getRecordId: (record: T) => RecordId
  ): Validation {
    const ids = new Set(Object.keys(errors ?? {}));
    const found = findRecords(records, getRecordId, ids);
    const byId = new Map<string, unknown>();
    for (const [id, entry] of found) byId.set(id, entry.record);
    return { errors, records: byId };
  }

  runValidate(): void {
    this.validateTimer = null;
    const validate = this.sheet.args.validate;
    if (!validate || this.sheet.isDestroying || this.sheet.isDestroyed) return;
    // a newer run supersedes the previous one
    this.validateController?.abort();
    this.endValidateWaiter();
    const seq = ++this.validateSeq;
    const controller = new AbortController();
    this.validateController = controller;
    const records = this.sheet.args.records;
    // the records the run starts with: the array as it is now (an owner may
    // change it in place before an async result); the records of the ids
    // with errors are looked up in it when the result comes, not every
    // record put in a map by id (its strings cost 20-45 ms at 100,000)
    const snapshot = records.slice();
    const getRecordId = this.sheet.args.getRecordId;
    const changed = this.changedSinceRun;
    this.changedSinceRun = [];
    const isCurrent = () =>
      seq === this.validateSeq &&
      !controller.signal.aborted &&
      !this.sheet.isDestroying &&
      !this.sheet.isDestroyed;

    const result = validate({ records, changed, signal: controller.signal });
    if (!isPromise<CellErrors>(result)) {
      this.validation = this.validationOf(result, snapshot, getRecordId);
      return;
    }
    const token = validateWaiter.beginAsync();
    this.validateToken = token;
    const end = () => {
      if (this.validateToken === token) this.endValidateWaiter();
    };
    result.then(
      (errors) => {
        if (isCurrent())
          this.validation = this.validationOf(errors, snapshot, getRecordId);
        end();
      },
      (error: unknown) => {
        end();
        // an aborted or superseded run's failure (an AbortError) is expected
        if (isCurrent()) throw error;
      }
    );
  }
}
