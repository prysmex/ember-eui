/**
 * The import screen's small pure parts (v0.4 10): type labels, the new
 * field's draft from a guess, the target select's values, the value map's
 * choices. The reading itself is `src/core/import.ts`.
 */
import type {
  EuiSheetField,
  SheetColumnGuess,
  SheetImportColumn,
  SheetImportFieldDraft,
  SheetMessages,
  SheetOption
} from '../../core/index.ts';
import type { EuiSheetFieldType, SheetFieldEditorType } from '../../types.ts';

export type ImportTypes = Record<string, EuiSheetFieldType<any, any>>;

/** A type's name as the field editor shows it: its `label`, else `messages.fieldType_<name>`, else the name. */
export function typeLabel(
  types: ImportTypes,
  messages: SheetMessages,
  name: string
): string {
  const lookup = messages as unknown as Record<
    string,
    (() => string) | undefined
  >;
  return types[name]?.label ?? lookup[`fieldType_${name}`]?.() ?? name;
}

/** The types the new-field form offers, in order (as the sheet's field editor builds them). */
export function editorTypes(
  types: ImportTypes,
  messages: SheetMessages,
  names: readonly string[]
): SheetFieldEditorType[] {
  const list: SheetFieldEditorType[] = [];
  for (const name of names) {
    const type = types[name];
    if (!type) continue;
    const entry: SheetFieldEditorType = {
      name,
      label: typeLabel(types, messages, name)
    };
    if (type.fieldOptions) entry.fieldOptions = type.fieldOptions;
    list.push(entry);
  }
  return list;
}

/** A type's name, with the date order or a decimal comma a guess or a column reads with. */
export function typeText(
  types: ImportTypes,
  messages: SheetMessages,
  name: string,
  options: { dateOrder?: unknown; decimalSeparator?: unknown } = {}
): string {
  let text = typeLabel(types, messages, name);
  if (DATE_TYPES.has(name)) {
    text += options.dateOrder === 'mdy' ? ', M/D/Y' : ', D/M/Y';
  }
  if (DECIMAL_TYPES.has(name) && options.decimalSeparator === ',') {
    text += `, ${messages.importDecimalComma()}`;
  }
  return text;
}

export const DATE_TYPES = new Set(['date', 'dateTime']);
export const DECIMAL_TYPES = new Set(['number', 'currency', 'percent']);
export const MAP_TYPES = new Set(['checkbox', 'singleSelect', 'multiSelect']);

/**
 * A new field's draft from a column's guess: the header as its label, the
 * guessed type and options. A currency gets the field editor's default
 * code (`USD`; the guess cannot know it), and a select at least `[]`.
 */
export function draftFromGuess(
  label: string,
  guess: SheetColumnGuess | undefined
): SheetImportFieldDraft {
  const type = guess?.type ?? 'text';
  const draft: SheetImportFieldDraft = { label, type, ...guess?.options };
  if (type === 'currency' && !draft['currency']) draft['currency'] = 'USD';
  if (
    (type === 'singleSelect' || type === 'multiSelect') &&
    !Array.isArray(draft['options'])
  ) {
    draft['options'] = [];
  }
  return draft;
}

/** A field the screen can write: not read-only for every record, and not a button. */
export function isWritable(field: EuiSheetField): boolean {
  return field.readOnly !== true && field.type !== 'button';
}

/** The target select's values: `f:<id>`, `new`, `skip`. */
export const TARGET_NEW = 'new';
export const TARGET_SKIP = 'skip';

export function targetValue(column: SheetImportColumn): string {
  const target = column.target;
  if (target === 'skip') return TARGET_SKIP;
  if ('newField' in target) return TARGET_NEW;
  return `f:${target.field}`;
}

/** The value map's select values: `''` as in the file, `null`, `true`/`false`, `o:<option index>`. */
export interface ValueChoice {
  value: string;
  text: string;
  /** What the column's `valueMap` gets; `undefined`: no entry. */
  mapped: unknown;
}

export function valueChoices(
  messages: SheetMessages,
  field: EuiSheetField
): ValueChoice[] {
  const type = field.type ?? 'text';
  const choices: ValueChoice[] = [
    { value: '', text: messages.importValueAsIs(), mapped: undefined }
  ];
  if (type === 'checkbox') {
    choices.push(
      { value: 'true', text: messages.importValueChecked(), mapped: true },
      { value: 'false', text: messages.importValueUnchecked(), mapped: false }
    );
    return choices;
  }
  const options = Array.isArray(field['options'])
    ? (field['options'] as SheetOption[])
    : [];
  options.forEach((option, k) => {
    choices.push({
      value: `o:${k}`,
      text: option.label,
      mapped: type === 'multiSelect' ? [option.value] : option.value
    });
  });
  choices.push({
    value: 'null',
    text: messages.importValueNone(),
    mapped: null
  });
  return choices;
}

/** The choice a map entry is (`''` when it is none of them). */
export function choiceOf(
  choices: readonly ValueChoice[],
  mapped: unknown
): string {
  if (mapped === undefined) return '';
  const plain = Array.isArray(mapped) ? (mapped as unknown[])[0] : mapped;
  for (const choice of choices) {
    if (choice.mapped === undefined) continue;
    const value = Array.isArray(choice.mapped)
      ? (choice.mapped as unknown[])[0]
      : choice.mapped;
    if (value === plain) return choice.value;
  }
  return '';
}

/** The message of a rejection: `error.message`, else the value as text. */
export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return typeof error === 'string' ? error : String(error);
}
