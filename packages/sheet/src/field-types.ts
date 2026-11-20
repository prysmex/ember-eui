/**
 * The built-in field types with their cells, editors and key rules: the
 * core types (`src/core/field-types`) registered through the same contract
 * an app uses (PACKAGE-DESIGN.md 8.2, 9.1). Spread one to change a part,
 * e.g. `{ ...dateType, editor: MyDatePickerEditor }` in `@fieldTypes`.
 */
import {
  attachmentFieldType,
  buttonFieldType,
  checkboxFieldType,
  currencyFieldType,
  dateFieldType,
  dateTimeFieldType,
  durationFieldType,
  emailFieldType,
  fieldOptions,
  linkedRecordFieldType,
  longTextFieldType,
  multiSelectFieldType,
  numberFieldType,
  percentFieldType,
  phoneFieldType,
  ratingFieldType,
  singleSelectFieldType,
  textFieldType,
  urlFieldType,
  userFieldType,
  valueOf
} from './core/index.ts';
import AttachmentCell from './-private/cells/attachment-cell.gts';
import AvatarCell from './-private/cells/avatar-cell.gts';
import ButtonCell from './-private/cells/button-cell.gts';
import CheckboxCell from './-private/cells/checkbox-cell.gts';
import ChipsCell from './-private/cells/chips-cell.gts';
import LinkCell from './-private/cells/link-cell.gts';
import LongTextCell from './-private/cells/long-text-cell.gts';
import RatingCell from './-private/cells/rating-cell.gts';
import SelectCell from './-private/cells/select-cell.gts';
import AttachmentEditor from './-private/editors/attachment-editor.gts';
import DateEditor from './-private/editors/date-editor.gts';
import DateTimeEditor from './-private/editors/date-time-editor.gts';
import InputEditor from './-private/editors/input-editor.gts';
import MultiSelectEditor from './-private/editors/multi-select-editor.gts';
import RecordPickerEditor from './-private/editors/record-picker-editor.gts';
import SelectEditor from './-private/editors/select-editor.gts';
import TextareaEditor, {
  isLineBreakKey
} from './-private/editors/textarea-editor.gts';
import SelectOptions from './-private/field-options/select-options.gts';
import {
  ButtonOptions,
  CurrencyOptions,
  DateOptions,
  DateTimeOptions,
  DurationOptions,
  PercentOptions,
  RatingOptions
} from './-private/field-options/simple-options.gts';

import type {
  AttachmentField,
  ButtonField,
  CheckboxField,
  CurrencyField,
  DateField,
  DateTimeField,
  DurationField,
  EuiSheetField,
  LinkedRecordField,
  LinkField,
  LongTextField,
  MultiSelectField,
  NumberField,
  PercentField,
  RatingField,
  SheetAttachment,
  SheetLinkedRecord,
  SheetOption,
  SheetUser,
  SingleSelectField,
  TextField,
  UserField
} from './core/index.ts';
import type { EuiSheetFieldType, SheetRowColor } from './types.ts';

export const textType: EuiSheetFieldType<string, TextField> = {
  ...textFieldType,
  editor: InputEditor
};

export const numberType: EuiSheetFieldType<number | null, NumberField> = {
  ...numberFieldType,
  editor: InputEditor,
  schema: 'numeric'
};

/** No editor: Space (navKey) or a click anywhere in the cell toggles it (P7). */
export const checkboxType: EuiSheetFieldType<boolean, CheckboxField> = {
  ...checkboxFieldType,
  cell: CheckboxCell,
  schema: 'boolean',
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
  handlesKey: (event) => listKeys(event),
  fieldOptions: SelectOptions
};

/** Typing a digit opens the text input; Enter, F2 or a double-click the native date input. */
export const dateType: EuiSheetFieldType<string | null, DateField> = {
  ...dateFieldType,
  editor: DateEditor,
  schema: 'datetime',
  opener: 'calendar',
  opensOnKey: (key) => /^\d$/.test(key),
  fieldOptions: DateOptions
};

/**
 * A date with a time (V03 10.3): typing a digit opens the text input;
 * Enter, F2, a double-click or the opener the native `datetime-local`
 * picker, in the field's zone. Stored as a UTC ISO string.
 */
export const dateTimeType: EuiSheetFieldType<string | null, DateTimeField> = {
  ...dateTimeFieldType,
  editor: DateTimeEditor,
  schema: 'datetime',
  opener: 'calendar',
  opensOnKey: (key) => /^\d$/.test(key),
  fieldOptions: DateTimeOptions
};

/**
 * A button (V03 10.3.1): no value; a click on it, or Enter or Space on the
 * selected cell, calls `@onButtonPress` (or opens `field.url`).
 */
export const buttonType: EuiSheetFieldType<null, ButtonField> = {
  ...buttonFieldType,
  cell: ButtonCell,
  onCellClick: () => ({ press: true }),
  opensOnKey: () => false,
  fieldOptions: ButtonOptions
};

/** The keys a list picker (select, multi-select, records) handles itself while open. */
const listKeys = (event: KeyboardEvent): boolean =>
  event.key === 'Enter' ||
  event.key === 'ArrowUp' ||
  event.key === 'ArrowDown' ||
  event.key === 'Tab';

/** Badges in a panel picker: Enter toggles, Tab or focus leaving saves the chosen options. */
export const multiSelectType: EuiSheetFieldType<
  Array<SheetOption['value']>,
  MultiSelectField
> = {
  ...multiSelectFieldType,
  cell: ChipsCell,
  editor: MultiSelectEditor,
  editorLayout: 'panel',
  opener: 'arrowDown',
  opensOnKey: (key) => key !== ' ',
  handlesKey: listKeys,
  fieldOptions: SelectOptions
};

/** Chips; the picker searches `field.search`. Typed or pasted text goes to `@onResolve`. */
export const linkedRecordType: EuiSheetFieldType<
  SheetLinkedRecord[],
  LinkedRecordField
> = {
  ...linkedRecordFieldType,
  cell: ChipsCell,
  editor: RecordPickerEditor,
  editorLayout: 'panel',
  opener: 'arrowDown',
  opensOnKey: (key) => key !== ' ',
  handlesKey: listKeys
};

/** An avatar and the name; the picker lists `field.options` or searches `field.search`. */
export const userType: EuiSheetFieldType<
  SheetUser | SheetUser[] | null,
  UserField
> = {
  ...userFieldType,
  cell: AvatarCell,
  editor: RecordPickerEditor,
  editorLayout: 'panel',
  opener: 'arrowDown',
  opensOnKey: (key) => key !== ' ',
  handlesKey: listKeys
};

/** Thumbnails; the panel lists, opens and removes files and uploads new ones (`field.upload`). Typing does not open it. */
export const attachmentType: EuiSheetFieldType<
  SheetAttachment[],
  AttachmentField
> = {
  ...attachmentFieldType,
  cell: AttachmentCell,
  editor: AttachmentEditor,
  editorLayout: 'panel',
  opener: 'paperClip',
  opensOnKey: () => false,
  handlesKey: (event) =>
    event.key === 'Tab' || event.key === 'Enter' || event.key === ' '
};

export const currencyType: EuiSheetFieldType<number | null, CurrencyField> = {
  ...currencyFieldType,
  editor: InputEditor,
  schema: 'currency',
  fieldOptions: CurrencyOptions
};

export const percentType: EuiSheetFieldType<number | null, PercentField> = {
  ...percentFieldType,
  editor: InputEditor,
  schema: 'numeric',
  fieldOptions: PercentOptions
};

export const durationType: EuiSheetFieldType<number | null, DurationField> = {
  ...durationFieldType,
  editor: InputEditor,
  schema: 'numeric',
  fieldOptions: DurationOptions
};

/** Stars, no editor: a click on a star or a digit key sets it. */
export const ratingType: EuiSheetFieldType<number | null, RatingField> = {
  ...ratingFieldType,
  cell: RatingCell,
  schema: 'numeric',
  fieldOptions: RatingOptions
};

/** Link-styled text; a click on it opens the link in a new tab. */
export const urlType: EuiSheetFieldType<string, LinkField> = {
  ...urlFieldType,
  cell: LinkCell,
  editor: InputEditor
};

export const emailType: EuiSheetFieldType<string, LinkField> = {
  ...emailFieldType,
  cell: LinkCell,
  editor: InputEditor
};

export const phoneType: EuiSheetFieldType<string, LinkField> = {
  ...phoneFieldType,
  cell: LinkCell,
  editor: InputEditor
};

/** A textarea that grows from the cell; Shift+Enter or Alt+Enter adds a line, Enter saves. */
export const longTextType: EuiSheetFieldType<string, LongTextField> = {
  ...longTextFieldType,
  cell: LongTextCell,
  editor: TextareaEditor,
  editorLayout: 'expand',
  handlesKey: isLineBreakKey
};

/**
 * Every built-in type by name: `text`, `number`, `checkbox`,
 * `singleSelect`, `date`, `multiSelect`, `linkedRecord`, `user`,
 * `attachment`, `currency`, `percent`, `duration`, `rating`, `url`,
 * `email`, `phone`, `longText`, `dateTime`, `button`. `@fieldTypes`
 * is merged over it.
 */
export const builtInSheetFieldTypes: Record<
  string,
  EuiSheetFieldType<any, any>
> = {
  text: textType,
  number: numberType,
  checkbox: checkboxType,
  singleSelect: singleSelectType,
  date: dateType,
  multiSelect: multiSelectType,
  linkedRecord: linkedRecordType,
  user: userType,
  attachment: attachmentType,
  currency: currencyType,
  percent: percentType,
  duration: durationType,
  rating: ratingType,
  url: urlType,
  email: emailType,
  phone: phoneType,
  longText: longTextType,
  dateTime: dateTimeType,
  button: buttonType
};

export { InputEditor as SheetInputEditor };

/**
 * `@rowColor` by a select field's option (V03 10.2): the `color` of the
 * record's option of `field` (a `singleSelect`; for a `multiSelect` its
 * first value's), the same colour its badge has. EuiBadge's `'default'`
 * and `'hollow'` are `'neutral'`. `undefined` for no value, or an option
 * without a colour.
 */
export function colorByOption<T>(
  field: EuiSheetField<T>
): (record: T) => SheetRowColor | undefined {
  return (record) => {
    const raw = valueOf(record, field.id);
    const value = Array.isArray(raw) ? (raw[0] as unknown) : raw;
    if (value === null || value === undefined || value === '') return undefined;
    const option = fieldOptions(field, record).find(
      (entry) => entry.value === value
    );
    const color = option?.color;
    if (!color) return undefined;
    return color === 'default' || color === 'hollow' ? 'neutral' : color;
  };
}
