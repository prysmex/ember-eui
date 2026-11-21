// axe-core with a sheet in a state: an editor open, a menu, the field
// editor, the expanded record, the import screen with a file, the shortcut
// list, an error shown, full screen.
//   node axe-states.js [outDir] [modes]   modes: comma list (default light,dark)
//   STATES: a comma list of state names to limit the run
// Writes `<outDir>/states-<mode>.json` and prints the counts. Each state
// also checks that it reached what it means to show (`expect`), else it
// is reported as `NOT REACHED` (its counts would mean nothing).
const fs = require('fs');
const path = require('path');
const lib = require('./lib.js');

const P = '/docs/sheet/docs/sheet';
const cell = (label, row, field) =>
  `.euiSheet:has([role=grid][aria-label="${label}"]) [role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-id="${field}"]`;

async function openEditor(page, label, row, field) {
  await page.click(cell(label, row, field));
  await page.keyboard.press('Enter');
  await page.waitForTimeout(600);
}

const STATES = {
  'text-editor': {
    url: `${P}/editing`,
    run: (page) => openEditor(page, 'People', 0, 'name'),
    expect: '.euiSheet__editor input'
  },
  'select-editor': {
    url: `${P}/field-types/selects`,
    run: (page) => openEditor(page, 'Inspections', 0, 'site'),
    expect: '[data-eui-sheet-layer] [role=listbox], [data-eui-sheet-layer] input'
  },
  'multi-select-editor': {
    url: `${P}/field-types/selects`,
    run: (page) => openEditor(page, 'Inspections', 0, 'hazards'),
    expect: '[data-eui-sheet-layer] input, [data-eui-sheet-layer] [role=listbox]'
  },
  'date-editor': {
    url: `${P}/field-types/dates`,
    run: (page) => openEditor(page, 'Incidents', 0, 'date'),
    expect: '[data-eui-sheet-layer] input, .euiSheet__editor input'
  },
  'date-time-editor': {
    url: `${P}/field-types/dates`,
    run: (page) => openEditor(page, 'Incidents', 0, 'reported'),
    expect: '[data-eui-sheet-layer] input, .euiSheet__editor input'
  },
  'row-menu': {
    url: `${P}/editing`,
    run: async (page) => {
      await page.click(cell('People', 1, 'city'), { button: 'right' });
      await page.waitForTimeout(500);
    },
    expect: '[data-test-subj=euiSheetRowMenu]'
  },
  'field-menu': {
    url: `${P}/fields`,
    run: async (page) => {
      const header = page.locator(
        '.euiSheet:has([role=grid][aria-label="People"]) [role=columnheader][data-gridcell-column-id="city"]'
      );
      await header.hover();
      await header
        .locator('[data-test-subj^="dataGridHeaderCellActionButton"]')
        .click();
      await page.waitForTimeout(500);
    },
    expect: '[data-test-subj="euiSheetEditField-city"]'
  },
  'field-editor': {
    url: `${P}/fields`,
    run: async (page) => {
      await STATES['field-menu'].run(page);
      await page.click('[data-test-subj="euiSheetEditField-city"]');
      await page.waitForTimeout(600);
    },
    expect: '[data-test-subj=euiSheetFieldEditor]'
  },
  'expanded-record': {
    url: `${P}/rows/expanded-record`,
    run: async (page) => {
      const row = page.locator(
        '.euiSheet:has([role=grid][aria-label="Findings"]) [role=gridcell][data-gridcell-visible-row-index="0"][data-gridcell-column-id="euiSheetRow"]'
      );
      await row.hover();
      await row.locator('[data-eui-sheet-row-expand]').click();
      await page.waitForTimeout(800);
    },
    expect: '[data-test-subj=euiSheetRecord]'
  },
  'import-screen': {
    url: `${P}/import-export/import-screen`,
    run: async (page) => {
      const csv =
        'Código,Nombre,Precio,Fecha,Activo,Estado\n' +
        Array.from(
          { length: 30 },
          (_, i) =>
            `A-${i},Item ${i},${i}.5,2026-12-${String((i % 28) + 1).padStart(2, '0')},${i % 2 ? 'sí' : 'no'},${i % 3 ? 'Abierto' : 'xx'}`
        ).join('\n');
      await page.setInputFiles('[data-test-subj=importScreenInput]', {
        name: 'inventory.csv',
        mimeType: 'text/csv',
        buffer: Buffer.from(csv)
      });
      await page.waitForSelector('.euiSheetImport', { timeout: 30000 });
      await page.waitForTimeout(2500);
    },
    expect: '.euiSheetImport'
  },
  'shortcut-list': {
    url: `${P}/editing/keyboard`,
    run: async (page) => {
      await page.click(cell('People', 0, 'start'));
      await page.keyboard.press('Control+/');
      await page.waitForTimeout(600);
    },
    expect: '[data-test-subj=euiSheetShortcuts]'
  },
  'cell-error': {
    url: `${P}/validation/field-rules`,
    run: async (page) => {
      await page.click(cell('Inspections', 3, 'permit'));
      await page.waitForTimeout(500);
    },
    expect: '[data-test-subj=euiSheetCellError]'
  },
  // the tints where contrast drops: a range over invalid cells, checked rows
  tints: {
    url: `${P}/validation/field-rules`,
    run: async (page) => {
      await page.click(cell('Inspections', 3, 'euiSheetRow'));
      await page.keyboard.press(' ');
      await page.keyboard.press('ArrowDown');
      await page.keyboard.press(' ');
      await page.click(cell('Inspections', 2, 'title'));
      await page.click(cell('Inspections', 5, 'findings'), {
        modifiers: ['Shift']
      });
      await page.mouse.move(5, 5);
      await page.waitForTimeout(500);
    },
    expect: '.euiSheet__cell--selected.euiSheet__cell--invalid'
  },
  'search-match': {
    url: `${P}/data/search-matches`,
    run: async (page) => {
      await page.fill('[data-test-subj=sheetSearch]', 'a');
      await page.waitForTimeout(400);
      await page.click('[data-test-subj=sheetSearchNext]');
      await page.waitForTimeout(600);
    },
    expect: '.euiSheet__cell--match'
  },
  'full-screen': {
    url: `${P}/more/full-screen`,
    run: async (page) => {
      await page.click('[data-test-subj=fullScreenButton]');
      await page.waitForTimeout(800);
    },
    expect: '.euiSheet--fullScreen'
  }
};

async function main() {
  const outDir = path.resolve(process.argv[2] || 'a11y-out');
  const modes = (process.argv[3] || 'light,dark').split(',');
  const names = process.env.STATES
    ? process.env.STATES.split(',')
    : Object.keys(STATES);
  fs.mkdirSync(outDir, { recursive: true });
  const { browser, context } = await lib.launch();
  for (const mode of modes) {
    const perState = {};
    const total = {};
    for (const name of names) {
      const state = STATES[name];
      const { page, errors } = await lib.openPage(context, state.url, mode);
      let reached = false;
      try {
        await state.run(page);
        reached = (await page.locator(state.expect).count()) > 0;
      } catch (e) {
        errors.push('run: ' + e.message.split('\n')[0]);
      }
      const violations = await lib.runAxe(page, { portalIsSheet: true });
      const contrast = await lib.runContrast(page);
      contrast.axeIncomplete = await page.evaluate(() => window.__axeIncompleteContrast);
      const counts = lib.tally(violations);
      perState[name] = { reached, counts, violations, contrast, errors };
      if (reached) lib.addTally(total, counts);
      for (const f of reached ? contrast.failures : []) {
        total.contrast ??= {};
        const k = `${f.tag}.${f.cls} ${f.fg} on ${f.bg} ${f.ratio}`;
        total.contrast[k] = (total.contrast[k] ?? 0) + f.count;
      }
      const sheet = Object.entries(counts.sheet ?? {})
        .map(([rule, n]) => `${rule} ${n}`)
        .join(', ');
      console.log(
        `${mode} ${name}${reached ? '' : ' NOT REACHED'}: sheet [${sheet}]; contrast ${contrast.failures.map((f) => f.cls + ' ' + f.ratio).join(', ') || 'ok'}${errors.length ? ` errors: ${errors.join(' / ')}` : ''}`
      );
      await page.close();
    }
    fs.writeFileSync(
      path.join(outDir, `states-${mode}.json`),
      JSON.stringify({ total, perState }, null, 1)
    );
    console.log(`TOTAL ${mode}`, JSON.stringify(total, null, 1));
  }
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
