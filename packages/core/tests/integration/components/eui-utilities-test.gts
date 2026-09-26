import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array } from '@ember/helper';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { on } from '@ember/modifier';
import { click, render, rerender, settled, triggerEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiAutoSizer from '#src/components/eui-auto-sizer.gts';
import EuiCode from '#src/components/eui-code.gts';
import EuiCopy from '#src/components/eui-copy.gts';
import EuiHideFor from '#src/components/eui-hide-for.gts';
import EuiInnerText from '#src/components/eui-inner-text.gts';
import EuiShowFor from '#src/components/eui-show-for.gts';

module('Integration | Component | utilities', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiShowFor / EuiHideFor with "all" and "none"', async function (assert) {
    await render(
      <template>
        <EuiShowFor @sizes="all"><span class="show-all">a</span></EuiShowFor>
        <EuiShowFor @sizes="none"><span class="show-none">b</span></EuiShowFor>
        <EuiHideFor @sizes="all"><span class="hide-all">c</span></EuiHideFor>
        <EuiHideFor @sizes="none"><span class="hide-none">d</span></EuiHideFor>
      </template>
    );

    assert.dom('.show-all').exists();
    assert.dom('.show-none').doesNotExist();
    assert.dom('.hide-all').doesNotExist();
    assert.dom('.hide-none').exists();
  });

  test('EuiShowFor / EuiHideFor follow the current breakpoint', async function (assert) {
    // the test browser is 1440px wide, i.e. the "xl" breakpoint
    await render(
      <template>
        <EuiShowFor @sizes={{array "l" "xl"}}><span class="show-desktop">a</span></EuiShowFor>
        <EuiShowFor @sizes={{array "xs" "s"}}><span class="show-mobile">b</span></EuiShowFor>
        <EuiHideFor @sizes={{array "xs" "s"}}><span class="hide-mobile">c</span></EuiHideFor>
      </template>
    );

    assert.dom('.show-desktop').exists();
    assert.dom('.show-mobile').doesNotExist();
    assert.dom('.hide-mobile').exists();
  });

  test('EuiAutoSizer yields the size of its parent', async function (assert) {
    await render(
      <template>
        <div style="width: 300px; height: 120px;">
          <EuiAutoSizer as |childStyle|>
            <span class="sized-width">{{childStyle.width}}</span>
            <span class="sized-height">{{childStyle.height}}</span>
          </EuiAutoSizer>
        </div>
      </template>
    );

    await waitUntil(() => document.querySelector('.sized-width')?.textContent?.trim() === '300px');
    assert.dom('.sized-width').hasText('300px');
    assert.dom('.sized-height').hasText('120px');
  });

  test('EuiInnerText yields the text of the referenced element', async function (assert) {
    await render(
      <template>
        <EuiInnerText as |setRef innerText|>
          <span {{didInsert setRef}}>Visible text</span>
          <span class="copy-of-text">{{innerText}}</span>
        </EuiInnerText>
      </template>
    );

    await settled();
    assert.dom('.copy-of-text').hasText('Visible text');
  });

  test('EuiCopy copies the text and changes the tooltip', async function (assert) {
    const original = document.execCommand;
    const copied: string[] = [];

    document.execCommand = ((command: string) => {
      copied.push(command);

      return true;
    }) as typeof document.execCommand;

    try {
      await render(
        <template>
          <EuiCopy @textToCopy="secret" @beforeMessage="Click to copy" @afterMessage="Copied!" as |copy|>
            <button type="button" class="copy-button" {{on "click" copy}}>Copy</button>
          </EuiCopy>
        </template>
      );

      await triggerEvent('.euiToolTipAnchor', 'mouseover');
      await waitUntil(() => document.querySelector('.euiToolTip'));
      assert.dom('.euiToolTip', document.body).containsText('Click to copy');

      await click('.copy-button');
      assert.deepEqual(copied, ['copy']);
      assert.dom('.euiToolTip', document.body).containsText('Copied!');
    } finally {
      document.execCommand = original;
    }
  });

  test('EuiCode highlights inline code', async function (assert) {
    await render(<template><EuiCode @language="js">const answer = 42;</EuiCode></template>);

    await waitUntil(() => document.querySelector('code.euiCode .token'));
    assert.dom('code.euiCode').hasAttribute('data-code-language', 'js').hasText('const answer = 42;');
    assert.dom('code.euiCode .token.keyword').hasText('const');
  });

  test('EuiCode transparent background', async function (assert) {
    await render(<template><EuiCode @transparentBackground={{true}}>plain</EuiCode></template>);

    await settled();
    assert.dom('code.euiCode').hasClass('euiCode--transparentBackground').hasAttribute('data-code-language', 'text');
  });
});
