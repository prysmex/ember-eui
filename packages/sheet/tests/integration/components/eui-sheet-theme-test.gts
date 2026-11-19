/**
 * Theme colours (V02-DESIGN.md 4.3): the wrapper's class defines the
 * `--euiSheet-*` custom properties from the resolved EUI theme, so the
 * sheet follows light and dark (TH1-TH4).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { sheetThemeVars } from '#src/-private/theme.ts';
import { cell, el, focusCell, type } from '../../helpers/sheet.ts';

import type { EuiSheetField } from '#src/core/index.ts';
import type { EuiSheetFieldType, SheetEditorSignature } from '#src/types.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';
import type { EuiThemeStyleContext } from '@ember-eui/core/theming';
import type Owner from '@ember/owner';

// the static CSS as text
const styleSources = import.meta.glob('../../../src/-private/styles.ts', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

interface Row {
  id: string;
  name: string;
  done: boolean;
}

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'name', label: 'Name' },
  { id: 'done', label: 'Done', type: 'checkbox' }
];
const rows = (): Row[] => [
  { id: 'r0', name: 'a', done: true },
  { id: 'r1', name: 'b', done: false }
];
const getId = (row: Row) => row.id;

/** `#rrggbb` → `rgb(r, g, b)`, as computed styles report it. */
function rgb(hex: string): string {
  const parts = /^#([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(hex);
  if (!parts) return hex;
  return `rgb(${parts
    .slice(1)
    .map((pair) => parseInt(pair, 16))
    .join(', ')})`;
}

function css(element: Element): CSSStyleDeclaration {
  return getComputedStyle(element);
}

let editorThemeClass: string | undefined;

class ThemeProbeEditor extends Component<SheetEditorSignature<string>> {
  constructor(owner: Owner, args: SheetEditorSignature<string>['Args']) {
    super(owner, args);
    editorThemeClass = args.themeClass;
  }
  <template><input aria-label="probe" data-test-probe /></template>
}

const FIELD_TYPES: Record<string, EuiSheetFieldType<any, any>> = {
  probe: {
    parse: (text: string) => ({ value: text }),
    format: (value: unknown) => (typeof value === 'string' ? value : ''),
    editor: ThemeProbeEditor
  }
};

module('Integration | Component | EuiSheet theme', function (hooks) {
  setupRenderingTest(hooks);

  test('TH1 the wrapper has an Emotion class and --euiSheet-primary is the theme’s primary', async function (assert) {
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    const wrapper = el('[data-test-subj=euiSheet]');
    const themeClass = Array.from(wrapper.classList).find((name) =>
      name.includes('euiSheetTheme')
    );
    assert.ok(themeClass, `an Emotion class (${wrapper.className})`);
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    const colors = emotion.context.upstream.euiTheme.colors;
    assert.strictEqual(
      css(wrapper).getPropertyValue('--euiSheet-primary').trim(),
      colors.primary
    );
    assert.strictEqual(
      css(el('.euiSheet__checkbox--checked', wrapper)).backgroundColor,
      rgb(colors.primary),
      'a checked checkbox uses it'
    );
  });

  test('TH2 in dark mode the selected cell and the input are dark', async function (assert) {
    // The sheet reads the nearest provider's theme, else the eui-emotion
    // service's. This test app does not run ember-provide-consume-context's
    // initializer (a real app does), so an <EuiEmotionProvider> here would not
    // be seen: the test switches the service's colour mode instead.
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    const wrapper = el('[data-test-subj=euiSheet]');
    const vars = () =>
      ['--euiSheet-selected', '--euiSheet-plain', '--euiSheet-text']
        .map((name) => css(wrapper).getPropertyValue(name).trim())
        .join(' ');
    await focusCell(0, 0);
    await type('x');
    const lightClass = wrapper.className;
    const lightVars = vars();
    const lightSelected = css(cell(0, 0)).backgroundColor;
    const lightInput = css(el('.euiSheet__input', wrapper)).backgroundColor;
    assert.dom(cell(0, 0)).hasClass('euiSheet__cell--selected');
    assert.strictEqual(
      lightInput,
      'rgb(255, 255, 255)',
      'light input is white'
    );

    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    assert.notStrictEqual(wrapper.className, lightClass, 'another theme class');
    assert.notStrictEqual(
      vars(),
      lightVars,
      `the colours follow the theme: light ${lightVars}; dark ${vars()}`
    );
    const darkSelected = css(cell(0, 0)).backgroundColor;
    assert.notStrictEqual(
      darkSelected,
      lightSelected,
      `selected: ${lightSelected} (light), ${darkSelected} (dark)`
    );
    const darkInput = css(el('.euiSheet__input', wrapper)).backgroundColor;
    assert.notStrictEqual(
      darkInput,
      'rgb(255, 255, 255)',
      `the dark input is not white (${darkInput})`
    );
  });

  test('TH3 styles.ts has no fixed colour outside a var(--euiSheet-*, fallback)', function (assert) {
    const source = Object.values(styleSources)[0];
    assert.ok(source, 'styles.ts read');
    const withoutVars = source!.replace(
      /var\(--euiSheet-\w+,\s*(?:rgba?\([^)]*\)|#[\da-f]+)\)/gi,
      'VAR'
    );
    assert.deepEqual(
      withoutVars.match(/#[\da-f]{3,8}\b|rgba?\(|hsla?\(/gi) ?? [],
      [],
      'no hex, rgb() or hsl() colour left'
    );
    // every property the CSS reads is defined by the theme class
    const anyColour = new Proxy({}, { get: () => '#000000' });
    const defined = Object.keys(
      sheetThemeVars({
        euiTheme: { colors: anyColour }
      } as unknown as EuiThemeStyleContext)
    );
    const used = new Set(source!.match(/--euiSheet-\w+/g));
    assert.true(used.size >= 10, `${used.size} properties used`);
    for (const name of used) {
      assert.true(defined.includes(name), `${name} is defined`);
    }
  });

  test('TH4 an editor gets the theme class as @themeClass', async function (assert) {
    editorThemeClass = undefined;
    const fields: EuiSheetField<Row>[] = [{ id: 'name', type: 'probe' }];
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:500px">
          <EuiSheet
            @records={{store.records}}
            @fields={{fields}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @fieldTypes={{FIELD_TYPES}}
          />
        </div>
      </template>
    );
    await focusCell(0, 0);
    await type('x');
    assert.dom('[data-test-probe]').exists();
    assert.ok(editorThemeClass, 'passed');
    assert.dom('[data-test-subj=euiSheet]').hasClass(editorThemeClass!);
  });

  test('TH5 a --euiSheet-* property set on the sheet element overrides the theme', async function (assert) {
    const store = localRecords(rows(), { getRecordId: getId });
    await render(
      <template>
        <div style="width:500px; --euiSheet-primary: rgb(1, 2, 3)">
          <EuiSheet
            style="--euiSheet-selected: rgb(4, 5, 6)"
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
          />
        </div>
      </template>
    );
    await focusCell(0, 0);
    // the first field is frozen (v0.2 C7): its selection is drawn as an
    // image over its opaque background
    assert.strictEqual(
      css(cell(0, 0)).backgroundImage,
      'linear-gradient(rgb(4, 5, 6), rgb(4, 5, 6))',
      'on the sheet element: applies'
    );
    assert.notStrictEqual(
      css(el('.euiSheet__checkbox--checked')).backgroundColor,
      'rgb(1, 2, 3)',
      'on a parent: the wrapper class wins'
    );
  });
});
