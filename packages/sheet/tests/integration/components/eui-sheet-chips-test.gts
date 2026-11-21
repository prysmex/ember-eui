/**
 * The chips in select, multi-select and linked-record cells (READINESS.md,
 * Performance, step 1): a span with EuiBadge's DOM, classes and `title`,
 * without EuiBadge (CHP1-CHP5).
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled } from '@ember/test-helpers';

import EuiBadge from '@ember-eui/core/components/eui-badge';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import { chipTitle } from '#src/-private/cells/chip.gts';
import { cell, el } from '../../helpers/sheet.ts';

import type { EuiSheetField, SheetOption } from '#src/core/index.ts';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';

interface Row {
  id: string;
  status: string | null;
  tags: string[];
  links: Array<{ id: string; label: string }>;
}

const OPTIONS: SheetOption[] = [
  { value: 'open', label: 'Open' },
  { value: 'done', label: 'Done', color: 'success' },
  { value: 'late', label: 'Late', color: 'danger' },
  { value: 'custom', label: 'Custom', color: '#DA8B45' },
  { value: 'spaced', label: '  Two   words\tand a tab ', color: 'primary' }
];

const FIELDS: EuiSheetField<Row>[] = [
  { id: 'status', type: 'singleSelect', options: OPTIONS },
  { id: 'tags', type: 'multiSelect', options: OPTIONS, width: 400 },
  { id: 'links', type: 'linkedRecord', search: () => [], width: 300 }
];

const getId = (row: Row) => row.id;

const ROWS: Row[] = [
  {
    id: 'r0',
    status: 'open',
    tags: ['done', 'custom', 'unknown'],
    links: [{ id: 'p1', label: 'Ana Ruiz' }]
  },
  {
    id: 'r1',
    status: 'custom',
    tags: ['late', 'spaced'],
    links: [{ id: 'p2', label: 'Bruno  Vela' }]
  },
  { id: 'r2', status: 'spaced', tags: [], links: [] }
];

/** A chip's DOM: its classes, title and the classes of its two inner spans. */
function shape(chip: Element): {
  tag: string;
  cls: string;
  title: string | null;
  inner: string[];
  text: string;
} {
  return {
    tag: chip.tagName,
    cls: chip.className,
    title: chip.getAttribute('title'),
    inner: Array.from(chip.querySelectorAll('span')).map((s) => s.className),
    text: (chip as HTMLElement).innerText
  };
}

function chips(row: number, col: number): Element[] {
  return Array.from(
    cell(row, col).querySelectorAll('[data-test-subj=euiSheetChip]')
  );
}

/** `<EuiBadge @color=… data-test-subj="ref">text</EuiBadge>` for each pair, outside the sheet. */
function badges(): Element[] {
  return Array.from(
    document.querySelectorAll('[data-test-ref] [data-test-subj=ref]')
  );
}

const REFS: Array<{ color: string; text: string }> = [
  { color: 'hollow', text: 'Open' },
  { color: 'success', text: 'Done' },
  { color: '#DA8B45', text: 'Custom' },
  { color: 'hollow', text: 'unknown' },
  { color: 'hollow', text: 'Ana Ruiz' },
  { color: '#DA8B45', text: 'Custom' },
  { color: 'danger', text: 'Late' },
  { color: 'primary', text: '  Two   words\tand a tab ' },
  { color: 'hollow', text: 'Bruno  Vela' },
  { color: 'primary', text: '  Two   words\tand a tab ' }
];

async function renderWithRefs(): Promise<void> {
  const store = localRecords(ROWS, { getRecordId: getId });
  await render(
    <template>
      <div style="width:1200px">
        <EuiSheet
          @records={{store.records}}
          @fields={{FIELDS}}
          @getRecordId={{getId}}
          @onChange={{store.apply}}
        />
      </div>
      <div data-test-ref>
        {{#each REFS as |ref|}}
          <EuiBadge
            @color={{ref.color}}
            data-test-subj="ref"
          >{{ref.text}}</EuiBadge>
        {{/each}}
      </div>
    </template>
  );
}

/** The chips in the order of REFS: row 0 (select, tags, links), row 1, row 2's select. */
function sheetChips(): Element[] {
  return [
    ...chips(0, 0),
    ...chips(0, 1),
    ...chips(0, 2),
    ...chips(1, 0),
    ...chips(1, 1),
    ...chips(1, 2),
    ...chips(2, 0)
  ];
}

module('Integration | Component | EuiSheet chips', function (hooks) {
  setupRenderingTest(hooks);

  test('CHP1 each chip has the DOM, classes and title EuiBadge renders for the same colour and text', async function (assert) {
    await renderWithRefs();
    const ours = sheetChips();
    const refs = badges();
    assert.strictEqual(ours.length, REFS.length, 'one chip per reference');
    assert.strictEqual(refs.length, REFS.length);
    ours.forEach((chip, i) => {
      assert.deepEqual(
        shape(chip),
        shape(refs[i]!),
        `chip ${i} (${REFS[i]!.color}, ${JSON.stringify(REFS[i]!.text)})`
      );
    });
  });

  test('CHP2 the title is the text as innerText reads it, from the first render', async function (assert) {
    await renderWithRefs();
    const spaced = el('[data-test-subj=euiSheetChip]', cell(2, 0));
    assert.strictEqual(spaced.getAttribute('title'), 'Two words and a tab');
    assert.strictEqual(
      el('[data-test-subj=euiSheetChip]', cell(1, 2)).getAttribute('title'),
      'Bruno Vela'
    );
    assert.strictEqual(
      chipTitle(' a  b '),
      ' a  b',
      'NBSP kept, as innerText keeps it'
    );
    assert.strictEqual(chipTitle(''), '');
  });

  test('CHP3 the chips follow the theme: the dark classes are the dark EuiBadge’s', async function (assert) {
    await renderWithRefs();
    const lightClass = sheetChips()[1]!.className;
    const emotion = this.owner.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService;
    emotion.colorMode = 'dark';
    await settled();
    const ours = sheetChips();
    const refs = badges();
    assert.notStrictEqual(ours[1]!.className, lightClass, 'another class');
    ours.forEach((chip, i) => {
      assert.strictEqual(chip.className, refs[i]!.className, `chip ${i}`);
    });
  });

  test('CHP4 the chip is not EuiBadge: no MutationObserver-driven title, a plain span with the badge spans', async function (assert) {
    await renderWithRefs();
    const chip = el('[data-test-subj=euiSheetChip]', cell(0, 0));
    assert.dom(chip).hasTagName('span');
    assert.dom(chip).hasClass('euiBadge');
    assert.strictEqual(chip.children.length, 1, 'one child: the content span');
    assert.dom(chip.children[0]).hasClass('euiBadge__content');
    assert.dom(chip.children[0]!.children[0]).hasClass('euiBadge__text');
    // a later DOM change does not change the title (EuiBadge's observer
    // would): the title comes from the value
    chip.querySelector('.euiBadge__text')!.append(' extra');
    await settled();
    assert.strictEqual(chip.getAttribute('title'), 'Open');
  });

  test('CHP5 a highlighted chip keeps its title, the marks in its text', async function (assert) {
    const store = localRecords(ROWS, { getRecordId: getId });
    await render(
      <template>
        <div style="width:1200px">
          <EuiSheet
            @records={{store.records}}
            @fields={{FIELDS}}
            @getRecordId={{getId}}
            @onChange={{store.apply}}
            @highlight="ru"
          />
        </div>
      </template>
    );
    const ana = el('[data-test-subj=euiSheetChip]', cell(0, 2));
    assert.dom('mark', ana).hasText('Ru', 'the term is marked');
    assert.strictEqual(ana.getAttribute('title'), 'Ana Ruiz');
    assert.strictEqual(ana.innerText, 'Ana Ruiz');
    const done = chips(0, 1)[0]!;
    assert.dom('mark', done).doesNotExist();
    assert.strictEqual(done.getAttribute('title'), 'Done');
  });
});
