/** The edit lifecycle: the open editor, its draft, commit and cancel (V03C-DESIGN.md 3.2). */
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { commitValue, valueOf } from '../../core/index.ts';
import { afterRender, clamp, uploadOf } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { EuiSheetField, Pos, RecordId } from '../../core/index.ts';
import type {
  EuiSheetFieldType,
  SheetEditorRect,
  SheetEditorResult
} from '../../types.ts';

/** `@editIn="auto"`: the expanded record edits on a coarse pointer and a sheet narrower than this. */
const NARROW_SHEET = 600;

/** Whether the primary pointer is coarse (a touch screen). */
function coarsePointer(): boolean {
  return (
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches
  );
}

/**
 * The open editor. One object per edit (the editor is keyed by it), so
 * when the owner moves the record (V02-DESIGN.md 3.2) its position and box
 * change in place and the editor keeps its draft.
 */
class Editing {
  @tracked pos: Pos;
  recordId: RecordId;
  field: EuiSheetField;
  type: EuiSheetFieldType;
  @tracked rect: SheetEditorRect;
  layout: 'cell' | 'panel' | 'expand';
  initialKey: string | null;
  draft: string;
  /** Opened by a click on the type's opener icon (V03 10.3.2: the barcode's camera). */
  opener = false;
  /** The editor's `@onUpload` (attachment fields with `upload`). */
  onUpload?: (files: File[]) => Promise<void>;

  constructor(init: {
    pos: Pos;
    recordId: RecordId;
    field: EuiSheetField;
    type: EuiSheetFieldType;
    rect: SheetEditorRect;
    layout: 'cell' | 'panel' | 'expand';
    initialKey: string | null;
    draft: string;
  }) {
    this.pos = init.pos;
    this.recordId = init.recordId;
    this.field = init.field;
    this.type = init.type;
    this.rect = init.rect;
    this.layout = init.layout;
    this.initialKey = init.initialKey;
    this.draft = init.draft;
  }
}

export default class SheetEdit<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  @tracked editing: Editing | null = null;
  /** `@editIn` opened the expanded record to edit this field (8.5). */
  pendingFormEdit: { recordId: RecordId; fieldId: string } | null = null;

  /** Plain: the last text (or value) the editor reported, and whether it reported one. */
  draft = '';
  draftDirty = false;
  draftValue: unknown = undefined;
  draftKind: 'text' | 'value' = 'text';

  /* -------------------------------------------------------------------- */
  /* @editIn (V02-DESIGN.md 8.5)                                           */
  /* -------------------------------------------------------------------- */

  /** Whether a click on the selected cell or Enter edits in the expanded record. */
  get editsInRecord(): boolean {
    const mode = this.sheet.args.editIn ?? 'auto';
    if (mode === 'record') return true;
    if (mode !== 'auto') return false;
    return (
      coarsePointer() &&
      (this.sheet.wrapper?.offsetWidth ?? Infinity) < NARROW_SHEET
    );
  }

  /**
   * `@editIn`: opens the expanded record with the cell's field editing,
   * instead of the grid's editor. False when it does not apply.
   */
  editInRecord(pos: Pos): boolean {
    if (!this.editsInRecord || !this.sheet.cells.canEdit(pos)) return false;
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (record === undefined || !field) return false;
    const recordId = this.sheet.args.getRecordId(record);
    this.pendingFormEdit = { recordId, fieldId: field.id };
    // the shell's focus trap waits for the editor (as for any form editor)
    this.sheet.expanded.formEditorOpen = true;
    this.sheet.expanded.expandRecord(recordId, { recordId, fieldId: field.id });
    afterRender(this.sheet, () => {
      // no form took it (a controlled owner kept the record closed)
      if (!this.pendingFormEdit) return;
      this.pendingFormEdit = null;
      this.sheet.expanded.formEditorOpen = false;
    });
    return true;
  }

  /** The expanded record's form asks which field to open on mount. */
  takePendingFormEdit(record: unknown): string | null {
    const pending = this.pendingFormEdit;
    if (!pending || record === undefined) return null;
    if (
      String(this.sheet.args.getRecordId(record as T)) !==
      String(pending.recordId)
    ) {
      return null;
    }
    this.pendingFormEdit = null;
    return pending.fieldId;
  }

  startEdit(
    pos: Pos,
    cell: HTMLElement,
    initialKey: string | null,
    options: { opener?: boolean } = {}
  ): void {
    // an edit ends the copy mark (V03 batch 1)
    if (this.sheet.outline.copied) this.sheet.outline.copied = null;
    const wrapper = this.sheet.wrapper;
    const record = this.sheet.rows.recordAt(pos.row);
    const field = this.sheet.fields.visibleFields[pos.col];
    if (!wrapper || record === undefined || !field) return;
    const type = this.sheet.fields.typeOf(field);
    const recordId = this.sheet.args.getRecordId(record);
    const rect = this.sheet.dom.rectOf(cell);
    if (!rect) return;
    const layout = type.editorLayout ?? 'cell';
    const upload = uploadOf(field);
    const rejection = this.sheet.cells.liveRejection(
      record,
      recordId,
      field.id
    );
    const draft =
      initialKey ??
      rejection?.text ??
      type.format(valueOf(record, field.id), field, {
        record,
        messages: this.sheet.messages
      });
    this.draft = draft;
    this.draftDirty = false;
    this.editing = new Editing({
      pos,
      recordId,
      field,
      type,
      rect,
      layout,
      initialKey,
      draft
    });
    if (options.opener) this.editing.opener = true;
    this.draftKind = 'text';
    this.draftValue = undefined;
    if (upload) {
      this.editing.onUpload = (files) =>
        this.sheet.uploads.uploadFiles(recordId, field, files);
    }
  }

  /**
   * The open editor as a one-item list, rendered with `{{#each}}` keyed by
   * identity: each edit gets its own editor instance, and an editor's args
   * stay those of its own edit while it is torn down (EuiSelectable reads
   * its options from a scheduled blur handler after the edit ended).
   */
  @cached
  get editingList(): Editing[] {
    return this.editing ? [this.editing] : [];
  }

  /** The edited record, by id: the owner may have moved it (V02-DESIGN.md 3.2). */
  editorRecord = (editing: Editing): T | undefined =>
    this.sheet.args.records[
      this.sheet.rows.rowOf(
        editing.recordId,
        this.sheet.rows.hintOf(editing.pos.row)
      )
    ];

  editorValue = (editing: Editing): unknown =>
    valueOf(this.editorRecord(editing), editing.field.id);

  commit({
    move = [0, 0],
    refocus = true,
    result
  }: {
    move?: [number, number];
    refocus?: boolean;
    result?: SheetEditorResult<unknown>;
  } = {}): void {
    const editing = this.editing;
    if (!editing) return;
    // first: the re-entrancy guard. The focusout caused below (or by the
    // editor leaving the DOM) finds editing === null and returns.
    this.editing = null;
    // the edited record's row now; gone: nothing to save
    const row = this.sheet.rows.rowOf(
      editing.recordId,
      this.sheet.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    const pos = { row, col: editing.pos.col };
    const ctx = this.sheet.context;
    const touched = [{ id: editing.recordId, fieldId: editing.field.id }];
    if (result && 'value' in result) {
      this.sheet.changes.emit(commitValue(ctx, pos, result.value), touched);
    } else if (result && 'text' in result) {
      this.sheet.changes.emitText(ctx, pos, result.text, touched);
    } else if (this.draftDirty && this.draftKind === 'value') {
      this.sheet.changes.emit(commitValue(ctx, pos, this.draftValue), touched);
    } else if (this.draftDirty) {
      this.sheet.changes.emitText(ctx, pos, this.draft, touched);
    }
    if (refocus) {
      // synchronous is safe: the target row already exists
      const model = this.sheet.rows.rowModel;
      const from = this.sheet.rows.gridRowOf(pos.row);
      let row = clamp(
        from + move[0],
        model.firstRecordRow,
        model.lastRecordRow
      );
      // grouped: over a header or an add row to the next record (V03 8.6)
      if (this.sheet.rows.isGrouped && !this.sheet.rows.isRecordRow(row)) {
        const next = model.nearestRecordRow(row, move[0] < 0 ? -1 : 1);
        row = next >= 0 ? next : from;
      }
      this.sheet.dom.focusGridCell({
        row,
        col: clamp(
          pos.col + move[1],
          0,
          this.sheet.fields.visibleFields.length - 1
        )
      });
    }
  }

  cancel = (): void => {
    const editing = this.editing;
    if (!editing) return;
    this.editing = null;
    const row = this.sheet.rows.rowOf(
      editing.recordId,
      this.sheet.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    this.sheet.dom.focusGridCell({
      row: this.sheet.rows.gridRowOf(row),
      col: editing.pos.col
    });
  };

  /* Editor callbacks, bound once */

  onDraftChange = (text: string): void => {
    this.draft = text;
    this.draftDirty = true;
    this.draftKind = 'text';
  };

  onDraftValue = (value: unknown): void => {
    this.draftValue = value;
    this.draftDirty = true;
    this.draftKind = 'value';
  };

  /** The editor's `@onSave`: saves a value and keeps it open. */
  onEditorSave = (value: unknown): void => {
    const editing = this.editing;
    if (!editing) return;
    const row = this.sheet.rows.rowOf(
      editing.recordId,
      this.sheet.rows.hintOf(editing.pos.row)
    );
    if (row < 0) return;
    this.sheet.changes.emit(
      commitValue(this.sheet.context, { row, col: editing.pos.col }, value),
      [{ id: editing.recordId, fieldId: editing.field.id }]
    );
  };

  onEditorCommit = (
    result?: SheetEditorResult<unknown>,
    options?: { move?: [number, number] }
  ): void => {
    this.commit({ result, move: options?.move });
  };

  onEditorFocusOut = (): void => {
    // no refocus: a clicked cell must keep focus
    if (this.editing) this.commit({ refocus: false });
  };

  /**
   * How far a cell editor grows past its cell (V03 batch 1): 2 px on each
   * side, less where the grid body's visible area ends (the header, the
   * frozen edge, the scroll bars), so it is not cut off.
   */
  growOf = (
    editing: Editing
  ): {
    top: number;
    right: number;
    bottom: number;
    left: number;
  } => {
    const rect = editing.rect;
    const wrapper = this.sheet.wrapper;
    const bounds = this.sheet.scroll.scrollBounds();
    const side = (room: number) => clamp(Math.floor(room), 0, 2);
    if (!wrapper || !bounds) return { top: 0, right: 0, bottom: 0, left: 0 };
    const origin = wrapper.getBoundingClientRect();
    const scale = wrapper.offsetWidth ? origin.width / wrapper.offsetWidth : 1;
    const clipLeft =
      bounds.frozenRight !== undefined &&
      editing.pos.col >= this.sheet.frozen.frozenCount
        ? bounds.frozenRight
        : bounds.left;
    const toWrapper = (x: number, from: number) => (x - from) / scale;
    return {
      top: side(rect.top - toWrapper(bounds.top, origin.top)),
      left: side(rect.left - toWrapper(clipLeft, origin.left)),
      right: side(
        toWrapper(bounds.right, origin.left) - rect.left - rect.width
      ),
      bottom: side(
        toWrapper(bounds.bottom, origin.top) - rect.top - rect.height
      )
    };
  };

  /** A header drag starting (V03 5.3, CD9) saves the open editor first. */
  @action
  onDragStart(): void {
    if (this.editing) this.commit({ refocus: false });
  }
}
