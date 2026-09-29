import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDragDropContext from '#src/components/eui-drag-drop-context.gts';
import { euiDragDropCopy, euiDragDropMove, euiDragDropReorder } from '#src/utils/drag-drop.ts';

import type { DropResult } from '#src/components/eui-drag-drop-context.gts';

class State {
  @tracked items = [
    { id: 'a', label: 'Apple' },
    { id: 'b', label: 'Banana' },
    { id: 'c', label: 'Cherry' },
  ];
  results: DropResult[] = [];

  onDragEnd = (result: DropResult) => {
    this.results.push(result);

    if (result.destination) {
      this.items = euiDragDropReorder(this.items, result.source.index, result.destination.index);
    }
  };
}

module('Integration | Component | eui-drag-drop', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders droppables and draggables', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" @spacing="m" @withPanel={{true}} as |list|>
            {{#each state.items as |item index|}}
              <list.Draggable @draggableId={{item.id}} @index={{index}} @spacing="s" as |d|>
                <div class="item {{if d.isDragging 'dragging'}}">{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    assert.dom('.euiDroppable').hasClass('euiDroppable--m').hasClass('euiDroppable--withPanel').hasClass('euiDroppable--noGrow');
    assert.dom('.euiDraggable').exists({ count: 3 });
    assert.dom('.euiDraggable').hasClass('euiDraggable--s').hasAttribute('draggable', 'true').hasAttribute('tabindex', '0');
    assert.dom('.euiDraggable .euiDraggable__item').exists({ count: 3 });
  });

  test('the keyboard lifts, moves and drops an item', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" as |list|>
            {{#each state.items key="id" as |item index|}}
              <list.Draggable @draggableId={{item.id}} @index={{index}} data-id={{item.id}}>
                <div>{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    await triggerKeyEvent('[data-id="a"]', 'keydown', ' ');
    assert.dom('[data-id="a"]').hasClass('euiDraggable--isDragging').hasAria('pressed', 'true');
    assert.dom('.euiDroppable').hasClass('euiDroppable--isDraggingType').hasClass('euiDroppable--isDraggingOver');

    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    assert.ok(this.element.querySelector<HTMLElement>('[data-id="b"]')!.style.transform.includes('translateY(-'), 'the others slide up');

    await triggerKeyEvent('[data-id="a"]', 'keydown', ' ');
    await rerender();

    assert.deepEqual(state.results.at(-1), {
      draggableId: 'a',
      type: 'EUI_DEFAULT',
      source: { droppableId: 'list', index: 0 },
      destination: { droppableId: 'list', index: 2 },
      reason: 'DROP',
    });
    assert.deepEqual(state.items.map((item) => item.id), ['b', 'c', 'a']);
    assert.dom('.euiDraggable--isDragging').doesNotExist();
  });

  test('Escape cancels; disabled items cannot be lifted', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" as |list|>
            {{#each state.items as |item index|}}
              <list.Draggable @draggableId={{item.id}} @index={{index}} @isDragDisabled={{eqB item.id}} data-id={{item.id}}>
                <div>{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    await triggerKeyEvent('[data-id="a"]', 'keydown', ' ');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'Escape');
    assert.strictEqual(state.results.at(-1)!.reason, 'CANCEL');
    assert.strictEqual(state.results.at(-1)!.destination, null);

    assert.dom('[data-id="b"]').hasAttribute('draggable', 'false').doesNotHaveAttribute('tabindex');
    assert.dom('[data-id="b"] .euiDraggable__item').hasClass('euiDraggable__item--isDisabled');
    await triggerKeyEvent('[data-id="b"]', 'keydown', ' ');
    assert.dom('.euiDraggable--isDragging').doesNotExist();
  });

  test('list helpers', function (assert) {
    assert.deepEqual(euiDragDropReorder([1, 2, 3], 0, 2), [2, 3, 1]);
    assert.deepEqual(
      euiDragDropMove([1, 2], [3], { droppableId: 'x', index: 0 }, { droppableId: 'y', index: 1 }),
      { x: [2], y: [3, 1] }
    );

    let n = 0;
    const copied = euiDragDropCopy(
      [{ id: 'a' }],
      [],
      { droppableId: 'x', index: 0 },
      { droppableId: 'y', index: 0 },
      { property: 'id', modifier: () => `copy-${++n}` }
    );

    assert.deepEqual(copied, { x: [{ id: 'a' }], y: [{ id: 'copy-1' }] });
  });
});

function eqB(id: string): boolean {
  return id === 'b';
}
