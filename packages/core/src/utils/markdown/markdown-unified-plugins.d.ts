/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

declare module 'remark-highlight.js' {
  import type { Plugin } from 'unified';
  const RemarkHighlight: Plugin;
  export = RemarkHighlight;
}

// remark/remark-emoji.ts reads the data of node-emoji and emoticon directly
declare module 'node-emoji/lib/emoji.json' {
  const emojiByName: Record<string, string>;
  export default emojiByName;
}

declare module 'emoticon' {
  const emoticons: {
    name: string;
    emoji: string;
    tags: string[];
    description: string;
    emoticons: string[];
  }[];
  export default emoticons;
}
