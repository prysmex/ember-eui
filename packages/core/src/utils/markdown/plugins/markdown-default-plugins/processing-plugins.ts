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
import type { PluggableList } from 'unified';
import remark2Rehype from 'remark-rehype';

import { toHast } from 'mdast-util-to-hast';
import type {
  Options as Remark2RehypeOptions,
  Handler
} from 'mdast-util-to-hast';
import * as MarkdownAddComponents from '../markdown-add-components';

const unknownHandler: Handler = (h, node) => {
  //@ts-expect-error
  return h(node, node.type, node, toHast(h, node));
};

export interface Rehype2ReactOptions {
  [key: string]: any;
}

export type DefaultEuiMarkdownProcessingPlugins = [
  [typeof remark2Rehype, Remark2RehypeOptions], // first is well known
  [typeof MarkdownAddComponents.processor, Rehype2ReactOptions], // second is well known
  ...PluggableList // any additional are generic
];

export const getDefaultEuiMarkdownProcessingPlugins: any = ({
  exclude
}: { exclude?: 'tooltip'[] } = {}) => {
  exclude;
  const plugins: DefaultEuiMarkdownProcessingPlugins = [
    [remark2Rehype, { allowDangerousHtml: true, unknownHandler }],
    [MarkdownAddComponents.processor, {}]
  ];
  return plugins;
};

export const defaultProcessingPlugins =
  getDefaultEuiMarkdownProcessingPlugins();
