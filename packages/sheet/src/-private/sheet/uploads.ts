/** Uploads: pasted and dropped files on attachment cells (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { cellKey, commitValue, isReadOnly, valueOf } from '../../core/index.ts';
import { resolveWaiter, samePos, uploadOf } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField, Pos, RecordId } from '../../core/index.ts';
import type { UploadField } from './types.ts';

/** An upload's progress (V03 11.4), 0 to 1; undefined until the uploader reports one. */
class UploadProgress {
  @tracked fraction: number | undefined = undefined;
}

/** A drag that carries files. */
function hasFiles(event: DragEvent): boolean {
  return Array.from(event.dataTransfer?.types ?? []).includes('Files');
}

export default class SheetUploads<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The attachment cell files are dragged over. */
  @tracked dropPos: Pos | null = null;

  /** Files pasted on an attachment cell: uploaded to the range's first cell. True when handled. */
  pasteFiles(files: FileList): boolean {
    const range = this.sheet.selection.range;
    if (!range) return false;
    // the range's first record
    const records = this.sheet.rows.recordRange(range);
    const record = records ? this.sheet.args.records[records.top] : undefined;
    const field = this.sheet.fields.visibleFields[range.left];
    if (record === undefined || !field || !uploadOf(field)) return false;
    if (isReadOnly(this.sheet.context, field, record)) return true;
    void this.uploadFiles(
      this.sheet.args.getRecordId(record),
      field,
      [...files],
      {
        rejectOnFailure: true
      }
    ).catch(() => undefined);
    return true;
  }

  /**
   * One upload pipeline for the editor, a drop and pasted files:
   * `field.upload(files, { record, field, signal })`, the cell pending
   * meanwhile, then the new files appended to the value read at that time
   * (`commitValue`, source 'edit'). On failure the promise rejects and,
   * with `rejectOnFailure`, the cell gets a rejection (`uploadFailed`).
   * Files past `maxFiles` are not uploaded.
   */
  uploadFiles(
    recordId: RecordId,
    field: EuiSheetField,
    files: File[],
    options: { rejectOnFailure?: boolean } = {}
  ): Promise<void> {
    const upload = uploadOf(field);
    const record = this.sheet.args.records[this.sheet.rows.rowOf(recordId, 0)];
    if (!upload || record === undefined || !files.length) {
      return Promise.resolve();
    }
    const maxFiles = (field as UploadField).maxFiles;
    const current = valueOf(record, field.id);
    const room =
      maxFiles === undefined
        ? files.length
        : maxFiles - (Array.isArray(current) ? current.length : 0);
    const chosen = files.slice(0, Math.max(0, room));
    if (!chosen.length) return Promise.resolve();
    const token = {};
    const controller = new AbortController();
    const key = cellKey(recordId, field.id);
    const progress = new UploadProgress();
    const next = new Map(this.sheet.resolve.pendingCells);
    next.set(key, { text: null, token, progress });
    this.sheet.resolve.pendingCells = next;
    this.sheet.resolve.pendingCalls.set(token, {
      kind: 'upload',
      controller,
      waiter: resolveWaiter.beginAsync(),
      entry: null
    });
    const settle = (): boolean => {
      const live = this.sheet.resolve.pendingCalls.has(token);
      if (this.sheet.resolve.pendingCells.get(key)?.token === token) {
        const rest = new Map(this.sheet.resolve.pendingCells);
        rest.delete(key);
        this.sheet.resolve.pendingCells = rest;
      }
      this.sheet.resolve.endCall(token, false);
      return live && !this.sheet.isDestroying && !this.sheet.isDestroyed;
    };
    // V03 11.4: 0 to 1 for the whole call, clamped; whole percents only (the
    // bar and the title), and nothing after the call settled or was aborted
    const onProgress = (fraction: number): void => {
      if (
        !this.sheet.resolve.pendingCalls.has(token) ||
        controller.signal.aborted ||
        typeof fraction !== 'number' ||
        Number.isNaN(fraction)
      ) {
        return;
      }
      const value = Math.round(Math.min(1, Math.max(0, fraction)) * 100) / 100;
      if (value !== progress.fraction) progress.fraction = value;
    };
    return upload(chosen, {
      record,
      field,
      signal: controller.signal,
      onProgress
    }).then(
      (added) => {
        if (!settle()) return;
        // the value now: another upload may have finished meanwhile
        const row = this.sheet.rows.rowOf(recordId, 0);
        const now = this.sheet.args.records[row];
        if (now === undefined) return;
        const before = valueOf(now, field.id);
        let value = [...(Array.isArray(before) ? before : []), ...added];
        if (maxFiles !== undefined) value = value.slice(0, maxFiles);
        const ctx = { ...this.sheet.context, records: [now], fields: [field] };
        this.sheet.changes.emit(commitValue(ctx, { row: 0, col: 0 }, value), [
          { id: recordId, fieldId: field.id }
        ]);
      },
      (error: unknown) => {
        if (!settle()) throw error;
        if (options.rejectOnFailure) {
          this.sheet.changes.emit(
            {
              source: 'edit',
              patches: [],
              inserts: [],
              rejected: [
                {
                  recordId,
                  fieldId: field.id,
                  text: chosen.map((file) => file.name).join(', '),
                  message: this.sheet.messages.uploadFailed()
                }
              ],
              newOptions: []
            },
            [{ id: recordId, fieldId: field.id }]
          );
        }
        throw error;
      }
    );
  }

  /** A cell's upload progress, 0 to 1, or undefined (the editor's `@progress`). */
  progressOf = (recordId: RecordId, fieldId: string): number | undefined =>
    this.sheet.resolve.pendingCells.get(cellKey(recordId, fieldId))?.progress
      ?.fraction;

  /* Dragging files over an attachment cell */

  /** The attachment cell under a drag with files, if it can take them. */
  dropCellAt(
    target: EventTarget | null
  ): { pos: Pos; record: T; field: EuiSheetField<T> } | null {
    const cell = this.sheet.dom.dataCell(target);
    if (!cell) return null;
    const pos = this.sheet.dom.cursor(cell);
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field || !uploadOf(field)) return null;
    if (isReadOnly(this.sheet.context, field, record)) return null;
    return { pos, record, field };
  }

  @action
  onDragOver(event: DragEvent): void {
    if (!hasFiles(event)) return;
    const target = this.dropCellAt(event.target);
    if (!target) {
      if (this.dropPos) this.dropPos = null;
      // over a cell that cannot take files: the "not allowed" cursor (no drop follows)
      if (this.sheet.dom.dataCell(event.target) && event.dataTransfer) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'none';
      }
      return;
    }
    event.preventDefault();
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'copy';
    if (!samePos(this.dropPos, target.pos)) this.dropPos = target.pos;
  }

  @action
  onDragLeave(event: DragEvent): void {
    const to = event.relatedTarget;
    if (to instanceof Node && this.sheet.wrapper?.contains(to)) return;
    if (this.dropPos) this.dropPos = null;
  }

  @action
  onDrop(event: DragEvent): void {
    if (!hasFiles(event)) return;
    this.dropPos = null;
    const target = this.dropCellAt(event.target);
    if (!target) return;
    event.preventDefault();
    event.stopPropagation();
    const files = [...(event.dataTransfer?.files ?? [])];
    void this.uploadFiles(
      this.sheet.args.getRecordId(target.record),
      target.field,
      files,
      { rejectOnFailure: true }
    ).catch(() => undefined);
  }
}
