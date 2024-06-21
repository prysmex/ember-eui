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
import markdown from 'remark-parse';

import highlight from '../../remark/remark-prismjs.ts';
import * as MarkdownCheckbox from '../markdown-checkbox/index.ts';
import * as MarkdownTooltip from '../markdown-tooltip/index.ts';

import type { PluggableList } from 'unified';

export type DefaultEuiMarkdownParsingPlugins = PluggableList;

export const getDefaultEuiMarkdownParsingPlugins = ({
  exclude
}: { exclude?: 'tooltip'[] } = {}): DefaultEuiMarkdownParsingPlugins => {
  const excludeSet = new Set(exclude);
  const parsingPlugins: PluggableList = [
    [markdown, {}],
    [highlight, {}],
    [emoji, { emoticon: false }],
    //@ts-ignore
    [breaks, {}],
    // [markdownLinkValidator, {}],
    [MarkdownCheckbox.parser, {}]
  ];

  if (!excludeSet.has('tooltip'))
    parsingPlugins.push([MarkdownTooltip.parser, {}]);

  return parsingPlugins;
};

export const defaultParsingPlugins = getDefaultEuiMarkdownParsingPlugins();
