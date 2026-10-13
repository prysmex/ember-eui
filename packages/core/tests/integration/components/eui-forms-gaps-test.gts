import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  focus,
  render,
  rerender,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { array, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

import EuiAccordion from '#src/components/eui-accordion.gts';
import EuiButtonIcon from '#src/components/eui-button-icon.gts';
import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiColorPalettePicker from '#src/components/eui-color-palette-picker.gts';
import EuiConfirmModal from '#src/components/eui-confirm-modal.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiInlineEditText from '#src/components/eui-inline-edit-text.gts';
import EuiInlineEditTitle from '#src/components/eui-inline-edit-title.gts';
import EuiInputPopover from '#src/components/eui-input-popover.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiResizableButton from '#src/components/eui-resizable-container/button.gts';
import EuiResizableContainer from '#src/components/eui-resizable-container.gts';
import EuiSuperSelect from '#src/components/eui-super-select.gts';
import {
  euiPaletteGreen,
  euiPaletteOrange,
  euiPaletteRed,
  euiPaletteSkyBlue,
  euiPaletteYellow
} from '#src/utils/color/index.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { TOC } from '@ember/component/template-only';
import type { EuiColorPalettePickerPalette } from '#src/components/eui-color-palette-picker.gts';
import type { EuiCssFunction } from '#src/utils/eui/styles.ts';

const light = resolveBorealisTheme('light').euiTheme;
const noop = () => {};

function q<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

// Output of @elastic/eui 123.1.0's euiPalette*(steps) with the Borealis light vis colors,
// for 1, 2, 3, 5 and 10 steps.
const UPSTREAM_PALETTES: Record<string, string[][]> = {
  "Red": [
    [
      "#FFC9C2"
    ],
    [
      "#feb7b0",
      "#f6726a"
    ],
    [
      "#fdcdc9",
      "#fda198",
      "#f6726a"
    ],
    [
      "#fcdfdd",
      "#fec4bf",
      "#feaaa2",
      "#fb8f86",
      "#f6726a"
    ],
    [
      "#f9eced",
      "#fcdfdd",
      "#fdd2ce",
      "#fec4bf",
      "#feb7b0",
      "#feaaa2",
      "#fc9c94",
      "#fb8f86",
      "#f98178",
      "#f6726a"
    ]
  ],
  "Green": [
    [
      "#AEE8D2"
    ],
    [
      "#9fdfc6",
      "#24c292"
    ],
    [
      "#bde8d8",
      "#7fd5b4",
      "#24c292"
    ],
    [
      "#d4efe6",
      "#b1e4d1",
      "#8cd9bb",
      "#62cea6",
      "#24c292"
    ],
    [
      "#e5f4f1",
      "#d4efe6",
      "#c3eadb",
      "#b1e4d1",
      "#9fdfc6",
      "#8cd9bb",
      "#78d4b1",
      "#62cea6",
      "#49c89c",
      "#24c292"
    ]
  ],
  "SkyBlue": [
    [
      "#B5E5F2"
    ],
    [
      "#a6d8ec",
      "#37b8dc"
    ],
    [
      "#c2e3f1",
      "#89cee7",
      "#37b8dc"
    ],
    [
      "#d7ecf6",
      "#b7dfef",
      "#95d2e9",
      "#6ec5e2",
      "#37b8dc"
    ],
    [
      "#e7f2f9",
      "#d7ecf6",
      "#c7e5f2",
      "#b7dfef",
      "#a6d8ec",
      "#95d2e9",
      "#82cbe6",
      "#6ec5e2",
      "#56bedf",
      "#37b8dc"
    ]
  ],
  "Yellow": [
    [
      "#FCD883"
    ],
    [
      "#f9d290",
      "#eaae01"
    ],
    [
      "#fadfb4",
      "#f6c66c",
      "#eaae01"
    ],
    [
      "#fae9d1",
      "#fadaa6",
      "#f7cb7a",
      "#f2bc4d",
      "#eaae01"
    ],
    [
      "#f8f1e6",
      "#fae9d1",
      "#fae2bb",
      "#fadaa6",
      "#f9d290",
      "#f7cb7a",
      "#f5c464",
      "#f2bc4d",
      "#eeb532",
      "#eaae01"
    ]
  ],
  "Orange": [
    [
      "#FFCDA1"
    ],
    [
      "#ffc1a1",
      "#fc8544"
    ],
    [
      "#ffd3be",
      "#ffae83",
      "#fc8544"
    ],
    [
      "#fee2d6",
      "#ffccb2",
      "#ffb58f",
      "#ff9d6a",
      "#fc8544"
    ],
    [
      "#fbede9",
      "#fee2d6",
      "#ffd7c4",
      "#ffccb2",
      "#ffc1a1",
      "#ffb58f",
      "#ffaa7c",
      "#ff9d6a",
      "#ff9156",
      "#fc8544"
    ]
  ]
};

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

module('Integration | Component | forms and containers: upstream gaps', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiCheckbox readOnly', function () {
    test('is read-only: native readonly, default cursor, clicks do not toggle', async function (assert) {
      const changes: boolean[] = [];
      const onChange = (event: Event) => changes.push((event.target as HTMLInputElement).checked);

      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiCheckbox @id="ro-on" @checked={{true}} @readOnly={{true}} @label="On" {{on "change" onChange}} />
            <EuiCheckbox @id="ro-off" @checked={{false}} @readOnly={{true}} @label="Off" {{on "change" onChange}} />
            <EuiCheckbox @id="rw" @checked={{false}} @label="Editable" />
          </EuiEmotionProvider>
        </template>
      );

      assert.dom('#ro-on').hasAttribute('readonly');
      assert.dom('#rw').doesNotHaveAttribute('readonly');
      assert.strictEqual(getComputedStyle(q('label[for="ro-on"]')).cursor, 'default');
      assert.strictEqual(getComputedStyle(q('label[for="rw"]')).cursor, 'pointer');
      assert.strictEqual(getComputedStyle(q('#ro-on')).cursor, 'default');

      await click('label[for="ro-on"]');
      await click('#ro-off');
      assert.dom('#ro-on').isChecked('stays checked');
      assert.dom('#ro-off').isNotChecked('stays unchecked');
      assert.deepEqual(changes, [], 'no change events');

      await click('label[for="rw"]');
      assert.dom('#rw').isChecked('an editable checkbox still toggles');
    });

    test('focus keeps the unselected border colour while read-only', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiCheckbox @id="ro" @readOnly={{true}} @label="Off" />
            <EuiCheckbox @id="rw" @label="Off" />
          </EuiEmotionProvider>
        </template>
      );

      const square = (id: string) => q(`#${id}`).closest('.euiCheckbox__square')!;

      await focus('#rw');
      const editable = getComputedStyle(square('rw')).borderColor;
      await focus('#ro');
      const readOnly = getComputedStyle(square('ro')).borderColor;

      assert.notStrictEqual(readOnly, editable, 'the read-only square does not take the focus border');
    });

    test('readOnly can be toggled', async function (assert) {
      const state = new (class {
        @tracked readOnly = true;
      })();

      await render(<template><EuiCheckbox @id="c" @readOnly={{state.readOnly}} @label="L" /></template>);
      await click('#c');
      assert.dom('#c').isNotChecked();

      state.readOnly = false;
      await rerender();
      assert.dom('#c').doesNotHaveAttribute('readonly');
      await click('#c');
      assert.dom('#c').isChecked();
    });
  });

  module('palettes', function () {
    const vis = light.colors.vis as unknown as Record<string, string>;

    test('Red, Green, SkyBlue, Yellow and Orange use the Borealis vis colors', function (assert) {
      const cases: [string, (steps: number) => string[], string, string][] = [
        ['Red', euiPaletteRed, 'Danger0', 'Danger1'],
        ['Green', euiPaletteGreen, 'Success0', 'Success1'],
        ['SkyBlue', euiPaletteSkyBlue, 'Neutral0', 'Neutral1'],
        ['Yellow', euiPaletteYellow, 'Warning0', 'Warning1'],
        ['Orange', euiPaletteOrange, 'Risk0', 'Risk1']
      ];

      for (const [name, palette, dark, single] of cases) {
        assert.deepEqual(palette(1), [vis[`euiColorVis${single}`]], `${name}: one step is the mid colour`);
        const five = palette(5);
        assert.strictEqual(five.length, 5, `${name}: steps`);
        assert.strictEqual(five.at(-1)!.toLowerCase(), vis[`euiColorVis${dark}`]!.toLowerCase(), `${name}: ends on the dark colour`);
        assert.true(five.every((color) => /^#[0-9a-f]{6}$/i.test(color)), `${name}: hex colours`);
      }
    });

    test('match the upstream 123.1.0 palettes', function (assert) {
      const fns = { Red: euiPaletteRed, Green: euiPaletteGreen, SkyBlue: euiPaletteSkyBlue, Yellow: euiPaletteYellow, Orange: euiPaletteOrange };

      for (const [name, fn] of Object.entries(fns)) {
        [1, 2, 3, 5, 10].forEach((steps, index) => {
          assert.deepEqual(
            fn(steps).map((color) => color.toLowerCase()),
            UPSTREAM_PALETTES[name]![index]!.map((color) => color.toLowerCase()),
            `${name} ${steps}`
          );
        });
      }
    });

    test('colors overrides the vis colors', function (assert) {
      const colors = { euiColorVisBase0: '#ffffff', euiColorVisDanger0: '#000000', euiColorVisDanger1: '#123456' };

      assert.deepEqual(euiPaletteRed(1, { colors }), ['#123456']);
      assert.strictEqual(euiPaletteRed(3, { colors }).at(-1), '#000000');
    });
  });

  module('EuiColorPalettePicker palette append', function () {
    test('append (text or component) is shown beside the title in the list, not for text options', async function (assert) {
      const Badge = <template><span class="my-badge">New</span></template> as TOC<{ Args: {} }>;
      const palettes: EuiColorPalettePickerPalette[] = [
        { value: 'a', title: 'A', type: 'fixed', palette: ['#111111', '#222222'], append: 'beta' },
        { value: 'b', title: 'B', type: 'gradient', palette: ['#333333', '#444444'], append: Badge },
        { value: 'c', title: 'C', type: 'text', append: 'ignored' }
      ];

      await render(<template><EuiColorPalettePicker @palettes={{palettes}} @valueOfSelected="a" @onChange={{noop}} /></template>);
      await click('button.euiSuperSelectControl');
      await waitUntil(() => document.querySelector('.euiColorPalettePicker__item'));

      const items = document.querySelectorAll('.euiColorPalettePicker__item');

      assert.dom('.euiFlexItem:last-child', items[0]).hasText('beta');
      assert.dom('.my-badge', items[1]).hasText('New');
      assert.dom('.euiFlexItem', items[2]).doesNotExist('text options have no title row');
      assert.strictEqual(items[2]!.textContent!.trim(), 'C');
    });
  });

  module('EuiInputPopover closeOnScroll', function () {
    class State {
      @tracked isOpen = true;
      close = () => (this.isOpen = false);
    }

    test('closes when a container of the input scrolls, after a grace period', async function (assert) {
      const state = new State();

      await render(
        <template>
          <div class="scroller" style="height: 100px; overflow: auto;">
            <div style="height: 600px;">
              <EuiInputPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @closeOnScroll={{true}} @disableFocusTrap={{true}}>
                <:input><input class="field" /></:input>
                <:content><div class="panel-content" style="height: 40px; overflow: auto;"><div style="height: 300px;">x</div></div></:content>
              </EuiInputPopover>
            </div>
          </div>
        </template>
      );
      await waitUntil(() => document.querySelector('.panel-content'));
      await sleep(600);

      // scrolling the panel itself is ignored
      const panel = q('.panel-content');
      panel.scrollTop = 20;
      await sleep(100);
      assert.true(state.isOpen, 'scrolling the popover does not close it');

      q('.scroller').scrollTop = 50;
      await waitUntil(() => !state.isOpen, { timeout: 2000 });
      assert.false(state.isOpen, 'scrolling the container closes it');
    });

    test('does not close without closeOnScroll, nor while the grace period runs', async function (assert) {
      const off = new State();
      const early = new State();

      await render(
        <template>
          <div class="scroller-off" style="height: 100px; overflow: auto;">
            <div style="height: 600px;">
              <EuiInputPopover @isOpen={{off.isOpen}} @closePopover={{off.close}} @disableFocusTrap={{true}}>
                <:input><input /></:input>
                <:content><div class="off-content">x</div></:content>
              </EuiInputPopover>
            </div>
          </div>
        </template>
      );
      await waitUntil(() => document.querySelector('.off-content'));
      await sleep(600);
      q('.scroller-off').scrollTop = 50;
      await sleep(200);
      assert.true(off.isOpen, 'off by default');

      await render(
        <template>
          <div class="scroller-early" style="height: 100px; overflow: auto;">
            <div style="height: 600px;">
              <EuiInputPopover @isOpen={{early.isOpen}} @closePopover={{early.close}} @closeOnScroll={{true}} @disableFocusTrap={{true}}>
                <:input><input /></:input>
                <:content><div class="early-content">x</div></:content>
              </EuiInputPopover>
            </div>
          </div>
        </template>
      );
      await waitUntil(() => document.querySelector('.early-content'));
      q('.scroller-early').scrollTop = 50;
      await sleep(100);
      assert.true(early.isOpen, 'scroll events right after opening are ignored');
    });
  });

  module('EuiInlineEdit readModeProps and inputProps', function () {
    test('readModeProps color and iconSide', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiInlineEditText @inputAriaLabel="d" @defaultValue="Default" class="d" />
            <EuiInlineEditText @inputAriaLabel="c" @defaultValue="Custom" class="c" @readModeProps={{hash color="primary" iconSide="left"}} />
            <EuiInlineEditTitle @inputAriaLabel="t" @defaultValue="Title" @heading="h3" class="t" @readModeProps={{hash iconSide="left"}} />
          </EuiEmotionProvider>
        </template>
      );

      const button = (root: string) => q<HTMLElement>(`${root} [data-test-subj="euiInlineReadModeButton"]`);
      const direction = (root: string) =>
        getComputedStyle(q(`${root} [data-test-subj="euiInlineReadModeButton"] .euiButtonContent`)).flexDirection;

      assert.notStrictEqual(getComputedStyle(button('.c')).color, getComputedStyle(button('.d')).color, 'colour');
      assert.strictEqual(direction('.d'), 'row-reverse', 'icon on the right by default');
      assert.strictEqual(direction('.c'), 'row', 'icon on the left');
      assert.strictEqual(direction('.t'), 'row', 'also for EuiInlineEditTitle');
    });

    test('inputProps prepend and append (text or component) and readOnly', async function (assert) {
      const Unit = <template><span class="unit">kg</span></template> as TOC<{ Args: {} }>;
      const props = { prepend: 'Weight', append: Unit, readOnly: true };
      const none = { readOnly: false };

      await render(
        <template>
          <EuiInlineEditText @inputAriaLabel="a" @defaultValue="1" @startWithEditOpen={{true}} @editModeProps={{hash inputProps=props}} class="with" />
          <EuiInlineEditText @inputAriaLabel="b" @defaultValue="2" @startWithEditOpen={{true}} @editModeProps={{hash inputProps=none}} class="without" />
        </template>
      );

      assert.dom('.with .euiFormControlLayout__prepend').hasText('Weight');
      assert.dom('.with .euiFormControlLayout__prepend label.euiFormLabel').hasAttribute('for', q('.with input').id);
      assert.dom('.with .euiFormControlLayout__append .unit').hasText('kg');
      assert.dom('.with input').hasAttribute('readonly');
      assert.dom('.without .euiFormControlLayout__prepend').doesNotExist();
      assert.dom('.without .euiFormControlLayout__append').doesNotExist();
      assert.dom('.without input').doesNotHaveAttribute('readonly');

      await fillIn('.without input', 'edited');
      assert.dom('.without input').hasValue('edited');
    });
  });

  module('EuiModal focusTrapProps.returnFocus', function () {
    class State {
      @tracked isOpen = false;
      @tracked returnFocus: boolean | ((el: Element) => boolean) | undefined = false;
      open = () => (this.isOpen = true);
      close = () => (this.isOpen = false);
    }

    test('false keeps focus where the app puts it; the default returns it to the opener', async function (assert) {
      const state = new State();

      await render(
        <template>
          <button type="button" class="opener" {{on "click" state.open}}>Open</button>
          {{#if state.isOpen}}
            <EuiModal @focusTrapProps={{hash returnFocus=state.returnFocus}} @onClose={{state.close}}>
              <button type="button">Inside</button>
            </EuiModal>
          {{/if}}
        </template>
      );

      await click('.opener');
      assert.true(q('.euiModal').contains(document.activeElement));
      await triggerKeyEvent(q('.euiModal'), 'keydown', 'Escape');
      assert.notStrictEqual(document.activeElement, q('.opener'), 'focus is not returned');

      state.returnFocus = undefined;
      await click('.opener');
      await triggerKeyEvent(q('.euiModal'), 'keydown', 'Escape');
      await waitUntil(() => document.activeElement === q('.opener'));
      assert.strictEqual(document.activeElement, q('.opener'), 'focus is returned by default');
    });

    test('a function receives the element to return to and can opt out', async function (assert) {
      const state = new State();
      const received: Element[] = [];

      state.returnFocus = (element: Element) => {
        received.push(element);
        return false;
      };

      await render(
        <template>
          <button type="button" class="opener" {{on "click" state.open}}>Open</button>
          {{#if state.isOpen}}
            <EuiModal @focusTrapProps={{hash returnFocus=state.returnFocus}} @onClose={{state.close}}>
              <button type="button">Inside</button>
            </EuiModal>
          {{/if}}
        </template>
      );

      await click('.opener');
      await triggerKeyEvent(q('.euiModal'), 'keydown', 'Escape');
      assert.deepEqual(received, [q('.opener')], 'called with the opener');
      assert.notStrictEqual(document.activeElement, q('.opener'));
    });

    test('EuiConfirmModal passes focusTrapProps on', async function (assert) {
      const state = new State();

      await render(
        <template>
          <button type="button" class="opener" {{on "click" state.open}}>Open</button>
          {{#if state.isOpen}}
            <EuiConfirmModal
              @title="T"
              @cancelButtonText="Cancel"
              @confirmButtonText="OK"
              @focusTrapProps={{hash returnFocus=false}}
              @onCancel={{state.close}}
              @onConfirm={{state.close}}
            />
          {{/if}}
        </template>
      );

      await click('.opener');
      await click(q('[data-test-subj="confirmModalCancelButton"]'));
      assert.notStrictEqual(document.activeElement, q('.opener'));
    });
  });

  module('EuiConfirmModal titleProps', function () {
    test('className, id and data-test-subj go on the title', async function (assert) {
      await render(
        <template>
          <EuiConfirmModal
            @title="Delete?"
            @titleProps={{hash className="my-title" id="my-title-id" data-test-subj="myTitle"}}
            @cancelButtonText="Cancel"
            @confirmButtonText="Delete"
            @onCancel={{noop}}
            @onConfirm={{noop}}
          />
          <EuiConfirmModal
            @title="Plain"
            @cancelButtonText="Cancel"
            @confirmButtonText="Delete"
            @onCancel={{noop}}
            @onConfirm={{noop}}
          />
        </template>
      );

      const titles = document.querySelectorAll('.euiModalHeader__title');

      assert.dom(titles[0]).hasClass('my-title').hasClass('euiModalHeader__title').hasAttribute('id', 'my-title-id').hasAttribute('data-test-subj', 'myTitle').hasText('Delete?');
      assert.dom(titles[1]).hasAttribute('data-test-subj', 'confirmModalTitleText', 'the default test subject stays');
      assert.dom(titles[1]).doesNotHaveClass('my-title');
    });
  });

  module('EuiSuperSelect popoverProps', function () {
    const options = [
      { value: 'a', inputDisplay: 'Option A' },
      { value: 'b', inputDisplay: 'Option B' }
    ];

    test('are applied to the input popover', async function (assert) {
      const popoverProps = {
        className: 'my-popover',
        panelClassName: 'my-panel',
        panelStyle: { backgroundColor: 'rgb(1, 2, 3)' },
        repositionOnScroll: true,
        ariaLabel: 'My list'
      };

      await render(
        <template>
          <EuiSuperSelect @options={{options}} @valueOfSelected="a" @onChange={{noop}} @popoverProps={{popoverProps}} />
          <EuiSuperSelect @options={{options}} @valueOfSelected="a" @onChange={{noop}} class="plain" />
        </template>
      );

      assert.dom('.euiSuperSelect.my-popover').exists();
      assert.dom('.euiSuperSelect').exists({ count: 2 });

      await click('.euiSuperSelect.my-popover button.euiSuperSelectControl');
      await waitUntil(() => document.querySelector('.euiSuperSelect__listbox'));

      const panel = q('.my-panel');
      assert.dom(panel).hasClass('euiPopover__panel');
      assert.strictEqual(getComputedStyle(panel).backgroundColor, 'rgb(1, 2, 3)', 'panelStyle');
      assert.dom('.euiSuperSelect__listbox', panel).exists('the list is inside');
      assert.dom(panel).hasAttribute('aria-label', 'My list');
    });

    test('closePopover and isOpen are kept; popoverProps.panelPaddingSize overrides the default', async function (assert) {
      const popoverProps = { panelPaddingSize: 'l' as const };

      await render(
        <template>
          <EuiSuperSelect @options={{options}} @valueOfSelected="a" @onChange={{noop}} @popoverProps={{popoverProps}} class="padded" />
        </template>
      );
      await click('.padded');
      await waitUntil(() => document.querySelector('.euiSuperSelect__listbox'));
      assert.notStrictEqual(getComputedStyle(q('.euiPopover__panel')).paddingInlineStart, '0px', 'padded panel');

      await triggerKeyEvent(q('.euiSuperSelect__item'), 'keydown', 'Escape');
      await waitUntil(() => !document.querySelector('.euiSuperSelect__listbox'));
      assert.dom('.euiSuperSelect__listbox').doesNotExist('Escape still closes it');
    });
  });

  module('EuiResizablePanel mode options', function () {
    test('className and data-test-subj go on the collapse toggle', async function (assert) {
      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer as |c|>
              <c.Panel @id="side" @initialSize={{30}} @mode={{array "collapsible" (hash position="top" className="my-toggle" data-test-subj="sideToggle")}}>Side</c.Panel>
              <c.Button />
              <c.Panel @id="main" @initialSize={{70}} @mode="main">Main</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );

      assert.dom('[data-test-subj="sideToggle"]').exists({ count: 1 }).hasClass('my-toggle').hasClass('euiResizableCollapseButton');
      assert.dom('.euiResizableCollapseButton').exists({ count: 1 });
    });

    test('without options the toggle is unchanged', async function (assert) {
      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer as |c|>
              <c.Panel @id="side" @initialSize={{30}} @mode={{array "collapsible" (hash position="bottom")}}>Side</c.Panel>
              <c.Button />
              <c.Panel @id="main" @initialSize={{70}} @mode="main">Main</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );

      assert.dom('.euiResizableCollapseButton').exists({ count: 1 }).doesNotHaveAttribute('data-test-subj');
    });
  });

  module('EuiResizableButton standalone', function () {
    test('renders without a container; your own events drive it', async function (assert) {
      const events: string[] = [];
      const record = (name: string) => (event: Event) => {
        events.push(name);
        if (event.type === 'keydown') event.preventDefault();
      };
      const down = record('mousedown');
      const touch = record('touchstart');
      const key = record('keydown');

      await render(
        <template>
          <EuiResizableButton @isHorizontal={{true}} class="h" {{on "mousedown" down}} {{on "touchstart" touch}} {{on "keydown" key}} />
          <EuiResizableButton class="v" />
        </template>
      );

      assert.dom('.h').hasClass('euiResizableButton').hasAttribute('data-test-subj', 'euiResizableButton').hasAria('label', 'Press the left or right arrow keys to adjust panels size');
      assert.dom('.v').hasAria('label', 'Press the up or down arrow keys to adjust panels size');
      assert.strictEqual(getComputedStyle(q('.h')).cursor, 'col-resize');
      assert.strictEqual(getComputedStyle(q('.v')).cursor, 'row-resize');

      q('.h').dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
      q('.h').dispatchEvent(new Event('touchstart', { bubbles: true }));
      await triggerKeyEvent('.h', 'keydown', 'ArrowRight');
      assert.deepEqual(events, ['mousedown', 'touchstart', 'keydown']);
    });

    test('upstream "Custom resize logic" example', async function (assert) {
      const MIN = 20;
      const state = new (class {
        @tracked width = 200;
        get style() {
          return { width: `${this.width}px` };
        }
        startX = 0;
        startWidth = 200;
        onMove = (event: MouseEvent) => {
          this.width = Math.max(this.startWidth + event.pageX - this.startX, MIN);
        };
        onUp = () => {
          window.removeEventListener('mousemove', this.onMove);
          window.removeEventListener('mouseup', this.onUp);
        };
        onDown = (event: MouseEvent) => {
          this.startX = event.pageX;
          this.startWidth = this.width;
          window.addEventListener('mousemove', this.onMove);
          window.addEventListener('mouseup', this.onUp);
        };
        onKey = (event: KeyboardEvent) => {
          if (event.key === 'ArrowRight') {
            event.preventDefault();
            this.width += 10;
          } else if (event.key === 'ArrowLeft') {
            event.preventDefault();
            this.width = Math.max(this.width - 10, MIN);
          }
        };
      })();

      await render(
        <template>
          <div class="box" style="display: flex; justify-content: flex-end; height: 100px; position: relative;" {{style state.style}}>
            <EuiResizableButton @isHorizontal={{true}} {{on "mousedown" state.onDown}} {{on "keydown" state.onKey}} />
          </div>
        </template>
      );

      await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowRight');
      assert.strictEqual(q('.box').offsetWidth, 210);
      await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowLeft');
      await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowLeft');
      assert.strictEqual(q('.box').offsetWidth, 190);

      q('.euiResizableButton').dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: 100 }));
      window.dispatchEvent(new MouseEvent('mousemove', { clientX: 150 }));
      await settled();
      assert.strictEqual(q('.box').offsetWidth, 240, 'dragging 50px');
      window.dispatchEvent(new MouseEvent('mouseup'));
    });

    test('inside a container it still resizes the panels', async function (assert) {
      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer as |c|>
              <c.Panel @id="a" @initialSize={{50}}>A</c.Panel>
              <c.Button />
              <c.Panel @id="b" @initialSize={{50}}>B</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );

      const before = q('#a').getBoundingClientRect().width;
      await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowRight');
      assert.strictEqual(Math.round(q('#a').getBoundingClientRect().width - before), 10);
    });
  });

  module('EuiAccordion hover-only extra action', function () {
    // upstream's example: an `@css` theme function on the extra action
    const hoverOnly: EuiCssFunction = ({ euiTheme }) => ({
      opacity: 0,
      '&:focus, .euiAccordion:hover &': { opacity: 1 },
      '@media (prefers-reduced-motion: no-preference)': {
        transition: `opacity ${euiTheme.animation.normal} ${euiTheme.animation.resistance}`
      }
    });

    test('the extra action is hidden until focused (or the accordion is hovered)', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiAccordion @id="acc" @extraAction={{true}} @buttonContent="Webhook">
              <:content>content</:content>
              <:extraAction>
                <EuiButtonIcon @iconType="cross" @color="danger" @css={{hoverOnly}} aria-label="Delete" />
              </:extraAction>
            </EuiAccordion>
          </EuiEmotionProvider>
        </template>
      );

      const button = q('[aria-label="Delete"]');
      assert.strictEqual(getComputedStyle(button).opacity, '0', 'hidden');
      await focus(button);
      await sleep(400);
      assert.strictEqual(getComputedStyle(button).opacity, '1', 'visible on focus');
    });
  });
});
