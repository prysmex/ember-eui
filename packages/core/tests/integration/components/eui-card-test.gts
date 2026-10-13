import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiCard from '#src/components/eui-card.gts';

module('Integration | Component | eui-card', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title and description', async function (assert) {
    await render(
      <template>
        <EuiCard @title="Hello" @description="World" />
      </template>
    );

    assert.dom('.euiCard').exists();
    assert.dom('.euiCard__title').hasText('Hello');
    assert.dom('.euiCard__description').hasText('World');
  });

  test('clicking the card forwards the click to the title button', async function (assert) {
    // relies on `didInsert (set this "link")` registering the title button
    let calls = 0;
    const onClick = () => calls++;

    await render(
      <template><EuiCard @title="Clickable" @onClick={{onClick}} /></template>
    );

    assert.dom('button.euiCard__titleButton').exists();

    await click('.euiCard');
    assert.strictEqual(calls, 1, 'outer click is forwarded once');

    await click('button.euiCard__titleButton');
    assert.strictEqual(calls, 2, 'direct click is not forwarded twice');
  });

  test('@hasBorder swaps the shadow for a border', async function (assert) {
    await render(
      <template>
        <EuiCard @title="Shadow" data-test-subj="shadow" />
        <EuiCard @title="Border" @hasBorder={{true}} data-test-subj="border" />
      </template>
    );

    // EuiPanel draws its border with an `::after` pseudo element
    const shadowEl = document.querySelector('[data-test-subj="shadow"]') as Element;
    const borderEl = document.querySelector('[data-test-subj="border"]') as Element;
    assert.strictEqual(getComputedStyle(shadowEl, '::after').borderTopWidth, '0px', 'default: no border');
    assert.notStrictEqual(getComputedStyle(shadowEl).boxShadow, 'none', 'default: shadow');
    assert.strictEqual(getComputedStyle(borderEl, '::after').borderTopWidth, '1px', 'bordered: border');
    assert.strictEqual(getComputedStyle(borderEl).boxShadow, 'none', 'bordered: no shadow');
  });

  test('betaBadgeProps accept color, href, target and onClick', async function (assert) {
    let clicked = 0;
    const link = { label: 'Beta', color: 'accent', href: '/docs', target: '_blank' };
    const button = { label: 'Lab', onClick: () => clicked++, onClickAriaLabel: 'About Lab' };
    await render(
      <template>
        <EuiCard @title="Link" @isDisabled={{true}} @betaBadgeProps={{link}} data-test-subj="a" />
        <EuiCard @title="Button" @betaBadgeProps={{button}} data-test-subj="b" />
      </template>
    );

    assert.dom('[data-test-subj="a"] a.euiBetaBadge').hasAttribute('href', '/docs').hasAttribute('target', '_blank').hasText('Beta');
    assert.dom('[data-test-subj="a"] a.euiBetaBadge').hasClass(/accent/, 'explicit color wins over the disabled subdued');
    await click('[data-test-subj="b"] button.euiBetaBadge');
    assert.strictEqual(clicked, 1);
    assert.dom('[data-test-subj="b"] button.euiBetaBadge').hasAttribute('aria-label', 'About Lab');
  });

  test('a disabled card still greys a plain badge, and a link badge stays hollow', async function (assert) {
    const plain = { label: 'Beta' };
    const link = { label: 'Beta', href: '#' };
    await render(
      <template>
        <EuiCard @title="P" @isDisabled={{true}} @betaBadgeProps={{plain}} data-test-subj="p" />
        <EuiCard @title="L" @isDisabled={{true}} @betaBadgeProps={{link}} data-test-subj="l" />
      </template>
    );
    const bg = (sel: string) => getComputedStyle(document.querySelector(sel) as Element).backgroundColor;
    assert.notStrictEqual(
      bg('[data-test-subj="p"] .euiBetaBadge'),
      bg('[data-test-subj="l"] .euiBetaBadge'),
      'different colors'
    );
  });

  test('@image accepts a component for a custom image', async function (assert) {
    const Custom = <template><svg class="custom-image" width="10" height="10"></svg></template>;
    await render(
      <template>
        <EuiCard @title="Url" @image="data:image/gif;base64,R0lGODlhAQABAAAAACw=" data-test-subj="url" />
        <EuiCard @title="Node" @image={{Custom}} data-test-subj="node" />
      </template>
    );

    assert.dom('[data-test-subj="url"] .euiCard__image img').exists();
    assert.dom('[data-test-subj="node"] .euiCard__image .custom-image').exists();
    assert.dom('[data-test-subj="node"] .euiCard__image img').doesNotExist();
  });
});
