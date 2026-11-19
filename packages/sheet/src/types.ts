/** Ember-layer types: field types with components, and the signatures (PACKAGE-DESIGN.md 9.1). */
import type {
  CellErrors,
  ChangeSet,
  EuiSheetField,
  FieldType,
  RecordId,
  SheetMessages,
  ValidateContext
} from './core/index.ts';
import type { ComponentLike } from '@glint/template';

export interface EuiSheetFieldType<
  V = unknown,
  F extends EuiSheetField = EuiSheetField
> extends FieldType<V, F> {
  /** Display component. Default: the formatted text. */
  cell?: ComponentLike<SheetCellSignature<V, F>>;
  /** Editor component. Without one the type has no edit mode (navKey and the cell's @onCommit still work). */
  editor?: ComponentLike<SheetEditorSignature<V, F>>;
  /** 'cell': the editor covers the cell. 'panel': a panel under (or above) the cell. Default 'cell'. */
  editorLayout?: 'cell' | 'panel';
  /** Whether a printable key opens the editor. Default: yes. Space never does. */
  opensOnKey?: (key: string) => boolean;
  /** Keys the editor handles itself while it is open. Default: none. */
  handlesKey?: (event: KeyboardEvent) => boolean;
  /**
   * An EUI icon type (e.g. `'arrowDown'`, `'calendar'`) shown at the end of
   * the hovered or selected cell; a click on it opens the editor at once.
   * Default: none (a second click on the selected cell opens it).
   */
  opener?: string;
  /**
   * A click anywhere in the cell saves the value it returns (the checkbox
   * toggles), instead of selecting then editing. `undefined`: nothing.
   */
  onCellClick?: (
    value: V | null | undefined,
    field: F,
    record: unknown
  ) => { value: V | null } | undefined;
}

export interface SheetCellSignature<
  V = unknown,
  F extends EuiSheetField = EuiSheetField,
  T = any
> {
  Args: {
    value: V | null | undefined;
    /** type.format(value). */
    text: string;
    field: F;
    record: T;
    errors: string[];
    readOnly: boolean;
    /** Saves a value from the cell itself (a checkbox, a rating star). */
    onCommit: (value: V) => void;
  };
}

export type SheetEditorResult<V> = { value: V } | { text: string };

export interface SheetEditorSignature<
  V = unknown,
  F extends EuiSheetField = EuiSheetField,
  T = any
> {
  Args: {
    value: V | null | undefined;
    field: F;
    record: T;
    /** Initial text: the typed character, else the cell's rejected text, else type.format(value). */
    draft: string;
    /** The printable key that opened the editor, or null (Enter, F2, double-click). */
    initialKey: string | null;
    /** Reports the text to parse if the editor is closed by blur, scroll, or a key the sheet handles. */
    onDraftChange: (text: string) => void;
    /** Closes the editor. `{ value }` is saved as is, `{ text }` goes through type.parse, nothing saves the reported draft. `move` is [rows, cols]; default [0, 0]. */
    onCommit: (
      result?: SheetEditorResult<V>,
      options?: { move?: [number, number] }
    ) => void;
    /** Closes the editor without a change and focuses the cell. */
    onCancel: () => void;
    messages: SheetMessages;
    /**
     * The class that defines the sheet's theme colours (`--euiSheet-*`). An
     * editor that renders a surface outside the sheet (a wormholed list or
     * calendar) adds it to that surface, which otherwise gets the light
     * fallbacks. Optional, so a wrapper that renders a built-in editor
     * itself (`SheetInputEditor`) keeps working; the sheet always passes it.
     */
    themeClass?: string;
  };
}

/**
 * What `@registerApi` gives the owner: one stable object, passed once,
 * after the first render.
 */
export interface SheetApi {
  /** Ctrl/Cmd+Z: emits the undo of the last change made in the sheet. */
  undo(): void;
  /** Ctrl/Cmd+Shift+Z: emits the last undone change again. */
  redo(): void;
  /** Focuses a cell by record and field. No-op when the record is not in `@records` or the field is not shown. */
  focusCell(cell: { recordId: RecordId; fieldId: string }): void;
  /**
   * Tells the sheet the ids the owner gave to inserted (or restored)
   * records: `{ [tempId or old id]: newId }`. The undo history, the
   * rejected texts and a pending focus are rewritten, so undo still finds
   * them. Call it before (or with) the `@records` that carry the new ids.
   */
  remapIds(ids: Record<string, RecordId>): void;
  /** Drops the undo and redo stacks (call it when your data changed wholesale). */
  clearHistory(): void;
}

/** The cell's box relative to the sheet's wrapper, in CSS px. */
export interface SheetEditorRect {
  top: number;
  left: number;
  width: number;
  height: number;
  /** The wrapper's height, for a panel placed above the cell. */
  wrapperHeight: number;
}

export interface EuiSheetSignature<T> {
  Element: HTMLDivElement;
  Args: {
    fields: EuiSheetField<T>[];
    records: T[];
    getRecordId: (record: T) => RecordId;
    onChange: (changeSet: ChangeSet) => void;
    /** Owner errors: recordId (as a string) → fieldId → message(s). Shown last. */
    cellErrors?: CellErrors;
    height?: number | string;
    /** App field types, merged over the built-ins. Keep the object stable (not created in a template). */
    fieldTypes?: Record<string, EuiSheetFieldType<any, any>>;
    /** Every field read-only. */
    readOnly?: boolean;
    /** Overrides of the built-in messages; wins over `eui-i18n` translations. */
    messages?: Partial<SheetMessages>;
    /** The grid's aria-label. Default 'Sheet'. */
    ariaLabel?: string;
    /**
     * Record, cross-row and async rules (PACKAGE-DESIGN.md 9.4, layers 4–6).
     * Runs (debounced) on first render, when `@records` changes and after
     * each emitted change set. A newer run aborts `signal`; a stale result
     * is discarded, and an error is dropped for a record that changed since
     * its run started.
     */
    validate?: (
      context: ValidateContext<T>
    ) => CellErrors | Promise<CellErrors>;
    /** Receives the sheet's API (`undo`, `redo`, `focusCell`, `remapIds`, `clearHistory`) once, after the first render. */
    registerApi?: (api: SheetApi) => void;
  };
}
