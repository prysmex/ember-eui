import { attachmentFieldType } from './attachment.ts';
import { checkboxFieldType } from './checkbox.ts';
import { currencyFieldType } from './currency.ts';
import { dateFieldType } from './date.ts';
import { dateTimeFieldType } from './date-time.ts';
import { durationFieldType } from './duration.ts';
import { emailFieldType, phoneFieldType, urlFieldType } from './link.ts';
import { linkedRecordFieldType } from './linked-record.ts';
import { longTextFieldType } from './long-text.ts';
import { multiSelectFieldType } from './multi-select.ts';
import { numberFieldType } from './number.ts';
import { percentFieldType } from './percent.ts';
import { ratingFieldType } from './rating.ts';
import { singleSelectFieldType } from './single-select.ts';
import { textFieldType } from './text.ts';
import { userFieldType } from './user.ts';

import type { FieldTypeRegistry } from '../types.ts';

export {
  attachmentFieldType,
  checkboxFieldType,
  currencyFieldType,
  dateFieldType,
  dateTimeFieldType,
  durationFieldType,
  emailFieldType,
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
  userFieldType
};
export { validIsoDate } from './date.ts';
export {
  dateTimeLocalValue,
  validIsoDateTime,
  validTimeZone
} from './date-time.ts';
export { safeFileUrl } from './attachment.ts';
export { LINK_PROTOCOLS, safeLink } from './link.ts';

/**
 * The built-in core types, without components: `text`, `number`,
 * `checkbox`, `singleSelect`, `date`, `multiSelect`, `linkedRecord`,
 * `user`, `attachment`, `currency`, `percent`, `duration`, `rating`,
 * `url`, `email`, `phone`, `longText`, `dateTime`.
 */
export const builtInFieldTypes: FieldTypeRegistry = {
  text: textFieldType,
  number: numberFieldType,
  checkbox: checkboxFieldType,
  singleSelect: singleSelectFieldType,
  date: dateFieldType,
  multiSelect: multiSelectFieldType,
  linkedRecord: linkedRecordFieldType,
  user: userFieldType,
  attachment: attachmentFieldType,
  currency: currencyFieldType,
  percent: percentFieldType,
  duration: durationFieldType,
  rating: ratingFieldType,
  url: urlFieldType,
  email: emailFieldType,
  phone: phoneFieldType,
  longText: longTextFieldType,
  dateTime: dateTimeFieldType
};

/** The built-ins plus `extra`; a type of `extra` with a built-in name replaces it. */
export function createRegistry(extra?: FieldTypeRegistry): FieldTypeRegistry {
  return { ...builtInFieldTypes, ...extra };
}
