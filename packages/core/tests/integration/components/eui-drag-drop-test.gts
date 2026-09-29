import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, rerender, triggerKeyEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDragDropContext from '#src/components/eui-drag-drop-context.gts';
import {
  euiDragDropCopy,
  euiDragDropMove,
  euiDragDropReorder
} from '#src/utils/drag-drop.ts';

import type { DropResult } from '#src/components/eui-drag-drop-context.gts';

class State {
  @tracked items = [
    { id: 'a', label: 'Apple' },
    { id: 'b', label: 'Banana' },
    { id: 'c', label: 'Cherry' }
  ];
  results: DropResult[] = [];

  onDragEnd = (result: DropResult) => {
    this.results.push(result);

    if (result.destination) {
      this.items = euiDragDropReorder(
        this.items,
        result.source.index,
        result.destination.index
      );
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
          <dnd.Droppable
            @droppableId="list"
            @spacing="m"
            @withPanel={{true}}
            as |list|
          >
            {{#each state.items as |item index|}}
              <list.Draggable
                @draggableId={{item.id}}
                @index={{index}}
                @spacing="s"
                as |d|
              >
                <div
                  class="item {{if d.isDragging 'dragging'}}"
                >{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    assert
      .dom('.euiDroppable')
      .hasClass('euiDroppable--m')
      .hasClass('euiDroppable--withPanel')
      .hasClass('euiDroppable--noGrow');
    assert.dom('.euiDraggable').exists({ count: 3 });
    assert
      .dom('.euiDraggable')
      .hasClass('euiDraggable--s')
      .hasAttribute('tabindex', '0');
    assert
      .dom('.euiDraggable')
      .hasAttribute(
        'draggable',
        'true',
        'registered with pragmatic drag and drop'
      );
    assert.dom('.euiDraggable .euiDraggable__item').exists({ count: 3 });
  });

  test('the keyboard lifts, moves and drops an item', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" as |list|>
            {{#each state.items key="id" as |item index|}}
              <list.Draggable
                @draggableId={{item.id}}
                @index={{index}}
                data-id={{item.id}}
              >
                <div>{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    await triggerKeyEvent('[data-id="a"]', 'keydown', ' ');
    assert
      .dom('[data-id="a"]')
      .hasClass('euiDraggable--isDragging')
      .hasAria('pressed', 'true');
    assert
      .dom('.euiDroppable')
      .hasClass('euiDroppable--isDraggingType')
      .hasClass('euiDroppable--isDraggingOver');

    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    await triggerKeyEvent('[data-id="a"]', 'keydown', 'ArrowDown');
    assert.ok(
      this.element
        .querySelector<HTMLElement>('[data-id="b"]')!
        .style.transform.includes('translateY(-'),
      'the others slide up'
    );

    await triggerKeyEvent('[data-id="a"]', 'keydown', ' ');
    await rerender();

    assert.deepEqual(state.results.at(-1), {
      draggableId: 'a',
      type: 'EUI_DEFAULT',
      source: { droppableId: 'list', index: 0 },
      destination: { droppableId: 'list', index: 2 },
      reason: 'DROP'
    });
    assert.deepEqual(
      state.items.map((item) => item.id),
      ['b', 'c', 'a']
    );
    assert.dom('.euiDraggable--isDragging').doesNotExist();
  });

  test('Escape cancels; disabled items cannot be lifted', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" as |list|>
            {{#each state.items as |item index|}}
              <list.Draggable
                @draggableId={{item.id}}
                @index={{index}}
                @isDragDisabled={{eqB item.id}}
                data-id={{item.id}}
              >
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

    assert
      .dom('[data-id="b"]')
      .doesNotHaveAttribute('draggable')
      .doesNotHaveAttribute('tabindex');
    assert
      .dom('[data-id="b"] .euiDraggable__item')
      .hasClass('euiDraggable__item--isDisabled');
    await triggerKeyEvent('[data-id="b"]', 'keydown', ' ');
    assert.dom('.euiDraggable--isDragging').doesNotExist();
  });

  test('dragging with the pointer reorders the list', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId="list" as |list|>
            {{#each state.items key="id" as |item index|}}
              <list.Draggable
                @draggableId={{item.id}}
                @index={{index}}
                data-id={{item.id}}
              >
                <div style="height: 40px;">{{item.label}}</div>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </template>
    );

    const dataTransfer = new DataTransfer();
    const frame = () =>
      new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));
    const fire = (element: Element, type: string, clientY = 0) =>
      element.dispatchEvent(
        new DragEvent(type, {
          bubbles: true,
          cancelable: true,
          dataTransfer,
          clientX: 10,
          clientY
        })
      );
    const itemA = this.element.querySelector('[data-id="a"]')!;
    const itemC = this.element.querySelector('[data-id="c"]')!;
    const below = itemC.getBoundingClientRect().bottom - 2;

    fire(itemA, 'dragstart', itemA.getBoundingClientRect().top + 5);
    await frame();
    await frame();
    assert.dom('[data-id="a"]').hasClass('euiDraggable--isDragging');

    fire(itemC, 'dragenter', below);
    fire(itemC, 'dragover', below);
    await frame();
    await frame();
    assert.dom('.euiDroppable').hasClass('euiDroppable--isDraggingOver');

    fire(itemC, 'drop', below);
    await frame();

    assert.strictEqual(state.results.at(-1)?.reason, 'DROP');
    assert.deepEqual(state.results.at(-1)?.destination, {
      droppableId: 'list',
      index: 2
    });
    assert.deepEqual(
      state.items.map((item) => item.id),
      ['b', 'c', 'a']
    );
  });

  module('auto scroll', function (hooks) {
    class Long {
      @tracked items = Array.from({ length: 20 }, (_, i) => ({
        id: `item-${i}`,
        label: `Item ${i}`
      }));
      onDragEnd = () => {};
    }

    const frame = () =>
      new Promise((resolve) => requestAnimationFrame(() => resolve(undefined)));
    const dataTransfer = () => new DataTransfer();

    let transfer: DataTransfer;

    hooks.beforeEach(function () {
      transfer = dataTransfer();
    });

    const fire = (
      element: Element,
      type: string,
      clientX: number,
      clientY: number
    ) =>
      element.dispatchEvent(
        new DragEvent(type, {
          bubbles: true,
          cancelable: true,
          dataTransfer: transfer,
          clientX,
          clientY
        })
      );

    /** Drags the first item and holds the pointer near the bottom of `edge`. */
    async function dragNearBottom(root: Element, edge: Element) {
      const first = root.querySelector('.euiDraggable')!;
      const rect = edge.getBoundingClientRect();
      const x = rect.left + 10;
      const y = rect.bottom - 3;

      fire(first, 'dragstart', x, first.getBoundingClientRect().top + 5);
      await frame();

      // pragmatic's auto scroll speeds up over time: hold the position a while
      for (let i = 0; i < 40; i++) {
        fire(document.elementFromPoint(x, y) ?? edge, 'dragover', x, y);
        await frame();
      }

      fire(document.elementFromPoint(x, y) ?? edge, 'drop', x, y);
      await frame();
    }

    test('a scrollable list scrolls while dragging near its edge', async function (assert) {
      const state = new Long();

      await render(
        <template>
          <EuiDragDropContext
            @onDragEnd={{state.onDragEnd}}
            @autoScrollWindow={{false}}
            as |dnd|
          >
            <dnd.Droppable
              @droppableId="long"
              style="height: 120px; overflow-y: auto;"
              as |list|
            >
              {{#each state.items key="id" as |item index|}}
                <list.Draggable @draggableId={{item.id}} @index={{index}}>
                  <div style="height: 30px;">{{item.label}}</div>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        </template>
      );

      const list = this.element.querySelector('.euiDroppable')!;

      await dragNearBottom(this.element, list);
      assert.true(list.scrollTop > 0, `scrolled to ${list.scrollTop}`);
    });

    test('@autoScroll={{false}} keeps the list still', async function (assert) {
      const state = new Long();

      await render(
        <template>
          <EuiDragDropContext
            @onDragEnd={{state.onDragEnd}}
            @autoScrollWindow={{false}}
            as |dnd|
          >
            <dnd.Droppable
              @droppableId="long"
              @autoScroll={{false}}
              style="height: 120px; overflow-y: auto;"
              as |list|
            >
              {{#each state.items key="id" as |item index|}}
                <list.Draggable @draggableId={{item.id}} @index={{index}}>
                  <div style="height: 30px;">{{item.label}}</div>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        </template>
      );

      const list = this.element.querySelector('.euiDroppable')!;

      await dragNearBottom(this.element, list);
      assert.strictEqual(list.scrollTop, 0);
    });

    test('the yielded autoScroll modifier scrolls another container', async function (assert) {
      const state = new Long();

      await render(
        <template>
          <EuiDragDropContext
            @onDragEnd={{state.onDragEnd}}
            @autoScrollWindow={{false}}
            as |dnd|
          >
            <div
              class="board"
              style="height: 150px; overflow-y: auto;"
              {{dnd.autoScroll}}
            >
              <dnd.Droppable
                @droppableId="long"
                @autoScroll={{false}}
                as |list|
              >
                {{#each state.items key="id" as |item index|}}
                  <list.Draggable @draggableId={{item.id}} @index={{index}}>
                    <div style="height: 30px;">{{item.label}}</div>
                  </list.Draggable>
                {{/each}}
              </dnd.Droppable>
            </div>
          </EuiDragDropContext>
        </template>
      );

      const board = this.element.querySelector('.board')!;

      await dragNearBottom(this.element, board);
      assert.true(board.scrollTop > 0, `scrolled to ${board.scrollTop}`);
    });

    test('moving with the keyboard keeps the item in view', async function (assert) {
      const state = new Long();

      await render(
        <template>
          <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
            <dnd.Droppable
              @droppableId="long"
              style="height: 120px; overflow-y: auto;"
              as |list|
            >
              {{#each state.items key="id" as |item index|}}
                <list.Draggable
                  @draggableId={{item.id}}
                  @index={{index}}
                  data-id={{item.id}}
                >
                  <div style="height: 30px;">{{item.label}}</div>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        </template>
      );

      await triggerKeyEvent('[data-id="item-0"]', 'keydown', ' ');
      for (let i = 0; i < 8; i++) {
        await triggerKeyEvent('[data-id="item-0"]', 'keydown', 'ArrowDown');
      }

      assert.true(this.element.querySelector('.euiDroppable')!.scrollTop > 0);
      await triggerKeyEvent('[data-id="item-0"]', 'keydown', 'Escape');
    });
  });

  test('list helpers', function (assert) {
    assert.deepEqual(euiDragDropReorder([1, 2, 3], 0, 2), [2, 3, 1]);
    assert.deepEqual(
      euiDragDropMove(
        [1, 2],
        [3],
        { droppableId: 'x', index: 0 },
        { droppableId: 'y', index: 1 }
      ),
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
