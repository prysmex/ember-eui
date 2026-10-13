import { getOwner } from '@ember/owner';

import type EuiConfigService from '../services/eui-config';

/** Pagination settings shared by every table and grid (upstream `EuiTablePagination` component defaults). */
export interface EuiTablePaginationDefaults {
  /** Rows per page. Upstream default `10`. */
  itemsPerPage: number;
  /** Choices of rows per page. Upstream default `[10, 25, 50]`. */
  itemsPerPageOptions: number[];
  /** Shows the "Rows per page" menu. Upstream default `true`. */
  showPerPageOptions: boolean;
}

/** Upstream `euiTablePaginationDefaults`. */
export const EUI_TABLE_PAGINATION_DEFAULTS: Readonly<EuiTablePaginationDefaults> = Object.freeze({
  itemsPerPage: 10,
  itemsPerPageOptions: [10, 25, 50],
  showPerPageOptions: true
});

/**
 * Upstream `useEuiTablePaginationDefaults`: the defaults merged with the
 * app's `componentDefaults.EuiTablePagination` from the `euiConfig`
 * service (Ember's `EuiProvider componentDefaults`). Reactive: reads the
 * service's tracked config.
 */
export function euiTablePaginationDefaults(context: object): Readonly<EuiTablePaginationDefaults> {
  const owner = getOwner(context);
  const config = owner?.lookup('service:eui-config') as EuiConfigService | undefined;
  const consumer = config?.getConfig('componentDefaults')?.EuiTablePagination;
  if (!consumer) return EUI_TABLE_PAGINATION_DEFAULTS;
  const merged = { ...EUI_TABLE_PAGINATION_DEFAULTS };
  for (const key of ['itemsPerPage', 'itemsPerPageOptions', 'showPerPageOptions'] as const) {
    // like a React spread, an explicit `undefined` falls back to nothing: skip it
    if (consumer[key] !== undefined) (merged as Record<string, unknown>)[key] = consumer[key];
  }
  return merged;
}
