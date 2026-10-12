/**
 * Combo box helpers. The group label style port it needs is shared with
 * EuiSelectableList (`utils/eui/selectable.ts`).
 */
import type { CSSObject } from '@emotion/css/create-instance';

/**
 * Ember has no React global reset: box sizing for the combo box's own
 * elements (upstream `*` reset) and the list's `button`-free rows.
 */
export const comboBoxBoxReset: CSSObject = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
};

/** The text of an option: strings as they are, else `label` (or `@searchField`). */
export function comboBoxOptionLabel(option: unknown, searchField?: string): string {
  if (typeof option === 'string') return option;
  if (typeof option === 'number') return String(option);
  if (option && typeof option === 'object') {
    const record = option as Record<string, unknown>;
    const value = record[searchField ?? 'label'] ?? record['label'];

    if (typeof value === 'string' || typeof value === 'number') {
      return String(value);
    }
  }

  return '';
}
