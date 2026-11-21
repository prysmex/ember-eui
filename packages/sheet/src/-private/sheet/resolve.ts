/** Bulk resolve: pending cells and the calls that resolve them (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';

import { cellKey, resolveCells } from '../../core/index.ts';
import { resolveWaiter } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  ChangeSet,
  EuiSheetField,
  PendingCell,
  RecordId,
  ResolvePlan,
  ResolveResult
} from '../../core/index.ts';
import type { HistoryEntry, PendingCall, PendingEntry } from './types.ts';

export default class SheetResolve<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Cells waiting for `@onResolve` or an upload, by cellKey. */
  @tracked pendingCells: ReadonlyMap<string, PendingEntry> = new Map();
  /** The `@onResolve` calls and uploads in flight, by token. */
  pendingCalls = new Map<object, PendingCall>();

  /* -------------------------------------------------------------------- */
  /* Bulk resolve and uploads (V02-DESIGN.md 8.1, 8.2)                     */
  /* -------------------------------------------------------------------- */

  /**
   * Stores a plan's pending cells (after its synchronous change set was
   * emitted: that emit's `touched` covers them) and calls `@onResolve`
   * once, one request per field.
   */
  startResolve(
    plan: ResolvePlan<T>,
    entry: HistoryEntry | null,
    fields?: readonly EuiSheetField<T>[]
  ): void {
    const onResolve = this.sheet.args.onResolve;
    if (!onResolve || !plan.pending.length) return;
    const token = {};
    const controller = new AbortController();
    const next = new Map(this.pendingCells);
    for (const cell of plan.pending) {
      next.set(cellKey(cell.recordId ?? cell.tempId!, cell.fieldId), {
        text: cell.text,
        token,
        cell
      });
    }
    this.pendingCells = next;
    const call: PendingCall = {
      kind: 'resolve',
      controller,
      waiter: resolveWaiter.beginAsync(),
      entry
    };
    if (fields) call.fields = fields;
    this.pendingCalls.set(token, call);
    let result: Promise<ResolveResult>;
    try {
      result = Promise.resolve(
        onResolve(plan.requests, { signal: controller.signal })
      );
    } catch (error) {
      result = Promise.reject(
        error instanceof Error ? error : new Error(String(error))
      );
    }
    result.then(
      (answers) => this.finishResolve(token, answers),
      () => this.finishResolve(token, null)
    );
  }

  /**
   * Writes the cells still pending under `token`: the resolved values (a
   * second change set, source 'resolve', merged into the paste's undo
   * entry), or, when the call failed (`null`), a rejection per cell.
   */
  finishResolve(token: object, answers: ResolveResult | null): void {
    const call = this.pendingCalls.get(token);
    if (!call || this.sheet.isDestroying || this.sheet.isDestroyed) return;
    const cells: PendingCell[] = [];
    const next = new Map(this.pendingCells);
    for (const [key, entry] of this.pendingCells) {
      if (entry.token !== token || !entry.cell) continue;
      cells.push(entry.cell);
      next.delete(key);
    }
    this.pendingCells = next;
    const mergeInto = call.entry;
    this.endCall(token, false);
    if (!cells.length) return;
    let changeSet: ChangeSet | null;
    if (answers) {
      // the fields the texts were read with first (`appendRows`' own)
      const fields = call.fields
        ? [...call.fields, ...this.sheet.fields.allFields]
        : this.sheet.fields.allFields;
      changeSet = resolveCells(
        { ...this.sheet.context, fields },
        cells,
        answers
      );
    } else {
      changeSet = {
        source: 'resolve',
        patches: [],
        inserts: [],
        rejected: cells.map((cell) => {
          const message = this.sheet.messages.unresolved(cell.text);
          return cell.recordId !== undefined
            ? {
                recordId: cell.recordId,
                fieldId: cell.fieldId,
                text: cell.text,
                message
              }
            : {
                tempId: cell.tempId!,
                fieldId: cell.fieldId,
                text: cell.text,
                message
              };
        }),
        newOptions: []
      };
    }
    this.sheet.changes.emit(
      changeSet,
      cells.map((cell) => ({
        id: cell.recordId ?? cell.tempId!,
        fieldId: cell.fieldId
      })),
      { mergeInto }
    );
  }

  /** Ends a call and its test waiter; aborts its signal unless it settled (`abort: false`). */
  endCall(token: object, abort = true): void {
    const call = this.pendingCalls.get(token);
    if (!call) return;
    this.pendingCalls.delete(token);
    if (abort) call.controller.abort();
    resolveWaiter.endAsync(call.waiter);
  }

  /** Ends the calls an undone entry asked for, and drops their cells. */
  endCallsOf(entry: HistoryEntry): void {
    const tokens = [...this.pendingCalls]
      .filter(([, call]) => call.entry === entry)
      .map(([token]) => token);
    if (!tokens.length) return;
    const next = new Map(this.pendingCells);
    for (const [key, pending] of this.pendingCells) {
      if (tokens.includes(pending.token)) next.delete(key);
    }
    this.pendingCells = next;
    for (const token of tokens) this.endCall(token);
  }

  /**
   * Drops pending resolve cells (by cellKey, or every cell of a record id);
   * a call none of whose cells is left pending is ended (its signal
   * aborted). Uploads are kept.
   */
  dropPending(
    keys: readonly string[],
    recordIds: readonly RecordId[] = []
  ): void {
    if (!this.pendingCells.size) return;
    const ids = new Set(recordIds.map(String));
    let next: Map<string, PendingEntry> | null = null;
    for (const [key, entry] of this.pendingCells) {
      // an upload is not undone by a write: its files are appended to the value then
      if (!entry.cell) continue;
      const id = String(entry.cell.recordId ?? entry.cell.tempId);
      if (!keys.includes(key) && !ids.has(id)) continue;
      next ??= new Map(this.pendingCells);
      next.delete(key);
    }
    if (!next) return;
    this.pendingCells = next;
    const live = new Set([...next.values()].map((entry) => entry.token));
    for (const [token, call] of [...this.pendingCalls]) {
      if (call.kind === 'resolve' && !live.has(token)) this.endCall(token);
    }
  }
}
