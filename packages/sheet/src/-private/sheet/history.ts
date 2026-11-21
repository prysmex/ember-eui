/** Undo and redo: the stacks, applying an entry, id remapping (V03C-DESIGN.md 3.2). */
import {
  cellKey,
  mergeChangeSets,
  redoChangeSet,
  undoChangeSet,
  valueOf
} from '../../core/index.ts';
import { findRecords } from '../../core/record-lookup.ts';
import { composeIdMaps, remapChangeSet, remapId, toIdMap } from '../remap.ts';
import {
  clearRejections,
  remapRejections,
  restoreRejections
} from '../rejections.ts';
import { afterRender, EMPTY_CHANGE_SET } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  ChangeSet,
  HistoryOptions,
  PendingCell,
  Pos,
  Range,
  RecordId
} from '../../core/index.ts';
import type { Rejection } from '../rejections.ts';
import type { HistoryEntry, PendingEntry, Touched } from './types.ts';

/** Undo entries kept per sheet. */
const HISTORY_LIMIT = 100;

export default class SheetHistory<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /* Undo and redo: the change sets this sheet emitted for user actions */
  undoStack: HistoryEntry[] = [];
  redoStack: HistoryEntry[] = [];
  /** Every id `remapIds` was told about, old (as a string) → new. */
  remapped: Map<string, RecordId> = new Map();

  /* -------------------------------------------------------------------- */
  /* Undo and redo                                                         */
  /* -------------------------------------------------------------------- */

  /**
   * What undo and redo need besides the records: every field id, visible
   * and hidden (a restored record's values); and, grouped with a collapsed
   * group, `keepUnseen`: a record not in `@records` may be in that group,
   * so its patches are emitted (V03 8.5, GR16).
   */
  get historyOptions(): HistoryOptions {
    return {
      fieldIds: this.sheet.fields.allFields.map((field) => field.id),
      equals: (fieldId, a, b) => this.sheet.fields.valueEquals(fieldId, a, b),
      keepUnseen: this.sheet.rows.groups.some((group) => group.collapsed)
    };
  }

  /**
   * Emits the inverse of the last entry, without the cells changed since,
   * and clears the texts it rejected. `focus: false` keeps DOM focus where
   * it is (the expanded record's form).
   */
  undo({ focus = true }: { focus?: boolean } = {}): void {
    if (this.sheet.args.readOnly) return;
    const entry = this.undoStack.pop();
    if (!entry) return;
    this.redoStack.push(entry);
    // a resolve or upload still running for it is dropped (V02-RESULTS, batch 5)
    this.sheet.resolve.endCallsOf(entry);
    const applied = this.applyHistory(
      undoChangeSet(
        entry.changeSet,
        this.sheet.args.records,
        this.sheet.args.getRecordId,
        this.historyOptions
      ),
      entry,
      'undo',
      focus
    );
    // none of its records is in @records (another page of the owner's
    // data): skipped, and kept on the stack for when they are back (7.3)
    if (!applied && !this.touchesRecords(entry)) {
      this.redoStack.pop();
      this.undoStack.push(entry);
    }
  }

  /**
   * Emits the last undone entry again, without the cells changed since,
   * and shows its rejected texts again.
   */
  redo({ focus = true }: { focus?: boolean } = {}): void {
    if (this.sheet.args.readOnly) return;
    const entry = this.redoStack.pop();
    if (!entry) return;
    this.undoStack.push(entry);
    const applied = this.applyHistory(
      redoChangeSet(
        entry.changeSet,
        this.sheet.args.records,
        this.sheet.args.getRecordId,
        this.historyOptions
      ),
      entry,
      'redo',
      focus
    );
    if (!applied && !this.touchesRecords(entry)) {
      this.undoStack.pop();
      this.redoStack.push(entry);
    }
  }

  clearHistory(): void {
    this.undoStack = [];
    this.redoStack = [];
  }

  /**
   * `SheetApi.remapIds`: rewrites the history, the rejections, a pending
   * focus, an open editor's record and the ids of the last `@records`.
   */
  remapIds(ids: Record<string, RecordId>): void {
    const map = toIdMap(ids);
    if (!map.size) return;
    this.remapped = composeIdMaps(this.remapped, map);
    const remapEntry = (entry: HistoryEntry): HistoryEntry => ({
      changeSet: remapChangeSet(entry.changeSet, map),
      rejections: remapRejections(entry.rejections, (id) => remapId(id, map))
    });
    const remapTracked = (entry: HistoryEntry): HistoryEntry => {
      const next = remapEntry(entry);
      this.replaceEntry(entry, next);
      return next;
    };
    this.undoStack = this.undoStack.map(remapTracked);
    this.redoStack = this.redoStack.map(remapTracked);
    if (this.sheet.resolve.pendingCells.size) {
      const next = new Map<string, PendingEntry>();
      for (const [key, entry] of this.sheet.resolve.pendingCells) {
        const cell = entry.cell;
        if (!cell) {
          const at = key.indexOf('\u0000');
          const id = String(remapId(key.slice(0, at), map));
          next.set(cellKey(id, key.slice(at + 1)), entry);
          continue;
        }
        const id = remapId(cell.recordId ?? cell.tempId!, map);
        const moved: PendingCell = { ...cell, recordId: id };
        delete moved.tempId;
        next.set(cellKey(id, cell.fieldId), { ...entry, cell: moved });
      }
      this.sheet.resolve.pendingCells = next;
    }
    if (this.sheet.cells.rejections.size) {
      const next = new Map<string, Rejection>();
      for (const entry of this.sheet.cells.rejections.values()) {
        const id = String(remapId(entry.id, map));
        next.set(cellKey(id, entry.fieldId), { ...entry, id });
      }
      this.sheet.cells.rejections = next;
    }
    if (this.sheet.records.pendingFocus) {
      this.sheet.records.pendingFocus = {
        ...this.sheet.records.pendingFocus,
        id: String(remapId(this.sheet.records.pendingFocus.id, map))
      };
    }
    if (this.sheet.edit.editing) {
      this.sheet.edit.editing.recordId = remapId(
        this.sheet.edit.editing.recordId,
        map
      );
    }
    if ([...this.sheet.checked.checkedIds].some((id) => map.has(id))) {
      this.sheet.checked.setChecked(
        new Set(
          [...this.sheet.checked.checkedIds].map((id) =>
            String(remapId(id, map))
          )
        )
      );
    }
    if (this.sheet.expanded.localExpandedId !== null) {
      this.sheet.expanded.localExpandedId = remapId(
        this.sheet.expanded.localExpandedId,
        map
      );
    }
    if (this.sheet.expanded.expandedFrom) {
      this.sheet.expanded.expandedFrom = {
        ...this.sheet.expanded.expandedFrom,
        recordId: remapId(this.sheet.expanded.expandedFrom.recordId, map)
      };
    }
    // a `@records` that only carries the new ids is not a change of rows
    this.sheet.follow.lastIds = this.sheet.follow.lastIds.map((id) =>
      String(remapId(id, map))
    );
    const deletes = [...this.sheet.changes.pendingOwn.deletes].map((id) =>
      String(remapId(id, map))
    );
    this.sheet.changes.pendingOwn = {
      ...this.sheet.changes.pendingOwn,
      deletes: new Set(deletes)
    };
  }

  /**
   * Emits an undo or redo (if anything is left of it), clears (undo) or
   * restores (redo) the entry's rejected texts, and selects what changed.
   * An entry with only rejections emits nothing: the data does not change.
   */
  /**
   * Whether a record the entry changed, inserted or deleted is in
   * `@records`. An entry with none (the owner shows another page or query)
   * is kept on its stack when undo or redo finds nothing to do.
   */
  touchesRecords(entry: HistoryEntry): boolean {
    const { changeSet } = entry;
    const named = new Set<string>([
      ...changeSet.patches.map((patch) => String(patch.recordId)),
      ...changeSet.inserts.map((insert) => insert.tempId),
      ...(changeSet.deletes ?? []).map((id) => String(id)),
      ...(changeSet.moves ?? []).map((move) => String(move.recordId)),
      ...entry.rejections.map((rejection) => String(rejection.id))
    ]);
    return (
      findRecords(this.sheet.args.records, this.sheet.args.getRecordId, named)
        .size > 0
    );
  }

  /** Returns whether it emitted a change set or changed the rejected texts shown. */
  applyHistory(
    changeSet: ChangeSet | null,
    entry: HistoryEntry,
    direction: 'undo' | 'redo',
    focus: boolean
  ): boolean {
    const recordsBefore = this.sheet.args.records;
    const before = recordsBefore.length;
    let shown: Rejection[] = [];
    if (direction === 'undo' && entry.rejections.length) {
      const next = clearRejections(
        this.sheet.cells.rejections,
        entry.rejections
      );
      if (next) {
        shown = entry.rejections.filter(
          (rejection) => !next.has(cellKey(rejection.id, rejection.fieldId))
        );
        this.sheet.cells.rejections = next;
      }
    }
    if (changeSet) {
      this.sheet.changes.emit(
        changeSet,
        changeSet.patches.map((patch) => ({
          id: patch.recordId,
          fieldId: patch.fieldId
        }))
      );
    }
    if (direction === 'redo' && entry.rejections.length) {
      // after emit: the owner may have put back the rows they are on
      const byId = findRecords(
        this.sheet.args.records,
        this.sheet.args.getRecordId,
        new Set(entry.rejections.map((rejection) => String(rejection.id)))
      );
      const next = restoreRejections(
        this.sheet.cells.rejections,
        entry.rejections,
        (id, fieldId) => ({
          found: byId.has(id),
          value: valueOf(byId.get(id)?.record, fieldId)
        })
      );
      if (next) {
        shown = entry.rejections.filter((rejection) =>
          next.has(cellKey(rejection.id, rejection.fieldId))
        );
        this.sheet.cells.rejections = next;
      }
    }
    if (!changeSet && !shown.length) return false;
    // a move's rows are selected at their new place (V03 10.1)
    if (changeSet?.moves?.length) {
      const ids = changeSet.moves.map((move) => move.recordId);
      if (focus) this.sheet.rowDrag.selectAfter(ids, ids[0]!, recordsBefore);
      return true;
    }
    this.selectChanged(
      changeSet ?? { ...EMPTY_CHANGE_SET, source: direction },
      before,
      shown.map((rejection) => ({
        id: rejection.id,
        fieldId: rejection.fieldId
      })),
      focus
    );
    return true;
  }

  /**
   * Selects the bounding box of the patched cells and focuses its top-left
   * cell. Only rows that exist both before and after the change are used:
   * inserted rows are rendered only on the next render, and the grid throws
   * for a row past its last one. A change that only inserts (an undone
   * delete) focuses the first inserted record once it is rendered.
   */
  selectChanged(
    changeSet: ChangeSet,
    rowsBefore: number,
    extraCells: Touched = [],
    focusCell = true
  ): void {
    // the owner's records after it applied the change set, if it did at once
    const records = this.sheet.args.records;
    const rows = Math.min(rowsBefore, records.length);
    let box: Range | null = null;
    const cells: Touched = [
      ...changeSet.patches.map((patch) => ({
        id: patch.recordId,
        fieldId: patch.fieldId
      })),
      ...extraCells
    ];
    const indexOf = findRecords(
      records,
      this.sheet.args.getRecordId,
      new Set(cells.map(({ id }) => String(id)))
    );
    const cols = new Map<string, number>();
    this.sheet.fields.visibleFields.forEach((field, i) => {
      if (!cols.has(field.id)) cols.set(field.id, i);
    });
    for (const { id, fieldId } of cells) {
      const row = indexOf.get(String(id))?.row;
      const col = cols.get(fieldId) ?? -1;
      if (row === undefined || row >= rows || col < 0) continue;
      box = box
        ? {
            top: Math.min(box.top, row),
            left: Math.min(box.left, col),
            bottom: Math.max(box.bottom, row),
            right: Math.max(box.right, col)
          }
        : { top: row, left: col, bottom: row, right: col };
    }
    let focus: Pos;
    if (box) {
      // the box is in record rows
      focus = this.sheet.rows.gridPos({ row: box.top, col: box.left });
      this.sheet.selection.anchor = this.sheet.rows.gridPos({
        row: box.bottom,
        col: box.right
      });
    } else if (changeSet.inserts.length) {
      const field =
        this.sheet.fields.visibleFields[this.sheet.selection.head?.col ?? 0];
      if (!field || !focusCell) return;
      this.sheet.records.pendingFocus = {
        id: changeSet.inserts[0]!.tempId,
        fieldId: field.id
      };
      // the owner may have applied it already; else the next render does
      afterRender(this.sheet, () => this.sheet.records.applyPendingFocus());
      return;
    } else {
      // nothing patched (an undo that only removed rows): keep focus on a
      // row that still exists
      const head = this.sheet.selection.head;
      if (
        !head ||
        rows === 0 ||
        head.row <= this.sheet.rows.gridRowOf(rows - 1)
      )
        return;
      focus = { row: this.sheet.rows.gridRowOf(rows - 1), col: head.col };
      this.sheet.selection.anchor = focus;
    }
    this.sheet.selection.head = focus;
    if (!focusCell) return;
    // onFocusIn sees the cell it already knows and keeps the range
    this.sheet.focus.domCursor = focus;
    this.sheet.dom.focusGridCell(focus);
  }

  /**
   * A user action's change set becomes an undo entry (not an undo or redo,
   * and not one with only new options), with the rejections it stored: a
   * paste whose every cell was rejected is undone too. A new entry clears
   * the redo stack. A bulk resolve (`'resolve'`) joins the last entry, the
   * paste that asked for it, so one undo reverts both.
   */
  recordHistory(
    changeSet: ChangeSet,
    rejections: Rejection[],
    mergeInto?: HistoryEntry | null
  ): HistoryEntry | null {
    if (changeSet.source === 'undo' || changeSet.source === 'redo') {
      return null;
    }
    if (
      !changeSet.patches.length &&
      !changeSet.inserts.length &&
      !changeSet.deletes?.length &&
      !changeSet.moves?.length &&
      !rejections.length
    ) {
      return null;
    }
    const remap = (id: RecordId) => remapId(id, this.remapped);
    const entry: HistoryEntry = {
      changeSet: remapChangeSet(changeSet, this.remapped),
      rejections: remapRejections(rejections, remap)
    };
    // a resolve joins the entry of the paste or edit that asked for it
    const index = mergeInto ? this.undoStack.indexOf(mergeInto) : -1;
    if (entry.changeSet.source === 'resolve' && index >= 0) {
      const target = this.undoStack[index]!;
      // a resolved text is no longer a rejection of that entry
      const written = new Set(
        entry.changeSet.patches.map((patch) =>
          cellKey(patch.recordId, patch.fieldId)
        )
      );
      const merged: HistoryEntry = {
        changeSet: mergeChangeSets(target.changeSet, entry.changeSet),
        rejections: [
          ...target.rejections.filter(
            (rejection) =>
              !written.has(cellKey(rejection.id, rejection.fieldId))
          ),
          ...entry.rejections
        ]
      };
      this.undoStack[index] = merged;
      this.replaceEntry(target, merged);
      return merged;
    }
    this.undoStack.push(entry);
    if (this.undoStack.length > HISTORY_LIMIT) this.undoStack.shift();
    this.redoStack = [];
    return entry;
  }

  /** A history entry was replaced (merged, remapped): calls that point at it follow. */
  replaceEntry(from: HistoryEntry, to: HistoryEntry): void {
    for (const call of this.sheet.resolve.pendingCalls.values()) {
      if (call.entry === from) call.entry = to;
    }
  }
}
