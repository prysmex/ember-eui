import { module, test } from 'qunit';

import remarkEmoji from '#src/utils/markdown/remark/remark-emoji.ts';

import type { RemarkEmojiOptions } from '#src/utils/markdown/remark/remark-emoji.ts';

function emojify(value: string, options?: RemarkEmojiOptions): string {
  const tree = { type: 'root', children: [{ type: 'text', value }] };

  (remarkEmoji as any).call(null, options)(tree);

  return tree.children[0]!.value;
}

// same results as remark-emoji 2.2 (which went through node-emoji)
module('Unit | utils | markdown | remark-emoji', function () {
  test('replaces shortcodes', function (assert) {
    assert.strictEqual(emojify(':smile: :+1: :-1: a:heart:b'), '😄 👍 👎 a❤️b');
  });

  test('leaves unknown shortcodes and emoticons alone by default', function (assert) {
    assert.strictEqual(emojify(':nope: :) ;)'), ':nope: :) ;)');
    assert.strictEqual(emojify(':constructor: :toString:'), ':constructor: :toString:');
  });

  test('`emoticon` replaces emoticons', function (assert) {
    assert.strictEqual(emojify('hi :) ok :-(', { emoticon: true }), 'hi 😃 ok 😦');
  });

  test('`padSpaceAfter` adds a space after each emoji', function (assert) {
    assert.strictEqual(emojify(':smile:!', { padSpaceAfter: true }), '😄 !');
    assert.strictEqual(emojify(':nope:', { padSpaceAfter: true }), ':nope:');
  });
});
