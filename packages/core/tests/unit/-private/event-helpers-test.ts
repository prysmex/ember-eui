import { module, test } from 'qunit';

import {
  preventDefault,
  stopPropagation
} from '#src/-private/event-helpers.ts';

module('Unit | -private | event-helpers', function () {
  test('preventDefault prevents the default action, then calls the handler', function (assert) {
    const event = new Event('click', { cancelable: true });
    const seen: boolean[] = [];

    preventDefault((e) => seen.push(e.defaultPrevented))(event);

    assert.true(event.defaultPrevented);
    assert.deepEqual(seen, [true], 'handler runs after preventDefault');
  });

  test('stopPropagation stops the event from bubbling', function (assert) {
    const parent = document.createElement('div');
    const child = document.createElement('button');
    parent.appendChild(child);

    let parentCalls = 0;
    let handlerCalls = 0;
    parent.addEventListener('click', () => parentCalls++);
    child.addEventListener('click', stopPropagation(() => handlerCalls++));

    child.dispatchEvent(new Event('click', { bubbles: true }));

    assert.strictEqual(handlerCalls, 1);
    assert.strictEqual(parentCalls, 0, 'did not bubble to the parent');
  });

  test('the handler is optional', function (assert) {
    const event = new Event('click', { cancelable: true });

    preventDefault()(event);
    stopPropagation(undefined)(event);

    assert.true(event.defaultPrevented);
  });
});
