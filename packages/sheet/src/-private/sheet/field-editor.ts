/** Field management: the field editor, its handlers, and placing created fields (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { modifier } from 'ember-modifier';

import { CREATABLE_FIELD_TYPES, withoutField } from '../../core/index.ts';
import { draftOf, FIELD_EDITOR_WIDTH } from '../field-editor.gts';
import { ADD_FIELD_COLUMN_ID, afterRender, clamp } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type {
  ChangeSet,
  EuiSheetField,
  SheetFieldDraft
} from '../../core/index.ts';
import type { SheetFieldEditorType } from '../../types.ts';
import type { HistoryEntry, WrapperBox } from './types.ts';

/** The message of a rejected field handler: `error.message`, else the value as text. */
function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return typeof error === 'string' ? error : String(error);
}

/** A field's type name. */
const typeName = (field: EuiSheetField): string => field.type ?? 'text';

/**
 * The open field editor (V03 6.4): what it edits, where it is, and the
 * handler's promise state.
 */
export class FieldEditorState {
  mode: 'create' | 'edit' | 'delete';
  /** The field edited or deleted. */
  fieldId?: string;
  /** Where a created field goes. */
  position?: { index: number; after?: string };
  draft: SheetFieldDraft;
  /** Its anchor, relative to the wrapper: the header (or the header row's right end). */
  anchor: WrapperBox;
  /** The header focused when it closes: by column id, else by grid column index. */
  returnTo: { columnId: string; index: number };
  @tracked isSaving = false;
  @tracked error: string | undefined = undefined;

  constructor(init: {
    mode: FieldEditorState['mode'];
    fieldId?: string;
    position?: FieldEditorState['position'];
    draft: SheetFieldDraft;
    anchor: WrapperBox;
    returnTo: FieldEditorState['returnTo'];
  }) {
    this.mode = init.mode;
    this.fieldId = init.fieldId;
    this.position = init.position;
    this.draft = init.draft;
    this.anchor = init.anchor;
    this.returnTo = init.returnTo;
  }
}

export default class SheetFieldEditor<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The open field editor (V03 6.4). */
  @tracked fieldEditorState: FieldEditorState | null = null;
  /** Every field id of the last render (`@fields` and `@hiddenFields`) and its type: what `watchFields` compares with. */
  lastFieldTypes: Map<string, string> | null = null;
  /** A created field without `@onFieldOrderChange` goes into the sheet's own order after this field (V03 6.8). */
  createdAfter: { after: string | undefined } | null = null;

  /** The field editor is open from the "+" header: it shows as open. */
  get addingField(): boolean {
    return this.fieldEditorState?.returnTo.columnId === ADD_FIELD_COLUMN_ID;
  }

  /** The open field editor, as a list keyed by its state (a new one starts a new form). */
  get fieldEditorList(): FieldEditorState[] {
    return this.fieldEditorState ? [this.fieldEditorState] : [];
  }

  /**
   * The types the field editor offers: `@creatableFieldTypes` (default
   * `CREATABLE_FIELD_TYPES`) that exist, and on edit the field's own type
   * first when it is not one of them (a linked record field keeps its type).
   */
  fieldEditorTypes(
    field: EuiSheetField<T> | undefined,
    mode: FieldEditorState['mode']
  ): SheetFieldEditorType[] {
    const names = [
      ...(this.sheet.args.creatableFieldTypes ?? CREATABLE_FIELD_TYPES)
    ];
    if (field && mode !== 'create' && !names.includes(typeName(field))) {
      names.unshift(typeName(field));
    }
    const messages = this.sheet.messages as unknown as Record<
      string,
      (() => string) | undefined
    >;
    const types: SheetFieldEditorType[] = [];
    for (const name of names) {
      const type = this.sheet.types[name];
      if (!type) continue;
      const entry: SheetFieldEditorType = {
        name,
        label: type.label ?? messages[`fieldType_${name}`]?.() ?? name
      };
      if (type.fieldOptions) entry.fieldOptions = type.fieldOptions;
      types.push(entry);
    }
    return types;
  }

  /**
   * Where the field editor goes: under the header of `columnId` (else the
   * "+" header), its left edge kept inside the wrapper; without either, at
   * the wrapper's top right, under the header row (a hidden field, V03
   * 6.8). The layer places it in the viewport from there (below, or above
   * when there is no room below; clamped, then scrolling).
   */
  fieldEditorPlace(columnId: string): { anchor: WrapperBox } {
    const width = this.sheet.wrapper?.offsetWidth ?? FIELD_EDITOR_WIDTH;
    const maxLeft = Math.max(0, width - FIELD_EDITOR_WIDTH);
    const header =
      this.sheet.dom.headerElement(columnId) ??
      (this.sheet.gridColumns.hasAddFieldColumn
        ? this.sheet.dom.headerElement(ADD_FIELD_COLUMN_ID)
        : null);
    const rect = header && this.sheet.dom.rectOf(header);
    if (rect) {
      return {
        anchor: {
          top: rect.top,
          left: clamp(rect.left, 0, maxLeft),
          width: rect.width,
          height: rect.height
        }
      };
    }
    const any = this.sheet.wrapper?.querySelector<HTMLElement>(
      '[role=columnheader]'
    );
    const anyRect = any && this.sheet.dom.rectOf(any);
    return {
      anchor: {
        top: anyRect ? anyRect.top : 0,
        left: maxLeft,
        width: 0,
        height: anyRect ? anyRect.height : 0
      }
    };
  }

  openFieldEditor(
    init: ConstructorParameters<typeof FieldEditorState>[0]
  ): void {
    if (this.sheet.edit.editing) this.sheet.edit.commit({ refocus: false });
    if (this.sheet.rowMenu.menu) this.sheet.rowMenu.closeMenu(false);
    this.fieldEditorState = new FieldEditorState(init);
  }

  /**
   * `api.addField`, the "+" column, "Insert left/right": the editor to
   * create a field at `index` among the visible fields (default the end;
   * never before the first field), under `columnId`'s header.
   */
  addField(index?: number, columnId?: string, after?: string): void {
    if (!this.sheet.args.onFieldCreate) return;
    const fields = this.sheet.fields.visibleFields;
    const count = fields.length;
    const at = clamp(index ?? count, count ? 1 : 0, count);
    const afterId = after ?? fields[at - 1]?.id;
    const anchor =
      columnId ??
      (this.sheet.gridColumns.hasAddFieldColumn
        ? ADD_FIELD_COLUMN_ID
        : (afterId ?? ''));
    const position: { index: number; after?: string } = { index: at };
    if (afterId !== undefined) position.after = afterId;
    const types = this.fieldEditorTypes(undefined, 'create');
    const type = types.some((entry) => entry.name === 'text')
      ? 'text'
      : (types[0]?.name ?? 'text');
    this.openFieldEditor({
      mode: 'create',
      position,
      draft: { label: '', type },
      ...this.fieldEditorPlace(anchor),
      returnTo: {
        columnId: anchor,
        index: this.sheet.gridColumns.gridIndexOf(anchor)
      }
    });
  }

  /** `api.editField` and "Edit field": the editor on a field, also a hidden one. */
  editField(fieldId: string): void {
    if (!this.sheet.args.onFieldUpdate) return;
    const field = this.sheet.fields.fieldById(fieldId);
    if (!field || field.manageable === false) return;
    const columnId = this.sheet.fields.visibleFieldIds.includes(fieldId)
      ? fieldId
      : ADD_FIELD_COLUMN_ID;
    this.openFieldEditor({
      mode: 'edit',
      fieldId,
      draft: draftOf(field),
      ...this.fieldEditorPlace(columnId),
      returnTo: {
        columnId,
        index: this.sheet.gridColumns.gridIndexOf(columnId)
      }
    });
  }

  /** "Duplicate field": `@onFieldCreate` at once, with a copy of the field's draft next to it. */
  duplicateField(fieldId: string): void {
    const handler = this.sheet.args.onFieldCreate;
    const index = this.sheet.fields.visibleFieldIds.indexOf(fieldId);
    const field = this.sheet.fields.visibleFields[index];
    if (!handler || !field || field.manageable === false) return;
    const draft: SheetFieldDraft = {
      ...draftOf(field),
      label: this.sheet.messages.duplicateFieldLabel(field.label ?? field.id)
    };
    this.noteCreatedAfter(field.id);
    void handler(draft, {
      index: index + 1,
      after: field.id,
      copyOf: field.id
    });
  }

  /** "Delete field": the confirmation, in the editor's frame (V03 6.6). */
  askDeleteField(fieldId: string): void {
    const field = this.sheet.fields.fieldById(fieldId);
    if (
      !this.sheet.args.onFieldDelete ||
      !field ||
      field.manageable === false
    ) {
      return;
    }
    if (this.sheet.fields.visibleFieldIds[0] === fieldId) return;
    this.openFieldEditor({
      mode: 'delete',
      fieldId,
      draft: draftOf(field),
      ...this.fieldEditorPlace(fieldId),
      returnTo: {
        columnId: fieldId,
        index: this.sheet.gridColumns.gridIndexOf(fieldId)
      }
    });
  }

  /** Save in the editor: `@onFieldCreate` or `@onFieldUpdate`. */
  saveFieldEditor(draft: SheetFieldDraft): void {
    const state = this.fieldEditorState;
    if (!state || state.isSaving) return;
    if (state.mode === 'create') {
      const handler = this.sheet.args.onFieldCreate;
      if (!handler) return;
      const position = { ...state.position! };
      this.noteCreatedAfter(position.after);
      this.runFieldHandler(state, () => handler(draft, position));
      return;
    }
    const handler = this.sheet.args.onFieldUpdate;
    const previous = this.sheet.fields.fieldById(state.fieldId);
    if (!handler || !previous || state.mode !== 'edit') return;
    this.runFieldHandler(state, () =>
      handler(previous.id, draft, { previous })
    );
  }

  /** The delete confirmation's button: `@onFieldDelete`. */
  confirmDeleteField(): void {
    const state = this.fieldEditorState;
    const handler = this.sheet.args.onFieldDelete;
    if (!state || state.isSaving || state.mode !== 'delete' || !handler) return;
    const fieldId = state.fieldId!;
    this.runFieldHandler(state, () => handler(fieldId));
  }

  /**
   * Calls a field handler (V03 6.2): without a promise the editor closes
   * at once; with one it stays open, busy, and closes when it resolves or
   * shows the rejection's message.
   */
  runFieldHandler(
    state: FieldEditorState,
    call: () => void | Promise<void>
  ): void {
    state.error = undefined;
    let result: unknown;
    try {
      result = call();
    } catch (error) {
      state.error = errorMessage(error);
      return;
    }
    if (!result || typeof (result as Promise<void>).then !== 'function') {
      this.closeFieldEditor(true);
      return;
    }
    state.isSaving = true;
    (result as Promise<void>).then(
      () => {
        if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
        state.isSaving = false;
        if (this.fieldEditorState === state) this.closeFieldEditor(true);
      },
      (error: unknown) => {
        if (isDestroying(this.sheet) || isDestroyed(this.sheet)) return;
        state.isSaving = false;
        state.error = errorMessage(error);
      }
    );
  }

  /**
   * Closes the field editor; `refocus` focuses the header it belongs to.
   * Not while its handler's promise is pending: Escape, Cancel, a click
   * outside or a scroll then do nothing, so a rejection is still shown
   * (V03 6.2).
   */
  closeFieldEditor(refocus: boolean): void {
    const state = this.fieldEditorState;
    if (!state || state.isSaving) return;
    this.fieldEditorState = null;
    if (!refocus) return;
    afterRender(this.sheet, () => this.sheet.dom.focusHeader(state.returnTo));
  }

  /** Without `@onFieldOrderChange` but with the sheet's own order, a created field goes after this one (V03 6.8). */
  noteCreatedAfter(after: string | undefined): void {
    this.createdAfter =
      this.sheet.fields.localOrder && !this.sheet.args.onFieldOrderChange
        ? { after }
        : null;
  }

  /** Whenever `@fields` or `@hiddenFields` is a new array: after the render, `fieldsRendered`. */
  watchFields = modifier(
    (_element: HTMLElement, [fields, hidden]: [unknown, unknown]) => {
      void fields;
      void hidden;
      afterRender(this.sheet, () => this.fieldsRendered());
    }
  );

  /**
   * After `@fields` or `@hiddenFields` changed (V03 6.6): a field that is
   * gone from both, or whose type changed, is forgotten (its undo
   * entries, rejected texts, pending cells, an editor on it); a created
   * field is placed in the sheet's own order; the selection is clamped.
   * A hide moves a field between the two lists and is not a loss.
   */
  fieldsRendered(): void {
    const all = [
      ...this.sheet.args.fields,
      ...(this.sheet.args.hiddenFields ?? [])
    ];
    const now = new Map(all.map((field) => [field.id, typeName(field)]));
    const before = this.lastFieldTypes;
    this.lastFieldTypes = now;
    if (!before) return;
    const gone: string[] = [];
    for (const [id, type] of before) {
      if (now.get(id) !== type) gone.push(id);
    }
    const created = this.createdAfter;
    if (created) {
      const added = [...now.keys()].filter((id) => !before.has(id));
      if (added.length) {
        this.createdAfter = null;
        this.placeCreated(added, created.after);
      }
    }
    if (gone.length) this.forgetFields(gone);
    this.sheet.selection.clampSelection();
  }

  /** Puts created fields into the sheet's own order after `after`. */
  placeCreated(ids: string[], after: string | undefined): void {
    const order = this.sheet.fields.localOrder;
    if (!order || this.sheet.args.onFieldOrderChange) return;
    const rest = order.filter((id) => !ids.includes(id));
    const at = after === undefined ? 0 : rest.indexOf(after) + 1;
    if (after !== undefined && at === 0) rest.push(...ids);
    else rest.splice(at, 0, ...ids);
    this.sheet.fields.localOrder = rest;
  }

  /** Drops what the sheet keeps per field for fields the owner deleted or retyped (V03 6.6). */
  forgetFields(fieldIds: string[]): void {
    const ids = new Set(fieldIds);
    const prune = (entries: HistoryEntry[]): HistoryEntry[] => {
      const kept: HistoryEntry[] = [];
      for (const entry of entries) {
        let changeSet: ChangeSet | null = entry.changeSet;
        for (const id of fieldIds) {
          if (changeSet) changeSet = withoutField(changeSet, id);
        }
        const rejections = entry.rejections.filter(
          (rejection) => !ids.has(rejection.fieldId)
        );
        if (!changeSet) continue;
        if (
          changeSet === entry.changeSet &&
          rejections.length === entry.rejections.length
        ) {
          kept.push(entry);
          continue;
        }
        const next = { changeSet, rejections };
        this.sheet.history.replaceEntry(entry, next);
        kept.push(next);
      }
      return kept;
    };
    this.sheet.history.undoStack = prune(this.sheet.history.undoStack);
    this.sheet.history.redoStack = prune(this.sheet.history.redoStack);
    if (
      [...this.sheet.cells.rejections.values()].some((r) => ids.has(r.fieldId))
    ) {
      this.sheet.cells.rejections = new Map(
        [...this.sheet.cells.rejections].filter(([, r]) => !ids.has(r.fieldId))
      );
    }
    const pendingKeys = [...this.sheet.resolve.pendingCells]
      .filter(([, entry]) => entry.cell && ids.has(entry.cell.fieldId))
      .map(([key]) => key);
    const uploadKeys = [...this.sheet.resolve.pendingCells.keys()].filter(
      (key) => ids.has(key.slice(key.indexOf('\u0000') + 1))
    );
    const keys = [...new Set([...pendingKeys, ...uploadKeys])];
    if (keys.length) this.sheet.resolve.dropPending(keys);
    if (this.sheet.edit.editing && ids.has(this.sheet.edit.editing.field.id))
      this.sheet.edit.editing = null;
    const state = this.fieldEditorState;
    // our own save in flight closes the editor itself
    if (state?.fieldId && ids.has(state.fieldId) && !state.isSaving) {
      this.closeFieldEditor(false);
    }
  }
}
