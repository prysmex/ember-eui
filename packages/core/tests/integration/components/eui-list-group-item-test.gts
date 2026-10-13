import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiListGroup from '#src/components/eui-list-group.gts';
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

  // upstream list_group_item.tsx: `content: toolTipText ?? label` with a node label
  test('without @toolTipText the tooltip shows the block (the label node)', async function (assert) {
    await render(
      <template>
        <EuiListGroupItem @onClick={{noop}} @showToolTip={{true}}>
          Third <strong class="rich">will surely</strong> truncate
        </EuiListGroupItem>
      </template>
    );

    await triggerEvent('.euiListGroupItem__tooltip', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).containsText('Third will surely truncate');
    assert.dom('.euiToolTip strong.rich', document.body).exists('rich content kept');
  });

  test('@toolTipText and toolTipProps.content win over the block', async function (assert) {
    const props = { content: 'From props' };
    await render(
      <template>
        <EuiListGroupItem @onClick={{noop}} @showToolTip={{true}} @toolTipText="Text" data-test="a">Block</EuiListGroupItem>
        <EuiListGroupItem @onClick={{noop}} @showToolTip={{true}} @toolTipText="Text" @toolTipProps={{props}} data-test="b">Block</EuiListGroupItem>
      </template>
    );

    await triggerEvent('[data-test="a"]', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasText('Text');
    await triggerEvent('[data-test="a"]', 'mouseout');
    await waitUntil(() => !document.querySelector('.euiToolTip'));
    await triggerEvent('[data-test="b"]', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasText('From props');
  });

  // upstream: `title: typeof label === 'string' ? label : innerText`
  test('a block label gets its text as title unless wrapping or a tooltip', async function (assert) {
    class State {
      @tracked wrap = false;
      @tracked tip = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiListGroupItem @href="#x" @wrapText={{state.wrap}} @showToolTip={{state.tip}} data-test="link">
          Rich <em>label</em>
        </EuiListGroupItem>
        <EuiListGroupItem @label="Plain" data-test="plain" />
      </template>
    );

    await waitUntil(() => document.querySelector('[data-test="link"] .euiListGroupItem__label[title]'));
    assert.dom('[data-test="link"] .euiListGroupItem__label').hasAttribute('title', 'Rich label');
    assert.dom('[data-test="plain"] .euiListGroupItem__label').hasAttribute('title', 'Plain');
    state.wrap = true;
    await settled();
    assert.dom('[data-test="link"] .euiListGroupItem__label').doesNotHaveAttribute('title');
    state.wrap = false;
    state.tip = true;
    await settled();
    assert.dom('[data-test="link"] .euiListGroupItem__label').doesNotHaveAttribute('title');
  });

  // upstream EuiListItemLayout: a plain li with a tooltip gets
  // `aria-describedby = classNames(tooltipId, aria-describedby)`
  test('a plain item with a tooltip is described by it, keeping its own ids', async function (assert) {
    const props = { id: 'my-tip' };
    class State {
      @tracked tip = true;
    }
    const state = new State();
    await render(
      <template>
        <span id="other">Other</span>
        <EuiListGroupItem @label="Plain" @showToolTip={{state.tip}} @toolTipProps={{props}} aria-describedby="other" data-test="li" />
        <EuiListGroupItem @label="Generated" @showToolTip={{true}} data-test="gen" />
        <EuiListGroupItem @label="Button" @onClick={{noop}} @showToolTip={{true}} data-test="button" />
      </template>
    );

    assert.dom('[data-test="li"]').hasAttribute('aria-describedby', 'my-tip other');
    assert.dom('[data-test="gen"]').hasAttribute('aria-describedby', /-tooltip$/);
    assert.dom('[data-test="button"]').doesNotHaveAttribute('aria-describedby', 'interactive items only while visible');
    await triggerEvent('[data-test="li"] .euiListGroupItem__tooltip', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasAttribute('id', 'my-tip').hasText('Plain');
    await triggerEvent('[data-test="li"] .euiListGroupItem__tooltip', 'mouseout');
    await waitUntil(() => !document.querySelector('.euiToolTip'));
    state.tip = false;
    await settled();
    assert.dom('[data-test="li"]').hasAttribute('aria-describedby', 'other');
  });

  test('toolTipProps forward isShown', async function (assert) {
    const props = { isShown: true };
    await render(<template><EuiListGroupItem @label="Shown" @onClick={{noop}} @showToolTip={{true}} @toolTipProps={{props}} /></template>);

    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTip', document.body).hasText('Shown');
  });

  // upstream list_group.tsx: `wrapText` is passed to `listItems` only, not
  // cloned into children
  test("the list's @wrapText reaches @listItems but not block items", async function (assert) {
    const items = [{ label: 'Listed' }, { label: 'Own', wrapText: false }];
    await render(
      <template>
        <EuiListGroup @wrapText={{true}} data-test="block">
          <EuiListGroupItem @label="Child" data-test="child" />
          <EuiListGroupItem @label="Wrapped child" @wrapText={{true}} data-test="wrapped" />
        </EuiListGroup>
        <EuiListGroup @wrapText={{true}} @listItems={{items}} data-test="items" />
      </template>
    );

    const ws = (selector: string) => getComputedStyle(document.querySelector(`${selector} .euiListGroupItem__label`)!).whiteSpace;
    assert.strictEqual(ws('[data-test="child"]'), 'nowrap');
    assert.dom('[data-test="child"] .euiListGroupItem__label').hasAttribute('title', 'Child');
    assert.strictEqual(ws('[data-test="wrapped"]'), 'normal');
    assert.strictEqual(ws('[data-test="items"] li:nth-child(1)'), 'normal');
    assert.dom('[data-test="items"] li:nth-child(1) .euiListGroupItem__label').doesNotHaveAttribute('title');
    assert.strictEqual(ws('[data-test="items"] li:nth-child(2)'), 'nowrap', "an item's own wrapText wins");
  });
});
