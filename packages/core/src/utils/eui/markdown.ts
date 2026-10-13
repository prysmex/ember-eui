/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Small pieces of the EUI 123.1.0 markdown family that live inside React
 * renderer modules (not style modules), ported by hand. The parity suite
 * (`scripts/eui-upstream-parity.test.mjs`) checks them against the upstream
 * sources. Everything else comes from `styles.generated.ts`.
 */
import { logicalCSS } from './styles.generated.ts';

/**
 * `plugins/markdown_tooltip/renderer.js`: the css given to the tooltip's
 * `EuiIcon` ("offset the tooltip icon, which isn't perfectly centered").
 */
export const tooltipMarkdownIconStyles =
  'transform:translateY(-1px);label:tooltipMarkdownRenderer;';

/**
 * `plugins/markdown_checkbox/renderer.js` module-level
 * `markdownCheckboxStyles`, given to each task list `EuiCheckbox` as `css`.
 *
 * Only the `:has(+ :not(.euiCheckbox))` rule matches upstream 123.1.0's own
 * checkbox markup (its input sits inside `.euiCheckbox__square`, so the two
 * sibling selectors never match). EuiMarkdownFormat applies the equivalent
 * of that rule to the task list wrappers; see `markdownFormatEmberCss`.
 */
export const markdownCheckboxStyles = [
  '&&{.euiCheckbox__input~.euiCheckbox__label{font-size:inherit;line-height:inherit;',
  logicalCSS('padding-left', '1.5em'),
  ';}&:has(+ :not(.euiCheckbox)){',
  logicalCSS('margin-bottom', '1em'),
  ';}.euiCheckbox__input+.euiCheckbox__square{',
  logicalCSS('top', '50%'),
  ' transform:translateY(-50%);}};label:markdownCheckboxStyles;'
].join('');
