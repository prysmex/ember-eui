/**
 * The floating layers (V03 batch 2, after the real-input check): the
 * field editor, the row menu and the panel editors render in a portaled
 * layer, so a sheet inside an `overflow: hidden` box (a card, a panel, a
 * tab) does not cut them off (LY1-LY6).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiFocusTrap from '@ember-eui/core/components/eui-focus-trap';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  editorFrame,
  el,
  focusCell,
  press
} from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

interface Row {
  id: string;
  name: string;
  status: string | null;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  {
    id: 'status',
    label: 'Status',
    type: 'singleSelect',
    options: [
      { value: 'o', label: 'Open' },
      { value: 'p', label: 'Pending' },
      { value: 'c', label: 'Closed' },
      { value: 'x', label: 'Cancelled' },
      { value: 'h', label: 'On hold' }
    ]
  }
];

const getId = (row: Row) => row.id;
const rows = (): Row[] =>
  ['Ana', 'Beto', 'Caro', 'Dani', 'Eva'].map((name, i) => ({
    id: `r${i}`,
    name,
    status: 'o'
  }));

const LAST = 4;

const onFieldCreate = () => {};

const editorSel = '[data-test-subj=euiSheetFieldEditor]';

/** The box that clips: a card with `overflow: hidden`. */
function clip(): HTMLElement {
  return el('[data-test-clip]');
}

/**
 * Whether `element` is inside the viewport and is what is painted at its
 * centre (not cut off by the box, not covered).
 */
function reachable(element: HTMLElement): string | true {
  const box = element.getBoundingClientRect();
  const inView =
    box.top >= 0 &&
    box.left >= 0 &&
    box.bottom <= window.innerHeight &&
    box.right <= document.documentElement.clientWidth;
  if (!inView) return `outside the viewport: ${JSON.stringify(box)}`;
  const x = box.left + box.width / 2;
  const y = box.top + box.height / 2;
  const hit = document.elementFromPoint(x, y);
  if (!hit || !element.contains(hit)) {
    return `at (${x}, ${y}) the page paints ${hit?.outerHTML.slice(0, 120)}`;
  }
  return true;
}

/** The test container, fixed in the viewport for these tests. */
function container(): HTMLElement {
  return document.getElementById('ember-testing-container')!;
}

let containerStyle: string | null = null;

/**
 * Moves the test container (fixed) so that `element`'s top is `y` px from
 * the viewport's top: the layers are placed in the viewport, so the tests
 * put their anchors where they need them.
 */
function placeAt(element: HTMLElement, y: number): void {
  const box = container();
  if (containerStyle === null) containerStyle = box.getAttribute('style');
  if (box.style.position !== 'fixed') {
    box.style.position = 'fixed';
    box.style.left = '8px';
    box.style.top = '0px';
    box.style.bottom = 'auto';
  }
  const offset =
    element.getBoundingClientRect().top - box.getBoundingClientRect().top;
  box.style.top = `${y - offset}px`;
}

function restoreContainer(): void {
  if (containerStyle === null) return;
  const box = container();
  if (containerStyle) box.setAttribute('style', containerStyle);
  else box.removeAttribute('style');
  box.scrollTop = 0;
  containerStyle = null;
}

/**
 * Two frames: a layer is placed when it is inserted, and again in the next
 * frame when its size changed (its content laid out).
 */
async function frames(): Promise<void> {
  for (let i = 0; i < 2; i++) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await settled();
}

/** A right-click at a point of a cell: the press, then the contextmenu event. */
async function rightClick(element: HTMLElement): Promise<void> {
  const box = element.getBoundingClientRect();
  const point = { clientX: box.left + 5, clientY: box.top + 5 };
  await triggerEvent(element, 'mousedown', { button: 2, ...point });
  await triggerEvent(element, 'contextmenu', { button: 2, ...point });
  await frames();
}

function menu(): HTMLElement {
  return el('[data-test-subj=euiSheetRowMenu]');
}

function lastMenuItem(): HTMLElement {
  const items = menu().querySelectorAll<HTMLElement>(
    '[data-test-subj^=euiSheetRowMenu-]'
  );
  return items[items.length - 1]!;
}

async function openFieldEditor(): Promise<void> {
  await click(el('[data-test-subj=euiSheetAddField]'));
  await waitUntil(() => !!document.activeElement?.closest(editorSel), {
    timeout: 2000
  });
  await frames();
}

module('Integration | Component | EuiSheet layers', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    restoreContainer();
  });

  async function renderClipped(): Promise<void> {
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div
          data-test-clip
          style="overflow:hidden;height:260px;width:600px;border:1px solid"
        >
          <EuiSheet
            @fields={{FIELDS}}
            @records={{store.records}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @onFieldCreate={{onFieldCreate}}
            @height={{220}}
          />
        </div>
      </template>
    );
    placeAt(clip(), 8);
    await settled();
  }

  test('LY1 the field editor is not cut off by an overflow: hidden box; Save is reachable', async function (assert) {
    await renderClipped();
    await openFieldEditor();
    const editor = el(editorSel);
    const save = el('[data-test-subj=euiSheetFieldSave]');
    assert.false(clip().contains(editor), 'portaled out of the box');
    assert.true(
      save.getBoundingClientRect().bottom >
        clip().getBoundingClientRect().bottom,
      'Save is below the box (it would have been cut off)'
    );
    assert.strictEqual(reachable(save), true, 'Save is painted');
    assert.strictEqual(editor.dataset['placement'], 'below');
    const header = el(
      '[role=columnheader][data-gridcell-column-id="euiSheet-addField"]'
    ).getBoundingClientRect();
    assert.true(
      editor.getBoundingClientRect().top >= header.bottom - 1,
      'under its header'
    );
    await click(save);
    assert.dom(editorSel, document.body).exists('Save with no name keeps it');
    await press('Escape');
    assert.dom(editorSel, document.body).doesNotExist('Escape closes it');
  });

  test('LY2 the row menu on the last row is not cut off; its last item is reachable', async function (assert) {
    await renderClipped();
    await rightClick(cell(LAST, 0));
    const item = lastMenuItem();
    assert.false(clip().contains(menu()), 'portaled out of the box');
    assert.strictEqual(reachable(item), true, 'the last item is painted');
    await click(item);
    assert
      .dom('[data-test-subj=euiSheetRowMenu]', document.body)
      .doesNotExist('picking an item closes it');
  });

  test('LY3 the single-select panel on the last row is not cut off', async function (assert) {
    await renderClipped();
    await focusCell(LAST, 1);
    await press('Enter');
    await frames();
    const frame = editorFrame()!;
    assert.dom(frame).hasClass('euiSheet__editor--panel');
    assert.false(clip().contains(frame), 'portaled out of the box');
    const options = frame.querySelectorAll<HTMLElement>('[role=option]');
    assert.strictEqual(options.length, 5, 'every option is rendered');
    assert.strictEqual(
      reachable(options[options.length - 1]!),
      true,
      'the last option is painted'
    );
    const box = frame.getBoundingClientRect();
    const target = cell(LAST, 1).getBoundingClientRect();
    assert.true(box.top >= target.bottom - 1, 'below the cell');
    assert.true(
      Math.abs(box.left - target.left) <= 1,
      `aligned with it (${box.left}, ${target.left})`
    );
    assert.strictEqual(
      document.activeElement,
      frame.querySelector('input'),
      'the search has focus'
    );
    // the editor's keys still reach the sheet: Escape cancels
    await press('Escape');
    assert.strictEqual(editorFrame(), null, 'Escape closed it');
    assert.strictEqual(document.activeElement, cell(LAST, 1), 'focus back');
  });

  test('LY4 near the viewport bottom the layers flip above their anchor', async function (assert) {
    await renderClipped();
    // the last row 40 px above the viewport's bottom
    placeAt(cell(LAST, 0), window.innerHeight - 40);
    await settled();

    await rightClick(cell(LAST, 0));
    let anchor = cell(LAST, 0).getBoundingClientRect();
    assert.strictEqual(menu().dataset['placement'], 'above', 'the menu');
    assert.true(
      menu().getBoundingClientRect().bottom <= anchor.top + 5 + 1,
      `the menu ends at the pointer (${menu().getBoundingClientRect().bottom}, ${anchor.top + 5}, viewport ${window.innerHeight})`
    );
    assert.strictEqual(reachable(lastMenuItem()), true, 'its last item');
    await press('Escape');

    await focusCell(LAST, 1);
    await press('Enter');
    await frames();
    const frame = editorFrame()!;
    anchor = cell(LAST, 1).getBoundingClientRect();
    assert.strictEqual(frame.dataset['placement'], 'above', 'the panel');
    assert.true(
      frame.getBoundingClientRect().bottom <= anchor.top + 1,
      'the panel ends at the cell'
    );
    const options = frame.querySelectorAll<HTMLElement>('[role=option]');
    assert.strictEqual(reachable(options[0]!), true, 'its first option');
    await press('Escape');

    // the header 60 px above the viewport's bottom
    const header = el(
      '[role=columnheader][data-gridcell-column-id="euiSheet-addField"]'
    );
    placeAt(header, window.innerHeight - 60);
    await settled();
    await openFieldEditor();
    const editor = el(editorSel);
    assert.strictEqual(editor.dataset['placement'], 'above', 'the editor');
    assert.true(
      editor.getBoundingClientRect().bottom <=
        header.getBoundingClientRect().top + 1,
      'the editor ends above its header'
    );
    assert.strictEqual(
      reachable(el('[data-test-subj=euiSheetFieldSave]')),
      true,
      'Save is painted'
    );
  });

  test('LY5 a scroll of an ancestor moves an open layer with its anchor', async function (assert) {
    await renderClipped();
    await rightClick(cell(1, 0));
    const before = menu().getBoundingClientRect().top;
    const cellBefore = cell(1, 0).getBoundingClientRect().top;
    // the test container scrolls (overflow: auto), as a page or a panel would
    container().scrollTop += 20;
    await triggerEvent(container(), 'scroll');
    const moved = cellBefore - cell(1, 0).getBoundingClientRect().top;
    const after = menu().getBoundingClientRect().top;
    assert.true(moved > 0, `the cell moved (${moved} px)`);
    assert.true(
      Math.abs(before - moved - after) <= 1,
      `the menu moved with it (${before} -> ${after})`
    );
    assert.dom(menu()).exists('still open');
  });

  test('LY6 the layers carry the sheet theme class, also in dark mode', async function (assert) {
    await renderClipped();
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    const wrapper = el('[data-test-subj=euiSheet]');
    const plain = (element: Element) =>
      getComputedStyle(element).getPropertyValue('--euiSheet-plain').trim();
    await rightClick(cell(LAST, 0));
    const layer = menu().closest<HTMLElement>('[data-eui-sheet-layer]')!;
    assert.ok(layer, 'the menu is in a layer');
    const themeClass = Array.from(wrapper.classList).find((name) =>
      /euiSheetTheme/.test(name)
    );
    assert.ok(themeClass, `the wrapper's theme class (${wrapper.className})`);
    assert.true(layer.classList.contains(themeClass!), 'on the layer too');
    assert.strictEqual(plain(menu()), plain(wrapper), 'the same colours');
    await press('Escape');
    // the menu's close refocuses its cell a frame later: a person cannot
    // right-click again inside that frame, a test can
    await settled();
    await frames();
    // an override set on the sheet itself reaches the layer
    wrapper.style.setProperty('--euiSheet-selected', 'rgb(1, 2, 3)');
    await rightClick(cell(LAST, 0));
    assert.strictEqual(
      getComputedStyle(menu()).getPropertyValue('--euiSheet-selected').trim(),
      'rgb(1, 2, 3)',
      "the sheet's own override"
    );
  });

  test('LY7 inside a focus trap (a modal, an own-focus flyout) the layers keep focus', async function (assert) {
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <EuiFocusTrap>
          <div style="width:600px">
            <EuiSheet
              @fields={{FIELDS}}
              @records={{store.records}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
            />
          </div>
        </EuiFocusTrap>
      </template>
    );
    await focusCell(1, 1);
    await press('Enter');
    await frames();
    const frame = editorFrame()!;
    assert.ok(frame, 'the select panel is open');
    assert.true(
      frame.contains(document.activeElement),
      'focus stays in the panel'
    );
    await press('Escape');
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus back');
    await press('F10', { shiftKey: true });
    await frames();
    assert.true(
      menu().contains(document.activeElement),
      'focus is in the row menu'
    );
    await press('Escape');
    assert.strictEqual(document.activeElement, cell(1, 1), 'focus back');
  });
});
