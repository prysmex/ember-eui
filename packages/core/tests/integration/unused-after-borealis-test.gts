import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { getDeprecations, render } from '@ember/test-helpers';
import style from 'ember-style-modifier/modifiers/style';

import MarkdownCheckmark from '#src/components/eui-markdown-editor-toolbar/icons/markdown-checkmark.gts';
import classNames from '#src/helpers/class-names.ts';
import euiPageRestrictWidth from '#src/helpers/eui-page-restrict-width.ts';
import getRangeTick from '#src/helpers/get-range-tick.ts';
import inlineStyles from '#src/helpers/inline-styles.ts';

/** Deprecations recorded in this test with the given name. */
function unused(name: string) {
  const id = `ember-eui.${name}.unused-after-borealis`;
  return getDeprecations().filter((d) => d.options?.id === id);
}

const TICK_VALUE = 5;
const MIN = 0;
const MAX = 10;
const WIDTH = 10;

module('Integration | unused after Borealis', function (hooks) {
  setupRenderingTest(hooks);

  test('class-names joins classes without deprecating', async function (assert) {
    const extra = undefined;

    await render(
      <template>
        <div id="target" class={{classNames "euiFoo  " extra "euiBar"}}></div>
      </template>
    );

    assert.dom('#target').hasAttribute('class', 'euiFoo euiBar');
    assert.strictEqual(unused('class-names-component-name').length, 0);
  });

  test('class-names deprecates and ignores componentName', async function (assert) {
    await render(
      <template>
        <div id="target" class={{classNames "euiFoo" componentName="EuiButton" color="primary"}}></div>
      </template>
    );

    assert.dom('#target').hasAttribute('class', 'euiFoo', 'no legacy mapping classes are added');

    const [deprecation] = unused('class-names-component-name');
    assert.ok(deprecation, 'fires');
    assert.deepEqual(
      { for: deprecation?.options.for, since: deprecation?.options.since, until: deprecation?.options.until },
      { for: '@ember-eui/core', since: { available: '15.0.0', enabled: '15.0.0' }, until: '16.0.0' }
    );
    assert.true(deprecation?.message.includes('EuiButton'), 'message names the component');
  });

  test('inline-styles keeps working and deprecates componentName', async function (assert) {
    await render(
      <template>
        <div id="plain" {{style (inlineStyles background="black")}}></div>
      </template>
    );

    assert.dom('#plain').hasStyle({ backgroundColor: 'rgb(0, 0, 0)' });
    assert.strictEqual(unused('inline-styles-component-name').length, 0);

    await render(
      <template>
        <div id="mapped" {{style (inlineStyles componentName="EuiAvatar" background="black")}}></div>
      </template>
    );

    assert.dom('#mapped').hasStyle({ backgroundColor: 'rgb(0, 0, 0)' });
    assert.strictEqual(unused('inline-styles-component-name').length, 1, 'fires');
  });

  test('get-range-tick, eui-page-restrict-width and MarkdownCheckmark deprecate at use', async function (assert) {
    await render(
      <template>
        {{#let (getRangeTick undefined TICK_VALUE MIN MAX WIDTH) as |tick|}}
          <span id="tick">{{tick.label}}</span>
        {{/let}}
        {{#let (euiPageRestrictWidth 600) as |result|}}
          <span id="width">{{result.newStyle.maxWidth}}</span>
        {{/let}}
        <MarkdownCheckmark @title="Task list" @titleId="checkmark-title" />
      </template>
    );

    assert.dom('#tick').hasText('5', 'get-range-tick still works');
    assert.dom('#width').hasText('600px', 'eui-page-restrict-width still works');
    assert.dom('svg title#checkmark-title').hasText('Task list', 'MarkdownCheckmark still renders');

    for (const name of ['get-range-tick', 'eui-page-restrict-width', 'markdown-checkmark']) {
      const [deprecation] = unused(name);
      assert.ok(deprecation, `${name} fires`);
      assert.strictEqual(deprecation?.options.until, '16.0.0', `${name} until 16.0.0`);
    }
  });
});
