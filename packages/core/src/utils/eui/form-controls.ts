/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Small pieces of the EUI 123.1.0 form control family that live inside React
 * component modules (not style modules), ported by hand. The parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) checks them against the upstream
 * sources. Everything else comes from `styles.generated.ts`.
 */
import { htmlSafe } from '@ember/template';

import type { CSSObject } from '@emotion/css/create-instance';

/**
 * `form_control_layout_custom_icon.js` module-level `styles`
 * (`euiFormControlLayoutCustomIcon`, `unclickable`, `clickable`).
 */
export const euiFormControlLayoutCustomIconStyles = {
  euiFormControlLayoutCustomIcon:
    'font-size:0;label:euiFormControlLayoutCustomIcon;',
  unclickable: '\n    pointer-events: none;\n  ',
  clickable:
    'pointer-events:all;&:disabled{cursor:not-allowed;color:currentColor;};label:clickable;'
} as const;

/** Icon kinds counted by upstream `getIconAffordanceStyles` (`_num_icons.js`). */
export interface EuiFormControlIconCount {
  icon?: unknown;
  iconSide?: 'left' | 'right';
  clear?: unknown;
  isLoading?: unknown;
  isInvalid?: unknown;
  isDropdown?: unknown;
}

/**
 * Upstream `getIconAffordanceStyles`: the CSS variables the control's padding
 * reads (`--euiFormControlLeftIconsCount` / `--euiFormControlRightIconsCount`),
 * only for non-zero counts, as an inline style for the children wrapper.
 */
export function iconAffordanceStyle({
  icon,
  iconSide,
  clear,
  isLoading,
  isInvalid,
  isDropdown
}: EuiFormControlIconCount) {
  let left = 0;
  let right = 0;
  if (icon) {
    if (iconSide === 'right') right++;
    else left++;
  }
  if (clear) right++;
  if (isLoading) right++;
  if (isInvalid) right++;
  if (isDropdown) right++;
  const declarations = [
    left ? `--euiFormControlLeftIconsCount: ${left}` : '',
    right ? `--euiFormControlRightIconsCount: ${right}` : ''
  ].filter(Boolean);
  return declarations.length ? htmlSafe(declarations.join('; ')) : undefined;
}

/**
 * Ember has no React global reset: the parts native form controls rely on
 * (`*` box sizing, `input { margin: 0; padding: 0 }`). Upstream rules that
 * follow in the same class override them.
 */
export const formControlReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0
};

/** Box sizing for the layout's own wrappers (React global `*` reset). */
export const layoutBoxReset: CSSObject = {
  boxSizing: 'border-box',
  '& :where(*, *::before, *::after)': { boxSizing: 'border-box' }
};

/** React global `button` reset, for the icon and clear buttons. */
export const buttonReset: CSSObject = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  background: 'none',
  border: 'none',
  color: 'inherit',
  font: 'inherit',
  cursor: 'pointer'
};
