/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/** Ports of the toolbar option helpers in upstream `data_grid_toolbar.tsx`. */
import type {
  EuiDataGridToolBarAdditionalControlsLeftOptions,
  EuiDataGridToolBarAdditionalControlsOptions,
  EuiDataGridToolBarVisibilityOptions
} from './types.ts';
import type { ComponentLike } from '@glint/template';

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

function isAdditionalControlsOptions(
  value: unknown
): value is EuiDataGridToolBarAdditionalControlsOptions {
  return typeof value === 'object' && value !== null && ('left' in value || 'right' in value);
}

function isLeftOptions(value: unknown): value is EuiDataGridToolBarAdditionalControlsLeftOptions {
  return typeof value === 'object' && value !== null && ('prepend' in value || 'append' in value);
}

/**
 * Port of upstream `renderAdditionalControls`: the `additionalControls`
 * component for a toolbar position. A single component (or a single `left`
 * component) goes to the left append position.
 */
export function getAdditionalControl(
  toolbarVisibility: boolean | EuiDataGridToolBarVisibilityOptions | undefined,
  position: 'left.prepend' | 'left.append' | 'right'
): ComponentLike | undefined {
  if (typeof toolbarVisibility !== 'object' || toolbarVisibility === null) return undefined;
  const { additionalControls } = toolbarVisibility;
  if (!additionalControls) return undefined;
  if (!isAdditionalControlsOptions(additionalControls)) {
    return position === 'left.append' ? additionalControls : undefined;
  }
  if (position === 'right') return additionalControls.right;
  const left = additionalControls.left;
  if (!left) return undefined;
  if (!isLeftOptions(left)) return position === 'left.append' ? left : undefined;
  return position === 'left.prepend' ? left.prepend : left.append;
}
