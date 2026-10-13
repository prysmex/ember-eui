/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

// Importing seemingly unused types from `unified` because the definitions
// are exported for two versions of TypeScript (3.4, 4.0) and implicit
// imports during eui.d.ts generation default to the incorrect version (3.4).
// Explicit imports here resolve the version mismatch.
import breaks from 'remark-breaks';
import emoji from 'remark-emoji';
import markdown from 'remark-parse-no-trim';

import {
  DEFAULT_OPTIONS as LINK_VALIDATOR_DEFAULTS,
  euiMarkdownLinkValidator
} from '../markdown-link-validator.ts';
import intrawordUnderscore from '../../remark/remark-intraword-underscore.ts';
import highlight from '../../remark/remark-prismjs.ts';
import * as MarkdownCheckbox from '../markdown-checkbox/index.ts';
import * as MarkdownTooltip from '../markdown-tooltip/index.ts';

import type { EuiMarkdownLinkValidatorOptions } from '../markdown-link-validator.ts';
import type { DefaultPluginsConfig, ExcludableDefaultPlugins } from './plugins.ts';
import type { PluggableList } from 'unified';

export type DefaultEuiMarkdownParsingPlugins = PluggableList;

export type DefaultParsingPluginsConfig = {
  /**
   * Allows enabling emoji rendering for emoticons such as :) and :(
   * @default { emoticon: false }
   */
  emoji?: { emoticon?: boolean };
  /**
   * Allows configuring the `allowRelative`, `allowProtocols`, and
   * `allowDocumentRelative` of {@link EuiMarkdownLinkValidatorOptions}
   */
  linkValidator?: EuiMarkdownLinkValidatorOptions;
};

const DEFAULT_PARSING_PLUGINS: Record<
  ExcludableDefaultPlugins,
  DefaultEuiMarkdownParsingPlugins[0]
> = {
  // remark-emoji's types follow whichever `unified` pnpm hoists (like
  // remark-breaks below), not the processor types used here
  emoji: [emoji as any, { emoticon: false }],
  lineBreaks: [breaks as any, {}],
  linkValidator: [euiMarkdownLinkValidator, LINK_VALIDATOR_DEFAULTS],
  checkbox: [MarkdownCheckbox.parser, {}],
  tooltip: [MarkdownTooltip.parser, {}]
};

export const getDefaultEuiMarkdownParsingPlugins = ({
  exclude,
  ...parsingConfig
}: DefaultPluginsConfig &
  DefaultParsingPluginsConfig = {}): DefaultEuiMarkdownParsingPlugins => {
  const parsingPlugins: PluggableList = [
    [markdown, {}],
    [highlight, {}],
    [intrawordUnderscore, {}]
  ];

  Object.entries(DEFAULT_PARSING_PLUGINS).forEach(([pluginName, plugin]) => {
    // Check for plugin exclusions
    if (!exclude?.includes(pluginName as ExcludableDefaultPlugins)) {
      // Check for plugin configuration overrides
      if (pluginName in parsingConfig) {
        parsingPlugins.push([
          (plugin as any[])[0],
          parsingConfig[pluginName as keyof DefaultParsingPluginsConfig]
        ]);
      } else {
        parsingPlugins.push(plugin);
      }
    }
  });

  return parsingPlugins;
};

export const defaultParsingPlugins = getDefaultEuiMarkdownParsingPlugins();
