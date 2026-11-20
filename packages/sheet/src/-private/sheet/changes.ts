/** Emitting change sets: the one path every write takes (V03C-DESIGN.md 3.2). */
import { cellKey, commitText, planCommit, valueOf } from '../../core/index.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { ChangeSet, Pos, SheetContext } from '../../core/index.ts';
import type { Rejection } from '../rejections.ts';
import type { HistoryEntry, PendingOwn, Touched } from './types.ts';

/** Shift+F10 or the ContextMenu key: the row menu. */
/** The change sets whose cells flash (V03 batch 1), and for how long (ms). */
const FLASH_SOURCES: ReadonlySet<string> = new Set([
  'paste',
  'fill',
  'undo',
  'redo'
]);

export default class SheetChanges<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** What emitted change sets insert and delete, until `@records` changes. */
  pendingOwn: PendingOwn = { deletes: new Set(), inserts: 0 };

  /**
   * A typed text: with `@onResolve`, a text the type answers `{ unresolved }`
   * for is pending and resolved (`planCommit`); else `commitText`.
   */
  emitText(
    ctx: SheetContext<T>,
    pos: Pos,
    text: string,
    touched: Touched
  ): void {
    if (!this.sheet.args.onResolve) {
      this.emit(commitText(ctx, pos, text), touched);
      return;
    }
    const plan = planCommit(ctx, pos, text);
    const entry = this.emit(plan.changeSet, touched);
    this.sheet.resolve.startResolve(plan, entry);
  }

  /* -------------------------------------------------------------------- */
  /* Emitting change sets                                                  */
  /* -------------------------------------------------------------------- */

  /**
   * Updates the rejections (drops the touched cells and entries whose record
   * is gone, adds the change set's), then calls `@onChange`.
   */
  emit(
    changeSet: ChangeSet | null,
    touched: Touched,
    options: { mergeInto?: HistoryEntry | null } = {}
  ): HistoryEntry | null {
    const next = new Map(this.sheet.cells.rejections);
    let changed = false;
    for (const { id, fieldId } of touched) {
      if (next.delete(cellKey(id, fieldId))) changed = true;
    }
    // a newer write to a pending cell discards its result
    this.sheet.resolve.dropPending(
      touched.map(({ id, fieldId }) => cellKey(id, fieldId)),
      changeSet?.deletes ?? []
    );
    if (changeSet?.deletes?.length) {
      // the removed records' texts and checkboxes go with them
      const gone = new Set(changeSet.deletes.map(String));
      if ([...gone].some((id) => this.sheet.checked.checkedIds.has(id))) {
        this.sheet.checked.setChecked(
          new Set(
            [...this.sheet.checked.checkedIds].filter((id) => !gone.has(id))
          )
        );
      }
      for (const [key, entry] of next) {
        if (gone.has(entry.id)) {
          next.delete(key);
          changed = true;
        }
      }
    }
    if (next.size) {
      const ids = new Set(
        this.sheet.args.records.map((record) =>
          String(this.sheet.args.getRecordId(record))
        )
      );
      for (const [key, entry] of next) {
        if (!ids.has(entry.id)) {
          next.delete(key);
          changed = true;
        }
      }
    }
    const stored: Rejection[] = [];
    if (changeSet) {
      const byId = new Map(
        this.sheet.args.records.map((record) => [
          String(this.sheet.args.getRecordId(record)),
          record
        ])
      );
      for (const rejection of changeSet.rejected) {
        const id = String(rejection.recordId ?? rejection.tempId);
        const entry: Rejection = {
          id,
          fieldId: rejection.fieldId,
          text: rejection.text,
          message: rejection.message,
          seenValue: valueOf(byId.get(id), rejection.fieldId)
        };
        next.set(cellKey(id, rejection.fieldId), entry);
        stored.push(entry);
        changed = true;
      }
    }
    if (changed) this.sheet.cells.rejections = next;
    if (!changeSet) return null;
    const entry = this.sheet.history.recordHistory(
      changeSet,
      stored,
      options.mergeInto
    );
    // the rows the owner's next `@records` gains or loses because of it
    if (changeSet.inserts.length || changeSet.deletes?.length) {
      this.pendingOwn.inserts += changeSet.inserts.length;
      for (const id of changeSet.deletes ?? []) {
        this.pendingOwn.deletes.add(String(id));
      }
    }
    for (const patch of changeSet.patches) {
      this.sheet.validate.changedSinceRun.push({
        recordId: patch.recordId,
        fieldId: patch.fieldId
      });
    }
    for (const insert of changeSet.inserts) {
      for (const fieldId of Object.keys(insert.values)) {
        this.sheet.validate.changedSinceRun.push({
          recordId: insert.tempId,
          fieldId
        });
      }
    }
    this.sheet.args.onChange(changeSet);
    this.sheet.validate.scheduleValidate();
    // a change ends the copy mark; a paste, fill, undo or redo flashes its cells
    if (this.sheet.outline.copied) this.sheet.outline.copied = null;
    if (FLASH_SOURCES.has(changeSet.source))
      this.sheet.outline.flashCells(changeSet);
    return entry;
  }
}
