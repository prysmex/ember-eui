/** EuiSheet with the field types of v0.2 batch 5 (V02-DESIGN.md 8.1, 8.3). */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  fillIn,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiSheet from '#src/components/eui-sheet.gts';
import { localRecords } from '#src/local-records.ts';
import {
  cell,
  changeSet,
  clipboard,
  editor,
  editorFrame,
  el,
  focusCell,
  isInvalid,
  press,
  pressed,
  text,
  type
} from '../../helpers/sheet.ts';

import type {
  EuiSheetField,
  SheetAttachment,
  SheetLinkedRecord,
  SheetUser
} from '#src/core/index.ts';

interface Row {
  id: string;
  [key: string]: unknown;
}

const getId = (row: { id: string }) => row.id;

const TAGS = [
  { value: 'red', label: 'Red', color: 'danger' },
  { value: 'blue', label: 'Blue' },
  { value: 'green', label: 'Green' },
  { value: 'gray', label: 'Gray' }
];

const PEOPLE: SheetLinkedRecord[] = [
  { id: 'p1', label: 'Ana' },
  { id: 'p2', label: 'Bo' },
  { id: 'p3', label: 'Carla' }
];

const USERS: SheetUser[] = [
  { id: 'u1', label: 'Ana Ruiz', email: 'ana@x.com' },
  { id: 'u2', label: 'Bo Vela', avatarUrl: 'https://example.com/bo.png' }
];

/** The label of an option, without the screen-reader text EuiSelectable adds. */
function labelOf(option: Element): string {
  const copy = option.cloneNode(true) as Element;
  copy
    .querySelectorAll('.euiScreenReaderOnly')
    .forEach((element) => element.remove());
  return copy.textContent?.trim() ?? '';
}

function listed(): string[] {
  return Array.from(editorFrame()?.querySelectorAll('[role=option]') ?? []).map(
    labelOf
  );
}

function checked(): string[] {
  return Array.from(
    editorFrame()?.querySelectorAll('[role=option][aria-checked=true]') ?? []
  ).map(labelOf);
}

function option(label: string): HTMLElement {
  const found = Array.from(
    editorFrame()?.querySelectorAll<HTMLElement>('[role=option]') ?? []
  ).find((element) => labelOf(element) === label);
  if (!found) throw new Error(`No option ${label}`);
  return found;
}

function chips(row: number, col: number): string[] {
  return Array.from(
    cell(row, col).querySelectorAll('[data-test-subj=euiSheetChip]')
  ).map((chip) => chip.textContent?.trim() ?? '');
}

/** Dispatches a drag event carrying `files` on `target`. */
async function drag(
  kind: 'dragover' | 'drop',
  target: Element,
  files: File[]
): Promise<DragEvent> {
  const dataTransfer = new DataTransfer();
  for (const file of files) dataTransfer.items.add(file);
  const event = new DragEvent(kind, {
    dataTransfer,
    bubbles: true,
    cancelable: true
  });
  target.dispatchEvent(event);
  await settled();
  return event;
}

const TABBABLE =
  'a[href], button, input, select, textarea, [contenteditable], [tabindex]';

module(
  'Integration | Component | EuiSheet field types (v0.2)',
  function (hooks) {
    setupRenderingTest(hooks);

    async function renderSheet(fields: EuiSheetField<Row>[], records: Row[]) {
      const store = localRecords<Row>(records, { getRecordId: getId, fields });
      await render(
        <template>
          <div style="width:1100px">
            <EuiSheet
              @records={{store.records}}
              @fields={{store.fields}}
              @getRecordId={{getId}}
              @onChange={{store.apply}}
            />
          </div>
        </template>
      );
      return store;
    }

    const tagFields = (): EuiSheetField<Row>[] => [
      { id: 'name' },
      {
        id: 'tags',
        label: 'Tags',
        type: 'multiSelect',
        options: TAGS,
        createOnPaste: true
      }
    ];

    test('M1 multiSelect: chips, at most three, then +N', async function (assert) {
      await renderSheet(tagFields(), [
        { id: 'r0', name: 'a', tags: ['red', 'blue'] },
        { id: 'r1', name: 'b', tags: ['red', 'blue', 'green', 'gray'] },
        { id: 'r2', name: 'c', tags: [] }
      ]);
      assert.deepEqual(chips(0, 1), ['Red', 'Blue']);
      assert.deepEqual(chips(1, 1), ['Red', 'Blue', 'Green']);
      assert.dom('[data-test-subj=euiSheetMore]', cell(1, 1)).hasText('+1');
      assert.deepEqual(chips(2, 1), []);
    });

    test('M2 multiSelect editor: clicks toggle and keep it open, Tab saves', async function (assert) {
      const store = await renderSheet(tagFields(), [
        { id: 'r0', name: 'a', tags: ['red', 'blue'] },
        { id: 'r1', name: 'b', tags: [] }
      ]);
      const before = store.records[0]!['tags'];
      await focusCell(0, 1);
      await press('Enter');
      assert.deepEqual(listed(), ['Red', 'Blue', 'Green', 'Gray']);
      assert.deepEqual(checked(), ['Red', 'Blue']);
      await click(option('Green'));
      await click(option('Red'));
      assert.dom(editorFrame()).exists('still open after two clicks');
      assert.deepEqual(checked(), ['Blue', 'Green']);
      assert.deepEqual(store.log, [], 'nothing saved yet');
      await press('Tab');
      assert.strictEqual(editorFrame(), null, 'closed');
      assert.deepEqual(store.log, [
        changeSet({
          source: 'edit',
          patches: [
            {
              recordId: 'r0',
              fieldId: 'tags',
              from: ['red', 'blue'],
              to: ['blue', 'green']
            }
          ]
        })
      ]);
      assert.deepEqual(before, ['red', 'blue'], 'the old array is not mutated');
      assert.deepEqual(chips(0, 1), ['Blue', 'Green']);
      // the keyboard: ArrowDown makes an option current, Enter toggles it,
      // Escape cancels
      await focusCell(1, 1);
      await press('Enter');
      await press('ArrowDown');
      await press('Enter');
      assert.deepEqual(checked(), ['Red'], 'Enter toggled the current option');
      assert.dom(editorFrame()).exists();
      await press('Escape');
      assert.strictEqual(editorFrame(), null);
      assert.strictEqual(store.log.length, 1, 'Escape saved nothing');
      // focus leaving saves the toggled options
      await press('Enter');
      await click(option('Gray'));
      await click(cell(0, 0));
      assert.deepEqual(store.log[1]?.patches, [
        { recordId: 'r1', fieldId: 'tags', from: [], to: ['gray'] }
      ]);
    });

    test('M3 multiSelect paste: labels, quoted parts, a new option; an equal value is no change', async function (assert) {
      const store = await renderSheet(tagFields(), [
        { id: 'r0', name: 'a', tags: ['blue', 'red'] },
        { id: 'r1', name: 'b', tags: [] }
      ]);
      await focusCell(1, 1);
      await clipboard('paste', 'red, "Pink, hot"');
      assert.deepEqual(store.log, [
        changeSet({
          source: 'paste',
          patches: [
            {
              recordId: 'r1',
              fieldId: 'tags',
              from: [],
              to: ['red', 'Pink, hot']
            }
          ],
          newOptions: [
            {
              fieldId: 'tags',
              option: { value: 'Pink, hot', label: 'Pink, hot' }
            }
          ]
        })
      ]);
      assert.deepEqual(
        chips(1, 1),
        ['Red', 'Pink, hot'],
        'the new option shows'
      );
      await focusCell(0, 1);
      await clipboard('paste', 'Blue, Red');
      assert.strictEqual(store.log.length, 1, 'an equal array writes nothing');
      const copied = await clipboard('copy');
      assert.strictEqual(copied.text, 'Blue, Red');
      await focusCell(1, 1);
      assert.strictEqual(
        (await clipboard('copy')).text,
        'Red, "Pink, hot"',
        'a label with a comma is quoted'
      );
    });

    test('M4 multiSelect clear: Delete gives []; again, nothing', async function (assert) {
      const store = await renderSheet(tagFields(), [
        { id: 'r0', name: 'a', tags: ['red'] }
      ]);
      await focusCell(0, 1);
      await press('Delete');
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r0', fieldId: 'tags', from: ['red'], to: [] }
      ]);
      await press('Delete');
      assert.strictEqual(store.log.length, 1, '[] equals []');
      // undo: the conflict check uses equals
      await pressed('z', { ctrlKey: true });
      assert.deepEqual(store.records[0]!['tags'], ['red']);
    });

    test('M5 multiSelect opened by typing: the seeded search filters, Enter toggles the first match (V5, N11)', async function (assert) {
      const store = await renderSheet(tagFields(), [
        { id: 'r0', name: 'a', tags: [] }
      ]);
      await focusCell(0, 1);
      await type('g');
      assert.strictEqual(editor()!.value, 'g', 'the key seeds the search');
      assert.deepEqual(listed(), ['Green', 'Gray']);
      await press('Enter');
      assert.deepEqual(
        checked(),
        ['Green'],
        'no current option: the first match'
      );
      assert.dom(editorFrame()).exists('still open');
      await press('Tab');
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r0', fieldId: 'tags', from: [], to: ['green'] }
      ]);
    });

    const linkFields = (
      search: (
        q: string,
        c: { signal: AbortSignal }
      ) => Promise<SheetLinkedRecord[]>
    ): EuiSheetField<Row>[] => [
      { id: 'name' },
      { id: 'people', label: 'People', type: 'linkedRecord', search }
    ];

    test('L1 linkedRecord: the picker searches field.search (async, with a signal)', async function (assert) {
      const calls: Array<{ query: string; signal: AbortSignal }> = [];
      const search = (query: string, { signal }: { signal: AbortSignal }) => {
        calls.push({ query, signal });
        return new Promise<SheetLinkedRecord[]>((resolve) =>
          setTimeout(
            () =>
              resolve(
                PEOPLE.filter((p) =>
                  p.label.toLowerCase().includes(query.toLowerCase())
                )
              ),
            10
          )
        );
      };
      await renderSheet(linkFields(search), [
        { id: 'r0', name: 'a', people: [] }
      ]);
      await focusCell(0, 1);
      await press('Enter');
      assert.strictEqual(calls[0]?.query, '', 'searched on open');
      assert.deepEqual(listed(), ['Ana', 'Bo', 'Carla']);
      await fillIn(editor()!, 'b');
      assert.strictEqual(calls[calls.length - 1]?.query, 'b');
      assert.true(calls[0]!.signal.aborted, 'the older search was aborted');
      assert.deepEqual(listed(), ['Bo']);
    });

    test('L2 linkedRecord: pick two, Tab saves; chips; chosen ones first', async function (assert) {
      const search = () => Promise.resolve(PEOPLE);
      const store = await renderSheet(linkFields(search), [
        { id: 'r0', name: 'a', people: [] }
      ]);
      await focusCell(0, 1);
      await press('Enter');
      await waitUntil(() => listed().length === 3);
      await click(option('Carla'));
      await click(option('Ana'));
      assert.dom(editorFrame()).exists('still open');
      await press('Tab');
      assert.deepEqual(store.log[0]?.patches, [
        {
          recordId: 'r0',
          fieldId: 'people',
          from: [],
          to: [PEOPLE[2], PEOPLE[0]]
        }
      ]);
      assert.deepEqual(chips(0, 1), ['Carla', 'Ana']);
      await focusCell(0, 1);
      await press('Enter');
      await waitUntil(() => listed().length === 3);
      assert.deepEqual(listed(), ['Carla', 'Ana', 'Bo'], 'chosen ones first');
      assert.deepEqual(checked(), ['Carla', 'Ana']);
    });

    test('L3 linkedRecord: copy gives the labels; without @onResolve a paste is rejected', async function (assert) {
      const store = await renderSheet(
        linkFields(() => Promise.resolve(PEOPLE)),
        [
          {
            id: 'r0',
            name: 'a',
            people: [PEOPLE[0], { id: 'p9', label: 'Bo, Jr' }]
          }
        ]
      );
      assert.deepEqual(chips(0, 1), ['Ana', 'Bo, Jr']);
      await focusCell(0, 1);
      assert.strictEqual((await clipboard('copy')).text, 'Ana, "Bo, Jr"');
      await clipboard('paste', 'Carla');
      assert.deepEqual(store.log[0]?.rejected, [
        {
          recordId: 'r0',
          fieldId: 'people',
          text: 'Carla',
          message: '"Carla" could not be resolved'
        }
      ]);
    });

    test('US1 user with options: avatar and name; a pick saves at once; paste by email', async function (assert) {
      const store = await renderSheet(
        [
          { id: 'name' },
          { id: 'owner', label: 'Owner', type: 'user', options: USERS }
        ],
        [
          { id: 'r0', name: 'a', owner: USERS[1] },
          { id: 'r1', name: 'b', owner: null }
        ]
      );
      assert.dom('.euiSheet__personName', cell(0, 1)).hasText('Bo Vela');
      assert
        .dom('.euiAvatar img, .euiAvatar', cell(0, 1))
        .exists('an EuiAvatar');
      await focusCell(1, 1);
      await press('Enter');
      assert.deepEqual(listed(), ['Ana Ruiz', 'Bo Vela']);
      await fillIn(editor()!, 'bo');
      assert.deepEqual(listed(), ['Bo Vela'], 'filtered locally');
      await click(option('Bo Vela'));
      assert.strictEqual(editorFrame(), null, 'one user: a pick saves');
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r1', fieldId: 'owner', from: null, to: USERS[1] }
      ]);
      await focusCell(0, 1);
      await clipboard('paste', 'ANA@x.com');
      assert.deepEqual(store.log[1]?.patches, [
        { recordId: 'r0', fieldId: 'owner', from: USERS[1], to: USERS[0] }
      ]);
      await clipboard('paste', 'Ana Ruiz');
      assert.strictEqual(store.log.length, 2, 'the same user: no change');
    });

    test('US2 a picker left without a pick saves nothing and keeps a rejected text', async function (assert) {
      const store = await renderSheet(
        [
          { id: 'name' },
          { id: 'owner', label: 'Owner', type: 'user', options: USERS }
        ],
        [
          { id: 'r0', name: 'a', owner: null },
          { id: 'r1', name: 'b', owner: null }
        ]
      );
      await focusCell(0, 1);
      await press('Enter');
      await fillIn(editor()!, 'bru');
      await click(cell(1, 0));
      assert.strictEqual(editorFrame(), null, 'closed');
      assert.deepEqual(
        store.log,
        [],
        'a local list: the typed search saves nothing'
      );
      assert.false(isInvalid(0, 1));
      await focusCell(1, 1);
      await clipboard('paste', 'Zed');
      assert.true(isInvalid(1, 1), 'rejected');
      await press('Enter');
      await click(cell(0, 0));
      assert.strictEqual(store.log.length, 1, 'opened and left: nothing');
      assert.true(isInvalid(1, 1), 'the rejected text stays');
    });

    const fileFields = (
      upload: (
        files: File[],
        context: { signal: AbortSignal }
      ) => Promise<SheetAttachment[]>
    ): EuiSheetField<Row>[] => [
      { id: 'name' },
      { id: 'files', label: 'Files', type: 'attachment', upload }
    ];

    const A: SheetAttachment = {
      id: 'a',
      name: 'a.pdf',
      url: 'https://example.com/a.pdf'
    };
    const PNG: SheetAttachment = {
      id: 'b',
      name: 'b.png',
      url: 'https://example.com/b.png',
      type: 'image/png'
    };

    let uploaded = 0;
    const fakeUpload = (files: File[]) =>
      new Promise<SheetAttachment[]>((resolve, reject) =>
        setTimeout(() => {
          if (files.some((file) => file.name.startsWith('fail'))) {
            reject(new Error('nope'));
            return;
          }
          resolve(
            files.map((file) => ({
              id: `up${++uploaded}`,
              name: file.name,
              url: `https://example.com/${file.name}`
            }))
          );
        }, 10)
      );

    test('A1 attachment editor: lists, uploads through field.upload, removes; stays open', async function (assert) {
      const store = await renderSheet(fileFields(fakeUpload), [
        { id: 'r0', name: 'a', files: [A, PNG] }
      ]);
      assert.dom('[data-test-subj=euiSheetFile]', cell(0, 1)).hasText('a.pdf');
      assert
        .dom('[data-test-subj=euiSheetThumb]', cell(0, 1))
        .hasAttribute('src', 'https://example.com/b.png');
      await focusCell(0, 1);
      await press('Enter');
      const panel = el('[data-test-subj=euiSheetAttachmentEditor]');
      const links = Array.from(panel.querySelectorAll('a'));
      assert.deepEqual(
        links.map((a) => [a.getAttribute('href'), a.target, a.rel]),
        [
          ['https://example.com/a.pdf', '_blank', 'noopener noreferrer'],
          ['https://example.com/b.png', '_blank', 'noopener noreferrer']
        ]
      );
      const input = el(
        '[data-test-subj=euiSheetFilePicker]',
        panel
      ) as HTMLInputElement;
      assert.true(
        panel.contains(document.activeElement),
        'focus is in the panel'
      );
      await triggerEvent(input, 'change', {
        files: [new File(['x'], 'c.txt', { type: 'text/plain' })]
      });
      assert.deepEqual(store.log[0]?.patches, [
        {
          recordId: 'r0',
          fieldId: 'files',
          from: [A, PNG],
          to: [
            A,
            PNG,
            {
              id: `up${uploaded}`,
              name: 'c.txt',
              url: 'https://example.com/c.txt'
            }
          ]
        }
      ]);
      assert.dom(editorFrame()).exists('still open after the upload');
      assert.dom('[data-test-subj=euiSheetAttachment]').exists({ count: 3 });
      await click(
        el(
          '[data-test-subj=euiSheetAttachment]:first-child [data-test-subj=euiSheetRemoveFile]'
        )
      );
      assert.deepEqual(
        (store.log[1]?.patches[0]?.to as SheetAttachment[]).map((f) => f.id),
        ['b', `up${uploaded}`]
      );
      assert.dom(editorFrame()).exists('still open after a removal');
      await press('Escape');
      assert.strictEqual(editorFrame(), null);
      // failing upload in the editor: an error in the panel
      await press('Enter');
      await triggerEvent(el('[data-test-subj=euiSheetFilePicker]'), 'change', {
        files: [new File(['x'], 'fail.txt')]
      });
      assert
        .dom('[data-test-subj=euiSheetUploadError]')
        .hasText('Upload failed');
      assert.strictEqual(store.log.length, 2, 'nothing saved');
    });

    test('A2 a file dropped on an attachment cell is uploaded and appended', async function (assert) {
      const store = await renderSheet(fileFields(fakeUpload), [
        { id: 'r0', name: 'a', files: [A] }
      ]);
      const file = new File(['x'], 'drop.txt');
      const over = await drag('dragover', cell(0, 1), [file]);
      assert.true(over.defaultPrevented, 'the cell takes the drop');
      assert.dom(cell(0, 1)).hasClass('euiSheet__cell--dropTarget');
      const name = await drag('dragover', cell(0, 0), [file]);
      assert.false(name.defaultPrevented, 'a text cell does not');
      assert.dom(cell(0, 1)).doesNotHaveClass('euiSheet__cell--dropTarget');
      await drag('dragover', cell(0, 1), [file]);
      const dropEvent = new DragEvent('drop', {
        dataTransfer: (() => {
          const dt = new DataTransfer();
          dt.items.add(file);
          return dt;
        })(),
        bubbles: true,
        cancelable: true
      });
      cell(0, 1).dispatchEvent(dropEvent);
      assert.true(dropEvent.defaultPrevented);
      await waitUntil(() =>
        cell(0, 1).classList.contains('euiSheet__cell--pending')
      );
      assert.dom(cell(0, 1)).doesNotHaveClass('euiSheet__cell--dropTarget');
      await settled();
      assert.dom(cell(0, 1)).doesNotHaveClass('euiSheet__cell--pending');
      assert.deepEqual(
        (store.log[0]?.patches[0]?.to as SheetAttachment[]).map((f) => f.name),
        ['a.pdf', 'drop.txt']
      );
      assert.strictEqual(store.log[0]?.source, 'edit');
      // pasted files go the same way
      await focusCell(0, 1);
      const data = new DataTransfer();
      data.items.add(new File(['y'], 'pasted.png', { type: 'image/png' }));
      const paste = new ClipboardEvent('paste', {
        clipboardData: data,
        bubbles: true,
        cancelable: true
      });
      document.activeElement!.dispatchEvent(paste);
      await settled();
      assert.true(paste.defaultPrevented);
      assert.deepEqual(
        (store.log[1]?.patches[0]?.to as SheetAttachment[]).map((f) => f.name),
        ['a.pdf', 'drop.txt', 'pasted.png']
      );
    });

    test('A3 a failed upload is a rejection with "Upload failed"; text is not a file', async function (assert) {
      const store = await renderSheet(fileFields(fakeUpload), [
        { id: 'r0', name: 'a', files: [A] }
      ]);
      await drag('dragover', cell(0, 1), [new File(['x'], 'fail.txt')]);
      await drag('drop', cell(0, 1), [new File(['x'], 'fail.txt')]);
      assert.deepEqual(store.log[0]?.rejected, [
        {
          recordId: 'r0',
          fieldId: 'files',
          text: 'fail.txt',
          message: 'Upload failed'
        }
      ]);
      assert.true(isInvalid(0, 1));
      assert.strictEqual(text(0, 1), 'fail.txt');
      assert.deepEqual(store.records[0]!['files'], [A], 'the files stay');
      await focusCell(0, 1);
      await clipboard('paste', 'https://example.com/x.pdf');
      assert.deepEqual(
        store.log[1]?.rejected[0]?.message,
        'Text is not a file'
      );
      assert.strictEqual(text(0, 1), 'https://example.com/x.pdf', 'shown');
      assert.strictEqual(
        (await clipboard('copy')).text,
        'https://example.com/a.pdf',
        'a copy gives the value: the URLs'
      );
      // a spreadsheet's copy: text, HTML and a picture of the cells: the text wins
      const data = new DataTransfer();
      data.setData('text/plain', 'https://example.com/y.pdf');
      data.setData(
        'text/html',
        '<table><td>https://example.com/y.pdf</td></table>'
      );
      data.items.add(new File(['p'], 'cells.png', { type: 'image/png' }));
      document.activeElement!.dispatchEvent(
        new ClipboardEvent('paste', {
          clipboardData: data,
          bubbles: true,
          cancelable: true
        })
      );
      await settled();
      assert.strictEqual(store.log.length, 3, 'no upload: the text was pasted');
      assert.deepEqual(
        store.log[2]?.rejected[0]?.text,
        'https://example.com/y.pdf'
      );
    });

    const allFields = (): EuiSheetField<Row>[] => [
      { id: 'name' },
      { id: 'tags', type: 'multiSelect', options: TAGS },
      { id: 'people', type: 'linkedRecord', search: () => Promise.resolve([]) },
      { id: 'owner', type: 'user', options: USERS },
      { id: 'files', type: 'attachment', upload: fakeUpload },
      { id: 'price', type: 'currency', currency: 'USD', locale: 'en-US' },
      { id: 'pct', type: 'percent' },
      { id: 'time', type: 'duration' },
      { id: 'stars', type: 'rating' },
      { id: 'site', type: 'url' },
      { id: 'mail', type: 'email' },
      { id: 'tel', type: 'phone' },
      { id: 'notes', type: 'longText' }
    ];

    const fullRow = (): Row => ({
      id: 'r0',
      name: 'a',
      tags: ['red', 'blue'],
      people: [PEOPLE[0]],
      owner: USERS[1],
      files: [A, PNG],
      price: 12.5,
      pct: 0.25,
      time: 5400,
      stars: 3,
      site: 'example.com',
      mail: 'ana@x.com',
      tel: '+52 81 1234',
      notes: 'one\ntwo'
    });

    test('A4 no cell of the new types holds a tabbable element (P9, N12)', async function (assert) {
      await renderSheet(allFields(), [fullRow()]);
      const cells = Array.from(
        document.querySelectorAll<HTMLElement>(
          '[role=gridcell][data-gridcell-visible-row-index="0"]:not([data-gridcell-column-id=euiSheetRow])'
        )
      );
      assert.strictEqual(cells.length, 13, 'every field rendered');
      for (const element of cells) {
        const found = Array.from(
          element.querySelectorAll<HTMLElement>(TABBABLE)
        ).filter((child) => child.getAttribute('tabindex') !== '-1');
        assert.deepEqual(
          found.map((child) => child.outerHTML.slice(0, 60)),
          [],
          element.dataset['gridcellColumnId']
        );
        assert.strictEqual(
          element.getAttribute('aria-describedby'),
          null,
          `${element.dataset['gridcellColumnId']}: no focus-trap hint`
        );
      }
    });

    test('NU1 currency, percent and duration: typing and paste', async function (assert) {
      const store = await renderSheet(allFields(), [fullRow()]);
      assert.strictEqual(text(0, 5), '$12.50');
      assert.strictEqual(text(0, 6), '25%');
      assert.strictEqual(text(0, 7), '1:30');
      await focusCell(0, 5);
      await type('1');
      assert.dom(editor()).hasAttribute('inputmode', 'decimal');
      await fillIn(editor()!, '$1,234.5');
      await press('Enter');
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r0', fieldId: 'price', from: 12.5, to: 1234.5 }
      ]);
      assert.strictEqual(text(0, 5), '$1,234.50');
      await focusCell(0, 6);
      await clipboard('paste', '12.5%');
      assert.deepEqual(store.log[1]?.patches, [
        { recordId: 'r0', fieldId: 'pct', from: 0.25, to: 0.125 }
      ]);
      assert.strictEqual(text(0, 6), '13%', 'shown with precision 0');
      assert.strictEqual(
        (await clipboard('copy')).text,
        '12.5%',
        'copied exactly'
      );
      await focusCell(0, 7);
      await type('2');
      await fillIn(editor()!, '1h 15m');
      await press('Enter');
      assert.deepEqual(store.log[2]?.patches, [
        { recordId: 'r0', fieldId: 'time', from: 5400, to: 4500 }
      ]);
      assert.strictEqual(text(0, 7), '1:15');
      await focusCell(0, 7);
      await clipboard('paste', 'soon');
      assert.deepEqual(
        store.log[3]?.rejected[0]?.message,
        '"soon" is not a duration'
      );
      assert.dom(`[role=columnheader][data-gridcell-column-id=price]`).exists();
    });

    test('RA1 rating: a star click sets it, the same star clears it, digits too', async function (assert) {
      const store = await renderSheet(allFields(), [fullRow()]);
      const stars = () =>
        Array.from(cell(0, 8).querySelectorAll('[data-eui-sheet-star]')).map(
          (star) => star.classList.contains('euiSheet__star--on')
        );
      assert.deepEqual(stars(), [true, true, true, false, false]);
      await click(el('[data-eui-sheet-star="5"]', cell(0, 8)));
      assert.deepEqual(store.log[0]?.patches, [
        { recordId: 'r0', fieldId: 'stars', from: 3, to: 5 }
      ]);
      assert.strictEqual(editorFrame(), null, 'no editor');
      await click(el('[data-eui-sheet-star="5"]', cell(0, 8)));
      assert.deepEqual(store.log[1]?.patches, [
        { recordId: 'r0', fieldId: 'stars', from: 5, to: null }
      ]);
      assert.deepEqual(stars(), [false, false, false, false, false]);
      await focusCell(0, 8);
      assert.true(await pressed('4'), 'the digit is the sheet’s');
      assert.deepEqual(store.log[2]?.patches, [
        { recordId: 'r0', fieldId: 'stars', from: null, to: 4 }
      ]);
      await press('Enter');
      assert.strictEqual(editorFrame(), null, 'Enter opens nothing');
    });

    test('LK1 a click on the link opens it once (stubbed window.open); beside it, it selects', async function (assert) {
      const opened: unknown[][] = [];
      const original = window.open;
      window.open = ((...args: unknown[]) => {
        opened.push(args);
        return null;
      }) as typeof window.open;
      try {
        const store = await renderSheet(allFields(), [
          fullRow(),
          { ...fullRow(), id: 'r1', site: 'javascript:alert(1)', mail: 'nope' }
        ]);
        await click(el('[data-eui-sheet-link]', cell(0, 9)));
        assert.deepEqual(opened, [
          ['https://example.com', '_blank', 'noopener']
        ]);
        assert.strictEqual(editorFrame(), null, 'no edit');
        await click(el('[data-eui-sheet-link]', cell(0, 10)));
        await click(el('[data-eui-sheet-link]', cell(0, 11)));
        assert.deepEqual(opened.slice(1), [
          ['mailto:ana@x.com', '_blank', 'noopener'],
          ['tel:+52811234', '_blank', 'noopener']
        ]);
        // beside the text: a normal click (the second one edits)
        await click(cell(0, 0));
        await click(cell(0, 9));
        assert.strictEqual(editorFrame(), null, 'the first click selects');
        // as in LT1: the grid's scroll to the focused column comes a frame
        // later and would close an editor opened before it
        await new Promise((resolve) => requestAnimationFrame(resolve));
        await new Promise((resolve) => requestAnimationFrame(resolve));
        await click(cell(0, 9));
        assert.strictEqual(opened.length, 3, 'nothing opened');
        assert.dom(editorFrame()).exists('the second click on the cell edits');
        await press('Escape');
        // a javascript: value has no link, and is invalid
        assert.dom('[data-eui-sheet-link]', cell(1, 9)).doesNotExist();
        assert.true(isInvalid(1, 9));
        assert.dom('[data-eui-sheet-link]', cell(1, 10)).doesNotExist();
        // the row menu: "Open link" on a link cell
        const box = cell(0, 9).getBoundingClientRect();
        const point = { clientX: box.left + 5, clientY: box.top + 5 };
        await triggerEvent(cell(0, 9), 'mousedown', { button: 2, ...point });
        await triggerEvent(cell(0, 9), 'contextmenu', { button: 2, ...point });
        await click(el('[data-test-subj=euiSheetRowMenu-openLink]'));
        assert.deepEqual(opened[opened.length - 1], [
          'https://example.com',
          '_blank',
          'noopener'
        ]);
        assert.strictEqual(store.log.length, 0);
      } finally {
        window.open = original;
      }
    });

    test('LK2 no <a> in the grid’s cells', async function (assert) {
      await renderSheet(allFields(), [fullRow()]);
      assert.dom('[role=gridcell] a').doesNotExist();
      assert.dom('[role=gridcell] [role=link]').exists({ count: 3 });
    });

    test('LT1 long text: Shift+Enter adds a line, the frame grows, Enter saves; copy is quoted', async function (assert) {
      const store = await renderSheet(allFields(), [fullRow()]);
      assert.strictEqual(text(0, 12), 'one\ntwo');
      await focusCell(0, 12);
      // the grid scrolls the last column into view; its scroll event comes
      // a frame later and would close an editor opened before it (as on
      // scroll)
      await new Promise((resolve) => requestAnimationFrame(resolve));
      await new Promise((resolve) => requestAnimationFrame(resolve));
      await press('Enter');
      const textarea = el(
        '[data-test-subj=euiSheetTextarea]'
      ) as HTMLTextAreaElement;
      assert.strictEqual(document.activeElement, textarea);
      assert.dom(editorFrame()).hasClass('euiSheet__editor--expand');
      const height = editorFrame()!.offsetHeight;
      assert.true(editorFrame()!.offsetWidth >= 240, 'at least 240 px wide');
      assert.true(await pressed('Enter', { shiftKey: true }), 'Shift+Enter');
      assert.true(await pressed('Enter', { altKey: true }), 'Alt+Enter');
      assert.strictEqual(textarea.value, 'one\ntwo\n\n');
      await fillIn(textarea, 'one\ntwo\nthree\nfour\nfive');
      assert.true(editorFrame()!.offsetHeight > height, 'the frame grew');
      assert.dom(editorFrame()).exists('still editing');
      await press('Enter');
      assert.strictEqual(editorFrame(), null);
      assert.deepEqual(store.log[0]?.patches, [
        {
          recordId: 'r0',
          fieldId: 'notes',
          from: 'one\ntwo',
          to: 'one\ntwo\nthree\nfour\nfive'
        }
      ]);
      await focusCell(0, 12);
      assert.strictEqual(
        (await clipboard('copy')).text,
        '"one\ntwo\nthree\nfour\nfive"',
        'quoted by toTsv'
      );
    });
  }
);
