import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent, triggerKeyEvent } from '@ember/test-helpers';

import EuiResizableContainer from '#src/components/eui-resizable-container.gts';

module('Integration | Component | eui-resizable-container', function (hooks) {
  setupRenderingTest(hooks);

  test('panels take their initial sizes; the keyboard resizes them', async function (assert) {
    const changes: Record<string, number>[] = [];
    const onChange = (sizes: Record<string, number>) => changes.push(sizes);

    await render(
      <template>
        <div style="width: 1000px;">
          <EuiResizableContainer @onPanelWidthChange={{onChange}} as |c|>
            <c.Panel @id="left" @initialSize={{30}}>Left</c.Panel>
            <c.Button />
            <c.Panel @id="right" @initialSize={{70}}>Right</c.Panel>
          </EuiResizableContainer>
        </div>
      </template>
    );

    assert.dom('.euiResizableContainer').hasClass('euiResizableContainer--horizontal');
    assert.dom('#left').hasClass('euiResizablePanel--first');
    assert.strictEqual(this.element.querySelector<HTMLElement>('#left')!.style.width, '30%');
    assert.dom('#right').hasClass('euiResizablePanel--last');
    assert.dom('.euiResizableButton').hasClass('euiResizableButton--horizontal').hasAria('label', 'Press left or right to adjust panels size');

    const width = () => this.element.querySelector('#left')!.getBoundingClientRect().width;
    const before = width();

    await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowRight');
    assert.strictEqual(changes.length, 1);
    assert.true(changes[0]!['left']! > 30, 'the panel before grows');
    assert.true(changes[0]!['right']! < 70, 'the panel after shrinks');
    assert.strictEqual(Math.round(width() - before), 10, 'by 10px');
  });

  test('dragging the button resizes the panels', async function (assert) {
    await render(
      <template>
        <div style="width: 1000px;">
          <EuiResizableContainer as |c|>
            <c.Panel @id="a" @initialSize={{50}} @minSize="10%">A</c.Panel>
            <c.Button />
            <c.Panel @id="b" @initialSize={{50}}>B</c.Panel>
          </EuiResizableContainer>
        </div>
      </template>
    );

    const button = this.element.querySelector('.euiResizableButton')!;
    const x = button.getBoundingClientRect().left;

    const width = () => this.element.querySelector('#a')!.getBoundingClientRect().width;
    const before = width();

    await triggerEvent(button, 'mousedown', { clientX: x, clientY: 10 });
    await triggerEvent('.euiResizableContainer', 'mousemove', { clientX: x - 100, clientY: 10 });
    await triggerEvent('.euiResizableContainer', 'mouseup');

    assert.strictEqual(Math.round(before - width()), 100, 'the panel before shrinks by the distance dragged');

    const after = width();

    await triggerEvent(button, 'mousedown', { clientX: x - 100, clientY: 10 });
    await triggerEvent('.euiResizableContainer', 'mousemove', { clientX: x - 450, clientY: 10 });
    assert.strictEqual(width(), after, 'not smaller than @minSize');
  });

  test('a collapsible panel collapses and expands', async function (assert) {
    await render(
      <template>
        <div style="width: 1000px;">
          <EuiResizableContainer as |c|>
            <c.Panel @id="nav" @mode="collapsible" @initialSize={{20}}>Nav</c.Panel>
            <c.Button />
            <c.Panel @id="main" @mode="main" @initialSize={{80}}>Main</c.Panel>
          </EuiResizableContainer>
        </div>
      </template>
    );

    assert.dom('#nav').hasClass('euiResizablePanel--collapsible');
    assert.dom('#nav .euiResizableToggleButton').hasClass('euiResizableToggleButton--after');

    await click('#nav .euiResizableToggleButton');
    assert.dom('#nav').hasClass('euiResizablePanel-isCollapsed');
    assert.dom('.euiResizableButton').isDisabled('the resizer next to a collapsed panel is disabled');

    await click('#nav .euiResizableToggleButton');
    assert.dom('#nav').doesNotHaveClass('euiResizablePanel-isCollapsed');
    assert.strictEqual(this.element.querySelector<HTMLElement>('#nav')!.style.width, '20%', 'back to its size');
  });

  test('vertical', async function (assert) {
    await render(
      <template>
        <div style="height: 400px;">
          <EuiResizableContainer @direction="vertical" style="height: 400px;" as |c|>
            <c.Panel @initialSize={{50}}>Top</c.Panel>
            <c.Button />
            <c.Panel @initialSize={{50}}>Bottom</c.Panel>
          </EuiResizableContainer>
        </div>
      </template>
    );

    assert.dom('.euiResizableContainer').hasClass('euiResizableContainer--vertical');
    assert.dom('.euiResizableButton').hasClass('euiResizableButton--vertical');
  });
});
