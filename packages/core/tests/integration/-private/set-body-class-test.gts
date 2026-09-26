import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import setBodyClass from '#src/-private/set-body-class.ts';

class State {
  @tracked first = true;
  @tracked second = true;
  @tracked names = 'a b';
}

module('Integration | -private | set-body-class', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    document.body.classList.add('pre-existing');
  });

  hooks.afterEach(function () {
    document.body.classList.remove('pre-existing');
  });

  test('adds the class while rendered and removes it on teardown', async function (assert) {
    const state = new State();

    await render(
      <template>
        {{#if state.first}}{{(setBodyClass "is-open")}}{{/if}}
      </template>
    );

    assert.dom(document.body).hasClass('is-open');
    assert.dom(document.body).hasClass('pre-existing');

    state.first = false;
    await rerender();

    assert.dom(document.body).doesNotHaveClass('is-open');
    assert.dom(document.body).hasClass('pre-existing', 'leaves other classes alone');
  });

  test('is reference counted across nested usages', async function (assert) {
    const state = new State();

    await render(
      <template>
        {{#if state.first}}{{(setBodyClass "is-open")}}{{/if}}
        {{#if state.second}}{{(setBodyClass "is-open")}}{{/if}}
      </template>
    );

    assert.dom(document.body).hasClass('is-open');

    state.first = false;
    await rerender();
    assert.dom(document.body).hasClass('is-open', 'kept while one usage remains');

    state.second = false;
    await rerender();
    assert.dom(document.body).doesNotHaveClass('is-open', 'removed with the last usage');
  });

  test('updates when the class names change', async function (assert) {
    const state = new State();

    await render(<template>{{(setBodyClass state.names)}}</template>);

    assert.dom(document.body).hasClass('a');
    assert.dom(document.body).hasClass('b');

    state.names = 'b c';
    await rerender();

    assert.dom(document.body).doesNotHaveClass('a');
    assert.dom(document.body).hasClass('b');
    assert.dom(document.body).hasClass('c');
  });
});
