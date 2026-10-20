/**
 * remark-emoji 2.2 (MIT, https://github.com/rhysd/remark-emoji), reading
 * node-emoji's name map directly: node-emoji's main module requires
 * CommonJS `lodash/toArray`, which put ~70KB of lodash in every bundle with
 * markdown. Same matching and options: `:name:` shortcodes, and with
 * `emoticon: true` emoticons such as `:)`; `padSpaceAfter` adds a space
 * after each emoji.
 */
import emoticons from 'emoticon';
import emojiByName from 'node-emoji/lib/emoji.json';
import visit from 'unist-util-visit';

import type { Plugin } from 'unified';

const RE_EMOJI = /:\+1:|:-1:|:[\w-]+:/g;
const RE_SHORT = /[$@|*'",;.=:\-)([\]\\/<>038BOopPsSdDxXzZ]{2,5}/g;

export interface RemarkEmojiOptions {
  padSpaceAfter?: boolean;
  emoticon?: boolean;
}

const remarkEmoji: Plugin<[RemarkEmojiOptions?]> = (options = {}) => {
  const pad = Boolean(options.padSpaceAfter);
  const emoticonEnable = Boolean(options.emoticon);

  function getEmojiByShortCode(match: string): string {
    // full match, or without the last char as it could be from text, e.g. :-),
    const iconFull = emoticons.find((e) => e.emoticons.includes(match));
    const iconPart = emoticons.find((e) =>
      e.emoticons.includes(match.slice(0, -1))
    );
    const trimmedChar = iconPart ? match.slice(-1) : '';
    const addPad = pad ? ' ' : '';
    const icon = iconFull
      ? iconFull.emoji + addPad
      : iconPart && iconPart.emoji + addPad + trimmedChar;

    return icon || match;
  }

  function getEmoji(match: string): string {
    const name = match.slice(1, -1);

    if (!Object.prototype.hasOwnProperty.call(emojiByName, name)) {
      return match;
    }

    return emojiByName[name] + (pad ? ' ' : '');
  }

  return (tree) => {
    visit(tree, 'text', (node: any) => {
      node.value = node.value.replace(RE_EMOJI, getEmoji);

      if (emoticonEnable) {
        node.value = node.value.replace(RE_SHORT, getEmojiByShortCode);
      }
    });
  };
};

export default remarkEmoji;
