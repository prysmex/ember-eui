/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { getDefaultEuiMarkdownParsingPlugins } from './parsing-plugins.ts';
import {
  getDefaultEuiMarkdownProcessingPlugins
} from './processing-plugins.ts';
import { getDefaultEuiMarkdownUiPlugins } from './ui-plugins.ts';

import type { DefaultEuiMarkdownParsingPlugins, DefaultParsingPluginsConfig } from './parsing-plugins.ts';
import type { DefaultEuiMarkdownProcessingPlugins } from './processing-plugins.ts';
import type { DefaultEuiMarkdownUiPlugins } from './ui-plugins.ts';

/**
 * The default plugins that can be unregistered with `exclude`. Excluding a
 * plugin leaves its syntax unparsed and, for `tooltip`, removes its toolbar
 * button and help text.
 */
export type ExcludableDefaultPlugins =
  | 'emoji'
  | 'lineBreaks'
  | 'linkValidator'
  | 'checkbox'
  | 'tooltip';

export type DefaultPluginsConfig =
  | undefined
  | { exclude?: ExcludableDefaultPlugins[] };

export const getDefaultEuiMarkdownPlugins = (
  config: DefaultPluginsConfig & {
    /** Overrides the configuration of the default parsing plugins. */
    parsingConfig?: DefaultParsingPluginsConfig;
    /** No customizations are supported yet (as upstream). */
    uiConfig?: {};
  } = {}
): {
  parsingPlugins: DefaultEuiMarkdownParsingPlugins;
  processingPlugins: DefaultEuiMarkdownProcessingPlugins;
  uiPlugins: DefaultEuiMarkdownUiPlugins;
} => {
  const { exclude, parsingConfig, uiConfig } = config ?? {};

  return {
    parsingPlugins: getDefaultEuiMarkdownParsingPlugins({
      exclude,
      ...parsingConfig
    }),
    processingPlugins: getDefaultEuiMarkdownProcessingPlugins({ exclude }),
    uiPlugins: getDefaultEuiMarkdownUiPlugins({ exclude, ...uiConfig })
  };
};
