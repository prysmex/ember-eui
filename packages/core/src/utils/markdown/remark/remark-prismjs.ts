/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { highlight } from 'refractor/core';
import visit from 'unist-util-visit';

import { highlightLanguage } from '../../../-private/language-loader.ts';
import { checkSupportedLanguage } from '../../code/utils.ts';

import type { Plugin } from 'unified';

export const FENCED_CLASS = 'remark-prismjs--fenced';

const attacher: Plugin = () => {
  return (ast) => visit(ast, 'code', visitor);

  function visitor(node: any) {
    const { data = {}, lang: language } = node;

    if (!language) {
      return;
    }

    const actualLanguage = checkSupportedLanguage(language);

    node.data = data;
    // plain until the language has loaded; reading it re-renders the
    // markdown then
    data.hChildren = highlight(node.value, highlightLanguage(actualLanguage));
    data.hProperties = {
      ...data.hProperties,
      language,
      className: [
        'prismjs',
        ...(data.hProperties?.className || []),
        `language-${language}`,
        FENCED_CLASS
      ]
    };
  }
};

export default attacher;
