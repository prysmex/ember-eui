/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import refractor from 'refractor';
import visit from 'unist-util-visit';
import type { Plugin } from 'unified';
import { checkSupportedLanguage } from '../../code/utils';

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
    data.hChildren = refractor.highlight(node.value, actualLanguage);
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
