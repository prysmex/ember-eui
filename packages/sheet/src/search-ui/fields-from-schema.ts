/**
 * Default sheet fields from a driver's schema (V02-DESIGN.md 7.3), for an
 * owner that passes no `@fields`. They have no widths, validation or
 * read-only rules: an app with real requirements passes its own fields.
 */
import type { EuiSheetField, SheetOption } from '../core/index.ts';
import type { SheetSearchDriver } from './search-records.ts';

function optionsOf(
  options: NonNullable<
    NonNullable<SheetSearchDriver['schema']>[string]['options']
  >
): SheetOption[] {
  const result: SheetOption[] = [];
  for (const { value, label } of options) {
    // a sheet option's value is a string or a number
    if (typeof value === 'string' || typeof value === 'number') {
      result.push({ value, label });
    }
  }
  return result;
}

/**
 * One field per schema entry, in the schema's order, with the entry's path
 * as the field id and its label (default: the path):
 *
 * - `keyword` with `options`: `singleSelect` (options whose value is not a
 *   string or a number are left out);
 * - `keyword`, `text` and any other type: `text`;
 * - `number`: `number`; `date`: `date`; `boolean`: `checkbox`.
 *
 * Left out: `nested` fields and `geo` fields, and dotted paths
 * (`custom.due`), because a sheet field reads `record[field.id]` (one key).
 */
export function fieldsFromSchema(
  schema: SheetSearchDriver['schema']
): EuiSheetField[] {
  const fields: EuiSheetField[] = [];
  for (const [key, definition] of Object.entries(schema ?? {})) {
    const id = definition.path || key;
    if (
      definition.nested ||
      definition.type === 'nested' ||
      definition.type === 'geo' ||
      id.includes('.')
    ) {
      continue;
    }
    const field: EuiSheetField = { id, label: definition.label ?? id };
    switch (definition.type) {
      case 'number':
        field.type = 'number';
        break;
      case 'date':
        field.type = 'date';
        break;
      case 'boolean':
        field.type = 'checkbox';
        break;
      default: {
        const options =
          definition.type === 'keyword' && definition.options
            ? optionsOf(definition.options)
            : [];
        if (options.length) {
          field.type = 'singleSelect';
          field['options'] = options;
        } else {
          field.type = 'text';
        }
      }
    }
    fields.push(field);
  }
  return fields;
}
