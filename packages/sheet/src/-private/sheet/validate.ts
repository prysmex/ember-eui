/** `@validate`: debounced runs and their result (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { debounce } from '@ember/runloop';
import { buildWaiter } from '@ember/test-waiters';

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
    const snapshot = new Map<string, unknown>(
      records.map((record) => [
        String(this.sheet.args.getRecordId(record)),
        record
      ])
    );
    const changed = this.changedSinceRun;
    this.changedSinceRun = [];
    const isCurrent = () =>
      seq === this.validateSeq &&
      !controller.signal.aborted &&
      !this.sheet.isDestroying &&
      !this.sheet.isDestroyed;

    const result = validate({ records, changed, signal: controller.signal });
    if (!isPromise<CellErrors>(result)) {
      this.validation = { errors: result, records: snapshot };
      return;
    }
    const token = validateWaiter.beginAsync();
    this.validateToken = token;
    const end = () => {
      if (this.validateToken === token) this.endValidateWaiter();
    };
    result.then(
      (errors) => {
        if (isCurrent()) this.validation = { errors, records: snapshot };
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
