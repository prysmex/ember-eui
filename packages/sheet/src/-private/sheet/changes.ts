/** Emitting change sets: the one path every write takes (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { next } from '@ember/runloop';

import { cellKey, commitText, planCommit, valueOf } from '../../core/index.ts';
import { findRecords } from '../../core/record-lookup.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { ChangeSet, Pos, SheetContext } from '../../core/index.ts';
import { UNSEEN } from '../rejections.ts';
import { samePos } from './util.ts';

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

  /**
   * The text of the sheet's polite live region (READINESS.md item 3): a
   * paste, an undo or a redo, a text that was not stored, an edit that
   * left its cell invalid (when the active cell has moved on; the focused
   * cell's error box is a live region of its own).
   */
  @tracked announcement = '';
  /** Alternates, so the same message twice still changes the region's text. */
  private announceFlip = false;

  announce(text: string): void {
    if (!text) return;
    this.announceFlip = !this.announceFlip;
    // a trailing no-break space: read the same, a new text for the region
    this.announcement = this.announceFlip ? text : `${text}\u00a0`;
  }

  /**
   * What a screen reader hears after a change set (`emit`). `pasted`: a
   * paste's columns (the clipboard's paste only, not `appendRows`): the
   * cells written are its patches and its new records' values in those
   * columns (not `@newRecordValues` or a group's values).
   */
  announceChangeSet(changeSet: ChangeSet, pasted?: ReadonlySet<string>): void {
    const messages = this.sheet.messages;
    const parts: string[] = [];
    if (changeSet.source === 'undo') parts.push(messages.announceUndone());
    else if (changeSet.source === 'redo') parts.push(messages.announceRedone());
    else if (changeSet.source === 'paste' && pasted) {
      const cells =
        changeSet.patches.length +
        changeSet.inserts.reduce(
          (count, insert) =>
            count +
            Object.keys(insert.values).filter((id) => pasted.has(id)).length,
          0
        );
      if (cells) {
        parts.push(
          cells === 1
            ? messages.announcePastedOne(cells)
            : messages.announcePasted(cells)
        );
      }
    }
    const rejected = changeSet.rejected;
    if (rejected.length === 1) parts.push(rejected[0]!.message);
    else if (rejected.length > 1) {
      parts.push(messages.announceRejected(rejected.length));
    }
    if (parts.length) {
      this.announce(parts.join('. '));
      return;
    }
    const patch = changeSet.patches[0];
    // an edit, or an edit to nothing (a clear)
    if (
      (changeSet.source !== 'edit' && changeSet.source !== 'clear') ||
      changeSet.patches.length !== 1
    )
      return;
    // once the owner's new `@records` rendered and focus moved (Enter,
    // Tab): the cell's own errors
    next(() => {
      if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
      const col = this.sheet.fields.visibleFields.findIndex(
        (field) => field.id === patch!.fieldId
      );
      const row = this.sheet.rows.rowOf(
        patch!.recordId,
        this.sheet.rows.hintOf(this.sheet.selection.head?.row)
      );
      if (col < 0 || row < 0) return;
      // focus still on the cell: its own error box says it
      if (samePos(this.sheet.focus.focused?.pos ?? null, { row, col })) return;
      const field = this.sheet.fields.visibleFields[col]!;
      const errors = this.sheet.cells.cellView(row, col, field.id)?.errors;
      if (!errors?.length) return;
      this.announce(
        messages.announceCellError(field.label ?? field.id, errors.join('. '))
      );
    });
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
    options: {
      mergeInto?: HistoryEntry | null;
      /** A paste's columns, for its announcement (`announceChangeSet`). */
      pasted?: ReadonlySet<string>;
    } = {}
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
      const found = findRecords(
        this.sheet.args.records,
        this.sheet.args.getRecordId,
        new Set([...next.values()].map((entry) => entry.id))
      );
      for (const [key, entry] of next) {
        if (!found.has(entry.id)) {
          next.delete(key);
          changed = true;
        }
      }
    }
    const stored: Rejection[] = [];
    if (changeSet?.rejected.length) {
      const found = findRecords(
        this.sheet.args.records,
        this.sheet.args.getRecordId,
        new Set(
          changeSet.rejected.map((rejection) =>
            String(rejection.recordId ?? rejection.tempId)
          )
        )
      );
      for (const rejection of changeSet.rejected) {
        const id = String(rejection.recordId ?? rejection.tempId);
        const record = found.get(id);
        const entry: Rejection = {
          id,
          fieldId: rejection.fieldId,
          text: rejection.text,
          message: rejection.message,
          // a record this change set inserts: the value it arrives with
          seenValue:
            record || rejection.recordId !== undefined
              ? valueOf(record?.record, rejection.fieldId)
              : UNSEEN
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
    this.announceChangeSet(changeSet, options.pasted);
    this.sheet.validate.scheduleValidate();
    // a change ends the copy mark; a paste, fill, undo or redo flashes its cells
    if (this.sheet.outline.copied) this.sheet.outline.copied = null;
    if (FLASH_SOURCES.has(changeSet.source))
      this.sheet.outline.flashCells(changeSet);
    return entry;
  }
}
