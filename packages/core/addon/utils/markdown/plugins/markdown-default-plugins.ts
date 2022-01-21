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
import {
  PluggableList,
  // @ts-ignore See above comment
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  Attacher,
  // @ts-ignore See above comment
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  Pluggable,
  // @ts-ignore See above comment
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  Settings
} from 'unified';
import remark2Rehype from 'remark-rehype';
// import * as MarkdownTooltip from './markdown_tooltip';
// import * as MarkdownCheckbox from './markdown_checkbox';
// import { markdownLinkValidator } from './markdown_link_validator';
// import { EuiLink } from '../../link';
// import { EuiCodeBlock, EuiCode } from '../../code';
import markdown from 'remark-parse';
import rehypeStringify from 'rehype-stringify';
import emoji from 'remark-emoji';
import all from 'mdast-util-to-hast/lib/all';
import { Options as Remark2RehypeOptions, Handler } from 'mdast-util-to-hast';
import MarkdownCheckbox from '../plugins/markdown-checkbox';
import MarkdownAddComponents from '../plugins/markdown-add-components';
import breaks from 'remark-breaks';
import highlight from 'remark-highlight.js';
import MarkdownTooltip from '../plugins/markdown-tooltip';

export type DefaultEuiMarkdownParsingPlugins = PluggableList;

export const getDefaultEuiMarkdownParsingPlugins =
  (): DefaultEuiMarkdownParsingPlugins => [
    [markdown, {}],
    [highlight, {}],
    [emoji, { emoticon: false }],
    //@ts-ignore
    [breaks, {}],
    [MarkdownTooltip.parser, {}],
    [MarkdownCheckbox.parser, {}]
    // [MarkdownCheckbox.parser, {}],
    // [markdownLinkValidator, {}]
  ];

const unknownHandler: Handler = (h, node) => {
  return h(node, node.type, node, all(h, node));
};

export const defaultParsingPlugins = getDefaultEuiMarkdownParsingPlugins();

class Compiler {
  constructor(tree) {
    this.tree = tree;
  }

  compile() {
    return this.tree;
  }
}

function compiler() {
  this.Compiler = Compiler;
}

export const getDefaultEuiMarkdownProcessingPlugins = (): [
  [typeof remark2Rehype, Record<string, unknown>],
  // [typeof rehypeSanitize, Record<string, unknown>], // first is well known
  [typeof rehypeStringify, Record<string, unknown>], // first is well known
  ...PluggableList // any additional are generic
] => [
  [remark2Rehype, { allowDangerousHtml: true, unknownHandler }],
  [MarkdownAddComponents, {}],
  [compiler]
];

export const defaultProcessingPlugins =
  getDefaultEuiMarkdownProcessingPlugins();
