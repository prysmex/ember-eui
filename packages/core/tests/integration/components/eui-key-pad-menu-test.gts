import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiIcon from '#src/components/eui-icon.gts';
import EuiKeyPadMenu from '#src/components/eui-key-pad-menu.gts';
import EuiKeyPadMenuItem from '#src/components/eui-key-pad-menu-item.gts';

module('Integration | Component | eui-key-pad-menu', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders items as buttons and links', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiKeyPadMenu as |Key|>
          <Key>
            <EuiKeyPadMenuItem @label="Dashboard" @isSelected={{true}} {{on "click" onClick}}>
              <EuiIcon @type="dashboardApp" @size="l" />
            </EuiKeyPadMenuItem>
          </Key>
          <Key>
            <EuiKeyPadMenuItem @label="Docs" @href="#docs" @betaBadgeLabel="Beta">
              <EuiIcon @type="documents" @size="l" />
            </EuiKeyPadMenuItem>
          </Key>
          <Key><EuiKeyPadMenuItem @label="Off" @isDisabled={{true}} /></Key>
        </EuiKeyPadMenu>
      </template>
    );

    assert.dom('ul.euiKeyPadMenu li').exists({ count: 3 });
    assert.dom('button.euiKeyPadMenuItem').exists({ count: 2 });
    assert.dom('li:nth-child(1) button').hasClass('euiKeyPadMenuItem-isSelected').hasAttribute('aria-pressed', 'true');
    assert.dom('li:nth-child(1) .euiKeyPadMenuItem__label').hasText('Dashboard');
    assert.dom('li:nth-child(1) .euiKeyPadMenuItem__icon svg').exists();
    assert.dom('li:nth-child(2) a').hasAttribute('href', '#docs').hasClass('euiKeyPadMenuItem--hasBetaBadge');
    assert.dom('li:nth-child(2) .euiKeyPadMenuItem__betaBadge').hasText('B');
    assert.dom('li:nth-child(3) button').isDisabled().hasClass('euiKeyPadMenuItem-isDisabled');

    await click('li:nth-child(1) button');
    assert.strictEqual(clicks, 1);
  });

  test('checkable single items use radios inside a fieldset', async function (assert) {
    const changes: unknown[][] = [];
    const onChange = (...args: unknown[]) => changes.push(args.slice(0, 2));
    const checkable = { legend: 'Pick one', ariaLegend: 'Pick one' };

    await render(
      <template>
        <EuiKeyPadMenu @checkable={{checkable}}>
          <EuiKeyPadMenuItem @checkable="single" @label="A" @name="pick" @value="a" @id="a" @onChange={{onChange}} />
          <EuiKeyPadMenuItem @checkable="single" @label="B" @name="pick" @value="b" @id="b" @onChange={{onChange}} />
        </EuiKeyPadMenu>
      </template>
    );

    assert.dom('fieldset.euiKeyPadMenu legend').hasText('Pick one');
    assert.dom('label.euiKeyPadMenuItem--checkable').exists({ count: 2 });
    assert.dom('input[type="radio"]').exists({ count: 2 });

    await click('#b');
    assert.deepEqual(changes, [['b', 'b']]);
  });

  test('the beta badge only renders with @betaBadgeLabel', async function (assert) {
    await render(
      <template>
        <EuiKeyPadMenu>
          <EuiKeyPadMenuItem @label="Plain" class="plain">
            <EuiIcon @type="dashboardApp" @size="l" />
          </EuiKeyPadMenuItem>
          <EuiKeyPadMenuItem @label="Beta" @betaBadgeLabel="Beta" class="beta">
            <EuiIcon @type="dashboardApp" @size="l" />
          </EuiKeyPadMenuItem>
        </EuiKeyPadMenu>
      </template>
    );

    assert.dom('.plain .euiKeyPadMenuItem__betaBadge').doesNotExist();
    assert.dom('.beta .euiKeyPadMenuItem__betaBadge').exists();
    assert.dom('.beta').hasClass('euiKeyPadMenuItem--hasBetaBadge');
  });
});
