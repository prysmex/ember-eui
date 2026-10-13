import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiListGroupItem from '#src/components/eui-list-group-item.gts';

const noop = () => {};

const ExtraAction = <template>
  <button type="button" class="my-extra-action">Extra</button>
</template>;

module('Integration | Component | eui-list-group-item', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the label and an @extraAction component', async function (assert) {
    await render(
      <template>
        <EuiListGroupItem @label="Item" @extraAction={{ExtraAction}} />
      </template>
    );

    assert.dom('.euiListGroupItem').exists();
    assert.dom('.euiListGroupItem__label').hasText('Item');
    assert.dom('button.my-extra-action').exists();
  });

  test('@showToolTip, @toolTipText and @toolTipProps customize the tooltip', async function (assert) {
    await render(
      <template>
        <EuiListGroupItem
          @label="Item"
          @onClick={{noop}}
          @showToolTip={{true}}
          @toolTipText="More"
          @toolTipProps={{hash position="bottom" title="Heading" anchorClassName="mine"}}
        />
      </template>
    );

    assert.dom('.euiListGroupItem__tooltip.mine').exists();
    assert.dom('.euiListGroupItem__tooltip.mine button').exists();
    await triggerEvent('.euiListGroupItem__tooltip', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).containsText('More').containsText('Heading');
  });

  test('a tooltip on a plain item wraps its content inside the li', async function (assert) {
    await render(<template><EuiListGroupItem @label="Plain" @showToolTip={{true}} /></template>);

    assert.dom('li.euiListGroupItem > .euiListGroupItem__tooltip').exists();
    const el = document.querySelector('.euiListGroupItem__tooltip') as HTMLElement;
    // `inline-flex` is blockified to `flex` inside a flex parent
    assert.ok(['flex', 'inline-flex'].includes(getComputedStyle(el).display));
  });
});
