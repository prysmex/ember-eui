/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { getDefaultEuiMarkdownUiPlugins } from './ui-plugins';
import type { DefaultEuiMarkdownUiPlugins } from './ui-plugins';
import { getDefaultEuiMarkdownParsingPlugins } from './parsing-plugins';
import type { DefaultEuiMarkdownParsingPlugins } from './parsing-plugins';
import {
  getDefaultEuiMarkdownProcessingPlugins
} from './processing-plugins';
import type { DefaultEuiMarkdownProcessingPlugins } from './processing-plugins';

export const getDefaultEuiMarkdownPlugins = (
  config: undefined | { exclude?: 'tooltip'[] }
): {
  parsingPlugins: DefaultEuiMarkdownParsingPlugins;
  processingPlugins: DefaultEuiMarkdownProcessingPlugins;
  uiPlugins: DefaultEuiMarkdownUiPlugins;
} => ({
  parsingPlugins: getDefaultEuiMarkdownParsingPlugins(config),
  processingPlugins: getDefaultEuiMarkdownProcessingPlugins(config),
  uiPlugins: getDefaultEuiMarkdownUiPlugins(config)
});
