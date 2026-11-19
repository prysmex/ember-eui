/**
 * The built-in field types with their cells, editors and key rules: the
 * core types (`src/core/field-types`) registered through the same contract
 * an app uses (PACKAGE-DESIGN.md 8.2, 9.1). Spread one to change a part,
 * e.g. `{ ...dateType, editor: MyDatePickerEditor }` in `@fieldTypes`.
 */
import {
  checkboxFieldType,
  dateFieldType,
  numberFieldType,
  singleSelectFieldType,
  textFieldType
} from './core/index.ts';
import CheckboxCell from './-private/cells/checkbox-cell.gts';
import SelectCell from './-private/cells/select-cell.gts';
import DateEditor from './-private/editors/date-editor.gts';
import InputEditor from './-private/editors/input-editor.gts';
import SelectEditor from './-private/editors/select-editor.gts';

import type {
  CheckboxField,
  DateField,
  NumberField,
  SheetOption,
  SingleSelectField,
  TextField
} from './core/index.ts';
import type { EuiSheetFieldType } from './types.ts';

export const textType: EuiSheetFieldType<string, TextField> = {
  ...textFieldType,
  editor: InputEditor
};

export const numberType: EuiSheetFieldType<number | null, NumberField> = {
  ...numberFieldType,
  editor: InputEditor
};

/** No editor: Space (navKey) or a click anywhere in the cell toggles it (P7). */
export const checkboxType: EuiSheetFieldType<boolean, CheckboxField> = {
  ...checkboxFieldType,
  cell: CheckboxCell,
  onCellClick: (value) => ({ value: value !== true })
};

export const singleSelectType: EuiSheetFieldType<
  SheetOption['value'] | null,
  SingleSelectField
> = {
  ...singleSelectFieldType,
  cell: SelectCell,
  editor: SelectEditor,
  editorLayout: 'panel',
  opener: 'arrowDown',
  // any printable key but Space (which never opens an editor) filters the list
  opensOnKey: (key) => key !== ' ',
  handlesKey: (event) =>
    event.key === 'Enter' ||
    event.key === 'ArrowUp' ||
    event.key === 'ArrowDown' ||
    event.key === 'Tab'
};

/** Typing a digit opens the text input; Enter, F2 or a double-click the native date input. */
export const dateType: EuiSheetFieldType<string | null, DateField> = {
  ...dateFieldType,
  editor: DateEditor,
  opener: 'calendar',
  opensOnKey: (key) => /^\d$/.test(key)
};

/** `{ text, number, checkbox, singleSelect, date }`; `@fieldTypes` is merged over it. */
export const builtInSheetFieldTypes: Record<
  string,
  EuiSheetFieldType<any, any>
> = {
  text: textType,
  number: numberType,
  checkbox: checkboxType,
  singleSelect: singleSelectType,
  date: dateType
};

export { InputEditor as SheetInputEditor };
