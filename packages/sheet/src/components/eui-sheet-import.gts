/**
 * EuiSheetImport (v0.4 10): the import screen. It reads a CSV file (or a
 * text, or an already parsed matrix), proposes a field for each column
 * (a saved mapping, then `importAliases`, label and id), guesses each
 * column's type, and shows a preview of what the import writes, with the
 * totals of a dry run over every line. The user changes a column's target
 * (a field, a new field, or nothing), its transform and its built-in
 * options; on Import, `@onCreateFields` creates the new fields and
 * `@onImport` gets the lines to append.
 *
 * A view over the pure helpers of `src/core/import.ts`. It takes no sheet,
 * renders inline (the app places it in its own modal, flyout or page) and
 * keeps no state outside itself. Nothing in the sheet imports it, so an
 * app that does not use it does not load it.
 */
import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { cancel, later } from '@ember/runloop';
import { service } from '@ember/service';
import { buildWaiter } from '@ember/test-waiters';

import EuiButton from '@ember-eui/core/components/eui-button';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiCallOut from '@ember-eui/core/components/eui-call-out';
import EuiLink from '@ember-eui/core/components/eui-link';
import EuiLoadingSpinner from '@ember-eui/core/components/eui-loading-spinner';
import EuiRadioGroup from '@ember-eui/core/components/eui-radio-group';
import EuiSelect from '@ember-eui/core/components/eui-select';
import EuiSwitch from '@ember-eui/core/components/eui-switch';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

import {
  CREATABLE_FIELD_TYPES,
  createMessages,
  decodeText,
  detectDelimiter,
  errorsCsv,
  guessColumn,
  importFieldId,
  importSignature,
  matchColumns,
  parseCsv,
  previewImport,
  runImport,
  suggestValueMap
} from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import { ensureStyles } from '../-private/styles.ts';
import { sheetThemeVars } from '../-private/theme.ts';
import { ensureImportStyles } from '../-private/import/styles.ts';
import ImportColumnRow from '../-private/import/column-row.gts';
import ImportPreviewTable from '../-private/import/preview-table.gts';
import {
  DATE_TYPES,
  DECIMAL_TYPES,
  MAP_TYPES,
  TARGET_NEW,
  TARGET_SKIP,
  draftFromGuess,
  editorTypes,
  errorMessage,
  isWritable,
  targetValue,
  typeText,
  valueChoices
} from '../-private/import/model.ts';

import type {
  EuiSheetField,
  SheetColumnGuess,
  SheetImportCell,
  SheetImportColumn,
  SheetImportContext,
  SheetImportFieldDraft,
  SheetImportMapping,
  SheetImportPreview,
  SheetImportRun,
  SheetImportTransform,
  SheetMessages
} from '../core/index.ts';
import type {
  EuiSheetFieldType,
  EuiSheetImportSignature,
  SheetFieldEditorType,
  SheetImportResult
} from '../types.ts';
import type { ValueChoice } from '../-private/import/model.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type Owner from '@ember/owner';
import type { Timer } from '@ember/runloop';

export type { EuiSheetImportSignature, SheetImportResult };

const waiter = buildWaiter('@ember-eui/sheet:import');

/** The dry run waits this long after the last change of the plan (v0.4 10, "Large files"). */
export const IMPORT_DRY_RUN_DEBOUNCE = 250;

/** Sample texts shown under a column's header. */
const SAMPLES = 3;

/** A parsed source: its lines, and the delimiter (none for `@matrix`). */
interface Parsed {
  matrix: string[][];
  delimiter: string | null;
  /** The file's name and encoding (`@file` only). */
  name?: string;
  encoding?: 'utf-8' | 'windows-1252';
}

/** One file column's texts and guesses (per parsed source and header choice). */
interface ColumnData {
  /** The header as shown (`Column 3` when there is none). */
  name: string;
  /** The data lines' texts. */
  texts: string[];
  samples: string[];
  guesses: SheetColumnGuess[];
}

/** The user's changes to the proposed plan, per column, for one parsed source and header choice. */
interface Overrides {
  parsed: Parsed;
  headers: boolean;
  byColumn: Record<number, Partial<SheetImportColumn>>;
}

/** A remembered dry run. */
interface RunState {
  parsed: Parsed;
  headers: boolean;
  columns: SheetImportColumn[];
  fields: EuiSheetField[];
  run: SheetImportRun;
}

/** What one row of the columns table shows. */
export interface ImportColumnView {
  index: number;
  column: SheetImportColumn;
  name: string;
  samples: string[];
  badge: { text: string; color: string; title: string } | null;
  targetValue: string;
  /** A field another column goes to is disabled (a field takes one column; the arrow keys of a closed select skip it). */
  targetOptions: Array<{ value: string; text: string; disabled?: boolean }>;
  /** The header names a field another column takes. */
  takenNote: string | null;
  isSkip: boolean;
  /** A new field's draft and its summary. */
  newField: SheetImportFieldDraft | null;
  newFieldText: string | null;
  /** The field the column is read with (the target, or the new field's draft). */
  field: EuiSheetField | null;
  showTransform: boolean;
  transformValue: string;
  dateOrder: 'dmy' | 'mdy' | null;
  decimalSeparator: '.' | ',' | null;
  /** The value map's table (select and checkbox targets). */
  valueMap: {
    texts: string[];
    choices: ValueChoice[];
    map: Readonly<Record<string, unknown>>;
    mapped: number;
  } | null;
  status: { read: number; total: number; errors: number } | null;
  formOpen: boolean;
  valuesOpen: boolean;
}

export default class EuiSheetImport<T = any> extends Component<
  EuiSheetImportSignature<T>
> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  id = guidFor(this);

  /** The file read so far (`@file`): its text and encoding. */
  @tracked decoded: {
    file: File;
    text: string;
    encoding: 'utf-8' | 'windows-1252';
  } | null = null;
  /** A file that could not be read, and why. */
  @tracked readError: { file: File; message: string } | null = null;
  /** The file being read (not tracked: a getter starts the read). */
  reading: File | null = null;

  /** The user's delimiter and header choices, for one source. */
  @tracked delimiterChoice: { source: unknown; value: string } | null = null;
  @tracked headersChoice: { source: unknown; value: boolean } | null = null;
  @tracked overrides: Overrides | null = null;

  /** Fields `@onCreateFields` created (they read their columns until `@fields` has them). */
  @tracked created: EuiSheetField<T>[] = [];
  /** The created fields not yet given to a successful `@onImport`. */
  unreported: EuiSheetField<T>[] = [];

  @tracked skipErrors = false;
  /** The column whose unreadable lines the preview shows. */
  @tracked filterColumn: number | null = null;
  @tracked formOpen: number | null = null;
  @tracked valuesOpen: number | null = null;
  @tracked busy = false;
  @tracked error: string | null = null;

  /* the dry run: remembered untracked; the timer bumps `runTick` */
  runState: RunState | null = null;
  @tracked runTick = 0;
  runTimer: Timer | null = null;
  runTimerFor: SheetImportColumn[] | null = null;
  runWaiter: unknown = null;

  /** Messages through `eui-i18n` (each call looks its token up). */
  translatedMessages: SheetMessages = createMessages((token, def, values) =>
    this.euiI18n.lookupToken(token, def, values)
  );

  constructor(owner: Owner, args: EuiSheetImportSignature<T>['Args']) {
    super(owner, args);
    // the new-field form is the sheet's field editor content: its styles
    ensureStyles();
    ensureImportStyles();
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.runTimer) cancel(this.runTimer);
    this.runTimer = null;
    this.endRunWaiter();
  }

  get gone(): boolean {
    return isDestroying(this) || isDestroyed(this);
  }

  /* -------------------------------------------------------------------- */
  /* Arguments                                                             */
  /* -------------------------------------------------------------------- */

  @cached
  get messages(): SheetMessages {
    return { ...this.translatedMessages, ...this.args.messages };
  }

  @cached
  get types(): Record<string, EuiSheetFieldType<any, any>> {
    return { ...builtInSheetFieldTypes, ...this.args.fieldTypes };
  }

  get transforms(): SheetImportTransform[] {
    return this.args.transforms ?? [];
  }

  get sampleSize(): number {
    return this.args.sampleSize ?? 20;
  }

  get creatableTypes(): readonly string[] {
    return this.args.creatableFieldTypes ?? CREATABLE_FIELD_TYPES;
  }

  get canCreate(): boolean {
    return typeof this.args.onCreateFields === 'function';
  }

  /** `@fields` and the fields created on the way that `@fields` does not have yet. */
  @cached
  get allFields(): EuiSheetField<T>[] {
    const fields = this.args.fields ?? [];
    if (!this.created.length) return fields;
    const known = new Set(fields.map((field) => field.id));
    return [...fields, ...this.created.filter((field) => !known.has(field.id))];
  }

  @cached
  get writableFields(): EuiSheetField<T>[] {
    return this.allFields.filter((field) => isWritable(field));
  }

  @cached
  get fieldById(): Map<string, EuiSheetField<T>> {
    return new Map(this.allFields.map((field) => [field.id, field]));
  }

  @cached
  get ctx(): SheetImportContext {
    return {
      types: this.types,
      messages: this.messages,
      fields: this.allFields
    };
  }

  @cached
  get themeClass(): string {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, sheetThemeVars));
  }

  @cached
  get editorTypes(): SheetFieldEditorType[] {
    return editorTypes(this.types, this.messages, this.creatableTypes);
  }

  /* -------------------------------------------------------------------- */
  /* The source                                                            */
  /* -------------------------------------------------------------------- */

  /** What the source is now: the file, the text or the matrix (keys the user's choices). */
  get source(): unknown {
    return (
      this.args.file ??
      (typeof this.args.text === 'string' ? this.args.text : null) ??
      this.args.matrix ??
      null
    );
  }

  get isFile(): boolean {
    return Boolean(this.args.file);
  }

  /** The source as text (`@file` once read, or `@text`); `null` for `@matrix` or while a file is read. */
  @cached
  get sourceText(): string | null {
    const file = this.args.file;
    if (file) {
      if (this.decoded?.file === file) return this.decoded.text;
      this.readFile(file);
      return null;
    }
    return typeof this.args.text === 'string' ? this.args.text : null;
  }

  get isReading(): boolean {
    const file = this.args.file;
    return Boolean(
      file && this.decoded?.file !== file && this.readError?.file !== file
    );
  }

  get fileError(): string | null {
    const file = this.args.file;
    return file && this.readError?.file === file
      ? this.readError.message
      : null;
  }

  /** Reads a file's bytes once (a getter calls it: it writes tracked state only when the read ends). */
  readFile(file: File): void {
    if (this.reading === file) return;
    this.reading = file;
    const token = waiter.beginAsync();
    file
      .arrayBuffer()
      .then((bytes) => {
        if (this.gone || this.args.file !== file) return;
        const { text, encoding } = decodeText(bytes);
        this.decoded = { file, text, encoding };
      })
      .catch((error: unknown) => {
        if (this.gone || this.args.file !== file) return;
        this.readError = { file, message: errorMessage(error) };
      })
      .finally(() => waiter.endAsync(token));
  }

  get delimiter(): string | null {
    const text = this.sourceText;
    if (text === null) return null;
    const choice = this.delimiterChoice;
    return choice && choice.source === this.source
      ? choice.value
      : detectDelimiter(text);
  }

  @cached
  get parsed(): Parsed | null {
    const text = this.sourceText;
    if (text !== null) {
      const delimiter = this.delimiter ?? ',';
      const parsed: Parsed = {
        matrix: parseCsv(text, { delimiter }),
        delimiter
      };
      const file = this.args.file;
      if (file && this.decoded?.file === file) {
        parsed.name = file.name;
        parsed.encoding = this.decoded.encoding;
      }
      return parsed;
    }
    if (!this.args.file && Array.isArray(this.args.matrix)) {
      return { matrix: this.args.matrix, delimiter: null };
    }
    return null;
  }

  get headers(): boolean {
    const choice = this.headersChoice;
    return choice && choice.source === this.source ? choice.value : true;
  }

  /** The number of columns: the widest line. */
  @cached
  get width(): number {
    let width = 0;
    for (const line of this.parsed?.matrix ?? []) {
      if (line.length > width) width = line.length;
    }
    return width;
  }

  /** The plan's headers: the header line's texts, or `Column N` without one (so a transform's `row` has a key per column). */
  @cached
  get headerTexts(): string[] {
    const matrix = this.parsed?.matrix ?? [];
    const texts: string[] = [];
    for (let j = 0; j < this.width; j++) {
      texts.push(
        this.headers
          ? (matrix[0]?.[j] ?? '')
          : this.messages.importColumnN(j + 1)
      );
    }
    return texts;
  }

  /** The data lines' indexes: no header line, no line whose cells are all blank (as the helpers read them). */
  @cached
  get dataLines(): number[] {
    const matrix = this.parsed?.matrix ?? [];
    const lines: number[] = [];
    for (let i = this.headers ? 1 : 0; i < matrix.length; i++) {
      if (!matrix[i]!.every((text) => text.trim() === '')) lines.push(i);
    }
    return lines;
  }

  @cached
  get columnData(): ColumnData[] {
    const matrix = this.parsed?.matrix ?? [];
    const lines = this.dataLines;
    // types and messages only: a created field does not change a guess
    const typeCtx = { types: this.types, messages: this.messages };
    return this.headerTexts.map((header, j) => {
      const texts = lines.map((i) => matrix[i]![j] ?? '');
      const samples: string[] = [];
      for (const text of texts) {
        if (text.trim() === '') continue;
        samples.push(text);
        if (samples.length === SAMPLES) break;
      }
      return {
        name:
          header.trim() === '' ? this.messages.importColumnN(j + 1) : header,
        texts,
        samples,
        guesses: guessColumn(typeCtx, texts, this.creatableTypes)
      };
    });
  }

  /* -------------------------------------------------------------------- */
  /* The plan                                                              */
  /* -------------------------------------------------------------------- */

  /** The value map's prefill for a column going to `field`, or `undefined`. */
  prefill(
    index: number,
    field: EuiSheetField | null
  ): Record<string, unknown> | undefined {
    if (!field || !MAP_TYPES.has(field.type ?? 'text')) return undefined;
    const texts = this.columnData[index]?.texts ?? [];
    const { map } = suggestValueMap(texts, field);
    return Object.keys(map).length ? map : undefined;
  }

  /** A new field's draft for a column, from its guess. */
  draftFor(index: number): SheetImportFieldDraft {
    const data = this.columnData[index];
    return draftFromGuess(
      data?.name ?? this.messages.importColumnN(index + 1),
      data?.guesses[0]
    );
  }

  /** The field a column is read with: its target, or its new field's draft. */
  fieldOf(column: SheetImportColumn): EuiSheetField | null {
    const target = column.target;
    if (target === 'skip') return null;
    if ('newField' in target) {
      return { ...target.newField, id: importFieldId(column.index) };
    }
    return this.fieldById.get(target.field) ?? null;
  }

  /** The proposed plan: `matchColumns`, then a new field (with `@onCreateFields`) for a column that matches none. */
  @cached
  get proposed(): SheetImportColumn[] {
    if (!this.parsed) return [];
    const saved = this.headers ? (this.args.savedMapping ?? null) : null;
    const columns = matchColumns(this.headerTexts, this.writableFields, saved, {
      headers: this.headers
    });
    return columns.map((column) => {
      const target = column.target;
      const fromSaved = column.matchedBy === 'saved';
      let next = column;
      if (target !== 'skip' && 'newField' in target && !this.canCreate) {
        next = { ...column, target: 'skip' };
      } else if (
        target === 'skip' &&
        !fromSaved &&
        column.taken === undefined &&
        this.canCreate
      ) {
        next = { ...column, target: { newField: this.draftFor(column.index) } };
      }
      if (next.valueMap === undefined) {
        const valueMap = this.prefill(next.index, this.fieldOf(next));
        if (valueMap) next = { ...next, valueMap };
      }
      return next;
    });
  }

  /** The plan now: the proposal with the user's changes. */
  @cached
  get columns(): SheetImportColumn[] {
    const proposed = this.proposed;
    const overrides = this.overrides;
    if (
      !overrides ||
      overrides.parsed !== this.parsed ||
      overrides.headers !== this.headers
    ) {
      return proposed;
    }
    return proposed.map((column) => {
      const patch = overrides.byColumn[column.index];
      return patch ? { ...column, ...patch } : column;
    });
  }

  /** Changes columns of the plan (the dry run follows, debounced). */
  edit(patches: Record<number, Partial<SheetImportColumn>>): void {
    const parsed = this.parsed;
    if (!parsed) return;
    const current =
      this.overrides &&
      this.overrides.parsed === parsed &&
      this.overrides.headers === this.headers
        ? this.overrides.byColumn
        : {};
    const byColumn = { ...current };
    for (const [index, patch] of Object.entries(patches)) {
      byColumn[Number(index)] = { ...byColumn[Number(index)], ...patch };
    }
    this.overrides = { parsed, headers: this.headers, byColumn };
  }

  get plan() {
    return { headers: this.headers, columns: this.columns };
  }

  /* -------------------------------------------------------------------- */
  /* Preview and dry run                                                   */
  /* -------------------------------------------------------------------- */

  /** The dry run of the plan now: at once for a new source, else debounced (the last result meanwhile). */
  @cached
  get dryRun(): SheetImportRun | null {
    void this.runTick;
    const parsed = this.parsed;
    if (!parsed) return null;
    const columns = this.columns;
    const fields = this.allFields;
    const state = this.runState;
    if (
      state &&
      state.parsed === parsed &&
      state.headers === this.headers &&
      state.columns === columns &&
      state.fields === fields
    ) {
      return state.run;
    }
    if (!state || state.parsed !== parsed || state.headers !== this.headers) {
      return this.storeRun().run;
    }
    this.scheduleRun(columns);
    return state.run;
  }

  /** Runs the dry run over the plan now and remembers it. */
  storeRun(): RunState {
    const state: RunState = {
      parsed: this.parsed!,
      headers: this.headers,
      columns: this.columns,
      fields: this.allFields,
      run: runImport(this.ctx, this.parsed!.matrix, this.plan, this.transforms)
    };
    this.runState = state;
    return state;
  }

  scheduleRun(columns: SheetImportColumn[]): void {
    if (this.runTimerFor === columns) return;
    if (this.runTimer) cancel(this.runTimer);
    this.runTimerFor = columns;
    if (this.runWaiter === null) this.runWaiter = waiter.beginAsync();
    this.runTimer = later(this, this.finishRun, IMPORT_DRY_RUN_DEBOUNCE);
  }

  finishRun(): void {
    this.runTimer = null;
    this.runTimerFor = null;
    this.endRunWaiter();
    if (this.gone || !this.parsed) return;
    this.storeRun();
    this.runTick++;
  }

  endRunWaiter(): void {
    if (this.runWaiter !== null) waiter.endAsync(this.runWaiter);
    this.runWaiter = null;
  }

  /** Errors per file column, from the dry run. */
  @cached
  get errorsByColumn(): Map<number, number> {
    const counts = new Map<number, number>();
    for (const error of this.dryRun?.errors ?? []) {
      counts.set(error.column, (counts.get(error.column) ?? 0) + 1);
    }
    return counts;
  }

  @cached
  get errorLines(): Set<number> {
    return new Set((this.dryRun?.errors ?? []).map((error) => error.line));
  }

  get totalLines(): number {
    return this.dryRun?.rows.length ?? 0;
  }

  get linesWithErrors(): number {
    return this.errorLines.size;
  }

  get linesReady(): number {
    return this.totalLines - this.linesWithErrors;
  }

  get importCount(): number {
    return this.skipErrors ? this.linesReady : this.totalLines;
  }

  get hasTarget(): boolean {
    return this.columns.some((column) => this.fieldOf(column) !== null);
  }

  get canImport(): boolean {
    return (
      !this.busy &&
      this.parsed !== null &&
      this.hasTarget &&
      this.importCount > 0
    );
  }

  @cached
  get preview(): SheetImportPreview | null {
    const parsed = this.parsed;
    if (!parsed) return null;
    let matrix: string[][] = parsed.matrix;
    const filter = this.filterColumn;
    if (filter !== null) {
      // only the lines where that column fails, at their own indexes (the
      // helpers leave out a line with no cells)
      const lines = new Set(
        (this.dryRun?.errors ?? [])
          .filter((error) => error.column === filter)
          .map((error) => error.line)
      );
      matrix = parsed.matrix.map((line, i) =>
        (this.headers && i === 0) || lines.has(i) ? line : []
      );
    }
    const preview = previewImport(
      this.ctx,
      matrix,
      this.plan,
      this.transforms,
      { size: this.sampleSize }
    );
    return this.asStored(preview);
  }

  /**
   * The preview's values as the target field shows them: a column read
   * with a copy (`dateOrder`, `decimalSeparator`) is formatted with the
   * field itself, so `11/19/2026` read as M/D/Y shows `19/11/2026` in a
   * D/M/Y field, as the sheet will show it.
   */
  asStored(preview: SheetImportPreview): SheetImportPreview {
    const byIndex = new Map(this.columns.map((c) => [c.index, c]));
    const stored = preview.columns.map((index, k) => {
      const column = byIndex.get(index);
      const field = column ? this.fieldOf(column) : null;
      return field && field !== preview.fields[k] ? field : null;
    });
    if (stored.every((field) => field === null)) return preview;
    const messages = this.messages;
    const cells = preview.cells.map((line) => {
      const record: Record<string, unknown> = {};
      line.forEach((cell, k) => {
        if (cell.state === 'value' || cell.state === 'newOption') {
          record[preview.fields[k]!.id] = cell.value;
        }
      });
      return line.map((cell, k): SheetImportCell => {
        const field = stored[k];
        if (!field || (cell.state !== 'value' && cell.state !== 'newOption')) {
          return cell;
        }
        const type = this.types[field.type ?? 'text'];
        if (!type) return cell;
        return {
          ...cell,
          display: type.format(cell.value, field, { record, messages })
        };
      });
    });
    return { ...preview, cells };
  }

  get previewCaption(): string {
    const filter = this.filterColumn;
    if (filter !== null) {
      return this.messages.importPreviewErrors(
        this.columnData[filter]?.name ?? ''
      );
    }
    return this.messages.importPreviewOf(
      this.preview?.lines.length ?? 0,
      this.dataLines.length
    );
  }

  /* -------------------------------------------------------------------- */
  /* The columns table                                                     */
  /* -------------------------------------------------------------------- */

  fieldLabel(field: EuiSheetField): string {
    return field.label ?? field.id;
  }

  @cached
  get columnViews(): ImportColumnView[] {
    const messages = this.messages;
    const columns = this.columns;
    const takenBy = new Map<string, number>();
    for (const column of columns) {
      const target = column.target;
      if (target !== 'skip' && 'field' in target) {
        if (!takenBy.has(target.field)) takenBy.set(target.field, column.index);
      }
    }
    const total = this.totalLines;
    return columns.map((column): ImportColumnView => {
      const index = column.index;
      const data = this.columnData[index];
      const name = data?.name ?? messages.importColumnN(index + 1);
      const target = column.target;
      const isSkip = target === 'skip';
      const newField = !isSkip && 'newField' in target ? target.newField : null;
      const field = this.fieldOf(column);
      const typeName = field ? (field.type ?? 'text') : null;

      const targetOptions: ImportColumnView['targetOptions'] = [];
      for (const candidate of this.writableFields) {
        const owner = takenBy.get(candidate.id);
        const label = this.fieldLabel(candidate);
        targetOptions.push(
          owner !== undefined && owner !== index
            ? {
                value: `f:${candidate.id}`,
                text: messages.importTakenBy(
                  label,
                  this.columnData[owner]?.name ?? ''
                ),
                disabled: true
              }
            : { value: `f:${candidate.id}`, text: label }
        );
      }
      if (this.canCreate) {
        targetOptions.push({
          value: TARGET_NEW,
          text: messages.importNewField()
        });
      }
      targetOptions.push({ value: TARGET_SKIP, text: messages.importSkip() });

      let takenNote: string | null = null;
      if (isSkip && column.taken !== undefined) {
        const owner = takenBy.get(column.taken);
        takenNote = messages.importTaken(
          owner !== undefined ? (this.columnData[owner]?.name ?? '') : ''
        );
      }

      const errors = this.errorsByColumn.get(index) ?? 0;
      let badge: ImportColumnView['badge'] = null;
      if (field && !newField && typeName) {
        const share = total ? (total - errors) / total : 1;
        const text = messages.importGuess(
          typeText(this.types, messages, typeName, {
            dateOrder: column.dateOrder ?? field['dateOrder'],
            decimalSeparator:
              column.decimalSeparator ?? field['decimalSeparator']
          }),
          percent(share)
        );
        badge = {
          text,
          color: errors ? 'warning' : 'success',
          title: text
        };
      } else if (data?.guesses[0]) {
        const guess = data.guesses[0];
        const text = messages.importGuess(
          typeText(this.types, messages, guess.type, guess.options),
          percent(guess.share)
        );
        badge = { text, color: 'hollow', title: text };
      }

      let valueMap: ImportColumnView['valueMap'] = null;
      if (field && typeName && MAP_TYPES.has(typeName)) {
        const texts = suggestValueMap(data?.texts ?? [], field).texts;
        const map = column.valueMap ?? {};
        valueMap = {
          texts,
          choices: valueChoices(messages, field),
          map,
          mapped: texts.filter((text) => map[text] !== undefined).length
        };
      }

      return {
        index,
        column,
        name,
        samples: data?.samples ?? [],
        badge,
        targetValue: targetValue(column),
        targetOptions,
        takenNote,
        isSkip,
        newField,
        newFieldText: newField
          ? messages.importNewFieldNamed(
              newField.label,
              typeText(this.types, messages, newField.type, {
                dateOrder: newField['dateOrder'],
                decimalSeparator: newField['decimalSeparator']
              })
            )
          : null,
        field,
        showTransform: !isSkip && this.transforms.length > 0,
        transformValue: column.transform ?? '',
        dateOrder:
          typeName && DATE_TYPES.has(typeName)
            ? (column.dateOrder ??
              (field?.['dateOrder'] as 'dmy' | 'mdy' | undefined) ??
              'dmy')
            : null,
        decimalSeparator:
          typeName && DECIMAL_TYPES.has(typeName)
            ? (column.decimalSeparator ??
              (field?.['decimalSeparator'] as '.' | ',' | undefined) ??
              '.')
            : null,
        valueMap,
        status: field ? { read: total - errors, total, errors } : null,
        formOpen: this.formOpen === index && newField !== null,
        valuesOpen: this.valuesOpen === index && valueMap !== null
      };
    });
  }

  /* -------------------------------------------------------------------- */
  /* Actions                                                               */
  /* -------------------------------------------------------------------- */

  onDelimiter = (event: Event): void => {
    const value = (event.target as HTMLSelectElement).value;
    this.delimiterChoice = { source: this.source, value };
    this.resetView();
  };

  onHeaders = (): void => {
    this.headersChoice = { source: this.source, value: !this.headers };
    this.resetView();
  };

  resetView(): void {
    this.filterColumn = null;
    this.formOpen = null;
    this.valuesOpen = null;
  }

  setTarget = (index: number, value: string): void => {
    const patches: Record<number, Partial<SheetImportColumn>> = {};
    let target: SheetImportColumn['target'];
    if (value === TARGET_SKIP) {
      target = 'skip';
    } else if (value === TARGET_NEW) {
      target = { newField: this.draftFor(index) };
    } else {
      const id = value.slice(2);
      target = { field: id };
      // a field takes one column (the select disables a taken field; a
      // call from elsewhere still frees it from the other column)
      for (const column of this.columns) {
        const other = column.target;
        if (
          column.index !== index &&
          other !== 'skip' &&
          'field' in other &&
          other.field === id
        ) {
          patches[column.index] = {
            target: 'skip',
            valueMap: undefined,
            taken: undefined
          };
        }
      }
    }
    const column = this.columns.find((c) => c.index === index);
    const field = column ? this.fieldOf({ ...column, target }) : null;
    patches[index] = {
      target,
      taken: undefined,
      valueMap: this.prefill(index, field)
    };
    if (this.formOpen === index) this.formOpen = null;
    if (this.valuesOpen === index) this.valuesOpen = null;
    if (this.filterColumn !== null) this.filterColumn = null;
    this.edit(patches);
  };

  setTransform = (index: number, value: string): void => {
    this.edit({ [index]: { transform: value === '' ? undefined : value } });
  };

  toggleTrim = (index: number): void => {
    const column = this.columns.find((c) => c.index === index);
    this.edit({ [index]: { trim: column?.trim === false } });
  };

  toggleEmptyIsNull = (index: number): void => {
    const column = this.columns.find((c) => c.index === index);
    this.edit({ [index]: { emptyIsNull: column?.emptyIsNull === false } });
  };

  setDateOrder = (index: number, value: 'dmy' | 'mdy'): void => {
    const column = this.columns.find((c) => c.index === index);
    const field = column ? this.fieldOf(column) : null;
    const own = (field?.['dateOrder'] as string | undefined) ?? 'dmy';
    this.edit({ [index]: { dateOrder: value === own ? undefined : value } });
  };

  setDecimalSeparator = (index: number, value: '.' | ','): void => {
    const column = this.columns.find((c) => c.index === index);
    const field = column ? this.fieldOf(column) : null;
    const own = field?.['decimalSeparator'] as string | undefined;
    this.edit({
      [index]: { decimalSeparator: value === own ? undefined : value }
    });
  };

  setValue = (index: number, text: string, choice: unknown): void => {
    const column = this.columns.find((c) => c.index === index);
    const map: Record<string, unknown> = { ...column?.valueMap };
    if (choice === undefined) delete map[text];
    else map[text] = choice;
    this.edit({
      [index]: { valueMap: Object.keys(map).length ? map : undefined }
    });
  };

  saveDraft = (index: number, draft: SheetImportFieldDraft): void => {
    const field: EuiSheetField = { ...draft, id: importFieldId(index) };
    this.edit({
      [index]: {
        target: { newField: draft },
        valueMap: this.prefill(index, field)
      }
    });
    this.formOpen = null;
  };

  toggleForm = (index: number): void => {
    this.formOpen = this.formOpen === index ? null : index;
  };

  toggleValues = (index: number): void => {
    this.valuesOpen = this.valuesOpen === index ? null : index;
  };

  showErrors = (index: number): void => {
    this.filterColumn = this.filterColumn === index ? null : index;
  };

  get isFiltered(): boolean {
    return this.filterColumn !== null;
  }

  showFirstLines = (): void => {
    this.filterColumn = null;
  };

  get skipChoice(): string {
    return this.skipErrors ? `${this.id}-skip` : `${this.id}-all`;
  }

  get skipOptions(): Array<{ id: string; label: string }> {
    return [
      { id: `${this.id}-all`, label: this.messages.importAll() },
      { id: `${this.id}-skip`, label: this.messages.importSkipErrors() }
    ];
  }

  onSkipChoice = (id: string): void => {
    this.skipErrors = id === `${this.id}-skip`;
  };

  get delimiterOptions(): Array<{ value: string; text: string }> {
    const messages = this.messages;
    return [
      { value: ',', text: messages.importDelimiterComma() },
      { value: ';', text: messages.importDelimiterSemicolon() },
      { value: '\t', text: messages.importDelimiterTab() }
    ];
  }

  get encodingText(): string | null {
    const encoding = this.parsed?.encoding;
    if (!encoding) return null;
    return encoding === 'utf-8' ? 'UTF-8' : 'Windows-1252';
  }

  /** Downloads the lines with errors as CSV (`errorsCsv`), the file's header line first. */
  downloadErrors = (): void => {
    const parsed = this.parsed;
    const errors = this.dryRun?.errors ?? [];
    if (!parsed || !errors.length) return;
    const csv = errorsCsv(parsed.matrix, errors, {
      headers: this.headers,
      delimiter: parsed.delimiter ?? ','
    });
    const base = (parsed.name ?? 'import').replace(/\.[^.]*$/, '');
    // the BOM tells Excel the file is UTF-8
    const blob = new Blob([String.fromCharCode(0xfeff) + csv], {
      type: 'text/csv;charset=utf-8'
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${base}-errors.csv`;
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  cancel = (): void => {
    this.args.onCancel?.();
  };

  /** The mapping to save: the plan's columns with field ids, without what only the screen uses. */
  mappingOf(columns: SheetImportColumn[]): SheetImportMapping | null {
    if (!this.headers) return null;
    return {
      signature: importSignature(this.headerTexts),
      columns: columns.map((column) => {
        const saved: SheetImportColumn = {
          index: column.index,
          header: column.header,
          target: column.target
        };
        const keys = [
          'transform',
          'trim',
          'emptyIsNull',
          'dateOrder',
          'decimalSeparator',
          'valueMap'
        ] as const;
        for (const key of keys) {
          if (column[key] !== undefined && column[key] !== null) {
            (saved as unknown as Record<string, unknown>)[key] = column[key];
          }
        }
        return saved;
      })
    };
  }

  /**
   * Import: the new fields first (`@onCreateFields`, once, with every
   * draft in column order; their columns then go to the created ids, so a
   * retry does not create them again), then every line read again with
   * the plan and given to `@onImport`.
   */
  import = async (): Promise<void> => {
    const parsed = this.parsed;
    if (!parsed || !this.canImport) return;
    this.busy = true;
    this.error = null;
    const token = waiter.beginAsync();
    try {
      const drafted = this.columns.filter(
        (column) => column.target !== 'skip' && 'newField' in column.target
      );
      if (drafted.length) {
        const create = this.args.onCreateFields;
        if (!create) throw new Error(this.messages.importCreateMismatch());
        const drafts = drafted.map((column) => ({
          ...(column.target as { newField: SheetImportFieldDraft }).newField
        }));
        const made = await create(drafts);
        if (this.gone) return;
        if (!Array.isArray(made) || made.length !== drafts.length) {
          throw new Error(this.messages.importCreateMismatch());
        }
        this.created = [...this.created, ...made];
        this.unreported = [...this.unreported, ...made];
        const patches: Record<number, Partial<SheetImportColumn>> = {};
        drafted.forEach((column, k) => {
          patches[column.index] = { target: { field: made[k]!.id } };
        });
        this.edit(patches);
        this.formOpen = null;
      }
      const columns = this.columns;
      const run = runImport(
        this.ctx,
        parsed.matrix,
        { headers: this.headers, columns },
        this.transforms,
        { skipLinesWithErrors: this.skipErrors }
      );
      const result: SheetImportResult<T> = {
        rows: run.rows,
        fieldIds: run.fieldIds,
        fields: run.fields as EuiSheetField<T>[],
        createdFields: [...this.unreported],
        skippedLines: run.skippedLines,
        lines: run.lines,
        values: run.values,
        mapping: this.mappingOf(columns)
      };
      await this.args.onImport(result);
      if (!this.gone) this.unreported = [];
    } catch (error) {
      if (!this.gone) this.error = errorMessage(error);
    } finally {
      if (!this.gone) this.busy = false;
      waiter.endAsync(token);
    }
  };

  <template>
    <div
      class="euiSheetImport {{this.themeClass}}"
      data-test-subj="euiSheetImport"
      aria-busy={{if this.busy "true"}}
      ...attributes
    >
      <section
        class="euiSheetImport__section"
        aria-labelledby="{{this.id}}-file"
        data-test-subj="euiSheetImportFile"
      >
        <h3 class="euiSheetImport__title" id="{{this.id}}-file">
          {{this.messages.importFile}}
        </h3>
        {{#if this.isReading}}
          <div class="euiSheetImport__inline" role="status">
            <EuiLoadingSpinner @size="m" />
            {{this.messages.importReading}}
          </div>
        {{else if this.fileError}}
          <EuiCallOut
            @size="s"
            @color="danger"
            @iconType="error"
            @title={{this.fileError}}
            data-test-subj="euiSheetImportFileError"
          />
        {{else if this.parsed}}
          <div class="euiSheetImport__fileRow">
            {{#if this.parsed.name}}
              <span
                class="euiSheetImport__fileName"
                data-test-subj="euiSheetImportFileName"
              >{{this.parsed.name}}</span>
            {{/if}}
            {{#if this.encodingText}}
              <span data-test-subj="euiSheetImportEncoding">
                <span class="euiSheetImport__subdued">
                  {{this.messages.importEncoding}}:
                </span>
                {{this.encodingText}}
              </span>
            {{/if}}
            {{#if this.parsed.delimiter}}
              <span class="euiSheetImport__inline">
                <label
                  for="{{this.id}}-delimiter"
                  class="euiSheetImport__subdued"
                >{{this.messages.importDelimiter}}</label>
                <EuiSelect
                  @compressed={{true}}
                  @options={{this.delimiterOptions}}
                  @value={{this.parsed.delimiter}}
                  @disabled={{this.busy}}
                  id="{{this.id}}-delimiter"
                  data-test-subj="euiSheetImportDelimiter"
                  {{on "change" this.onDelimiter}}
                />
              </span>
            {{/if}}
            <EuiSwitch
              @compressed={{true}}
              @label={{(this.messages.importHeaderLine)}}
              @checked={{this.headers}}
              @disabled={{this.busy}}
              @onChange={{this.onHeaders}}
              data-test-subj="euiSheetImportHeaders"
            />
            <span data-test-subj="euiSheetImportLineCount">
              {{this.messages.importLineCount this.dataLines.length}}
            </span>
          </div>
        {{/if}}
      </section>

      {{#if this.parsed}}
        <section
          class="euiSheetImport__section"
          aria-labelledby="{{this.id}}-columns"
          data-test-subj="euiSheetImportColumns"
        >
          <h3 class="euiSheetImport__title" id="{{this.id}}-columns">
            {{this.messages.importColumns}}
          </h3>
          <div class="euiSheetImport__scroll">
            <table class="euiSheetImport__table euiSheetImport__columns">
              <thead>
                <tr>
                  <th scope="col">{{this.messages.importFileColumn}}</th>
                  <th scope="col">{{this.messages.importType}}</th>
                  <th scope="col">{{this.messages.importTarget}}</th>
                  {{#if this.transforms.length}}
                    <th scope="col">{{this.messages.importTransform}}</th>
                  {{/if}}
                  <th scope="col">{{this.messages.importOptions}}</th>
                  <th scope="col">{{this.messages.importStatus}}</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.columnViews key="index" as |view|}}
                  <ImportColumnRow
                    @view={{view}}
                    @screen={{this}}
                    @transforms={{this.transforms}}
                    @messages={{this.messages}}
                  />
                {{/each}}
              </tbody>
            </table>
          </div>
        </section>

        <section
          class="euiSheetImport__section"
          aria-labelledby="{{this.id}}-preview"
          data-test-subj="euiSheetImportPreview"
        >
          <h3 class="euiSheetImport__title" id="{{this.id}}-preview">
            {{this.messages.importPreview}}
          </h3>
          {{#if this.dataLines.length}}
            {{#if this.preview}}
              <ImportPreviewTable
                @preview={{this.preview}}
                @caption={{this.previewCaption}}
                @messages={{this.messages}}
              />
            {{/if}}
            {{#if this.isFiltered}}
              <div>
                <EuiLink
                  data-test-subj="euiSheetImportShowFirst"
                  {{on "click" this.showFirstLines}}
                >{{this.messages.importShowFirstLines}}</EuiLink>
              </div>
            {{/if}}
            <div
              class="euiSheetImport__totals"
              data-test-subj="euiSheetImportTotals"
            >
              <span role="status" data-test-subj="euiSheetImportTotalsText">
                {{this.messages.importLinesReady this.linesReady}},
                <span
                  class={{if this.linesWithErrors "euiSheetImport__danger"}}
                >
                  {{this.messages.importLinesWithErrors this.linesWithErrors}}
                </span>
              </span>
              {{#if this.linesWithErrors}}
                <EuiLink
                  data-test-subj="euiSheetImportDownloadErrors"
                  {{on "click" this.downloadErrors}}
                >{{this.messages.importDownloadErrors}}</EuiLink>
              {{/if}}
            </div>
            {{#if this.linesWithErrors}}
              <EuiRadioGroup
                @compressed={{true}}
                @options={{this.skipOptions}}
                @idSelected={{this.skipChoice}}
                @onChange={{this.onSkipChoice}}
                @disabled={{this.busy}}
                @name="{{this.id}}-errors"
                data-test-subj="euiSheetImportErrorChoice"
              />
            {{/if}}
          {{else}}
            <p
              class="euiSheetImport__subdued"
              data-test-subj="euiSheetImportNoLines"
            >
              {{this.messages.importNoLines}}
            </p>
          {{/if}}
        </section>
      {{/if}}

      {{#if this.error}}
        <EuiCallOut
          @size="s"
          @color="danger"
          @iconType="error"
          @title={{this.error}}
          role="alert"
          data-test-subj="euiSheetImportError"
        />
      {{/if}}

      <div class="euiSheetImport__actions">
        {{#if @onCancel}}
          <EuiButtonEmpty
            @size="s"
            @type="button"
            @isDisabled={{this.busy}}
            data-test-subj="euiSheetImportCancel"
            {{on "click" this.cancel}}
          >{{this.messages.cancel}}</EuiButtonEmpty>
        {{/if}}
        <EuiButton
          @size="s"
          @fill={{true}}
          @type="button"
          @isLoading={{this.busy}}
          @isDisabled={{if this.canImport false true}}
          title={{if this.hasTarget undefined (this.messages.importNoTarget)}}
          data-test-subj="euiSheetImportSubmit"
          {{on "click" this.import}}
        >{{this.messages.importLines this.importCount}}</EuiButton>
      </div>
    </div>
  </template>
}

/** A share as a whole percent, never 100 unless all is read. */
function percent(share: number): number {
  return share >= 1 ? 100 : Math.floor(share * 100);
}
