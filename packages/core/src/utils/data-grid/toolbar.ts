/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/** Ports of the toolbar option helpers in upstream `data_grid_toolbar.tsx`. */
import type { EuiDataGridToolBarVisibilityOptions } from './types.ts';

/** Whether a toolbar control is shown (missing options default to shown). */
export function checkOrDefaultToolBarDisplayOptions(
  arg: boolean | EuiDataGridToolBarVisibilityOptions | undefined,
  option: keyof EuiDataGridToolBarVisibilityOptions
): boolean {
  if (arg === undefined) return true;
  if (typeof arg === 'boolean') return arg;
  if (Object.prototype.hasOwnProperty.call(arg, option)) return !!arg[option];
  return true;
}

/** Nested options of selectors (e.g. `showColumnSelector.allowHide`). */
export function getNestedObjectOptions<T extends object>(
  controlOption: boolean | T | undefined,
  objectKey: keyof T
): boolean {
  // If the config is a boolean, nested options follow that boolean
  if (typeof controlOption === 'boolean') return controlOption;
  // If config is not defined, default to enabled
  if (controlOption == null) return true;
  // Otherwise, dive into the object of boolean values
  return !!(controlOption[objectKey] ?? true);
}
