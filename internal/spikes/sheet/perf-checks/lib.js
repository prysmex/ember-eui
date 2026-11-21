// Shared helpers: open the docs page of the production build in Playwright's
// Chromium and find a sheet by its grid's aria-label.
//   PORT (default 4195): the `vite preview` port.
const { chromium } = require('playwright');

const PORT = process.env.PORT || '4195';
const URL = `http://127.0.0.1:${PORT}/docs/sheet/docs/sheet`;

async function open({ width = 1400, height = 900 } = {}) {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: 2
  });
  const page = await context.newPage();
  // INIT_SCRIPT: JavaScript run before the page's own (experiments, e.g. a
  // global flag read by a temporarily patched build)
  if (process.env.INIT_SCRIPT)
    await page.addInitScript(process.env.INIT_SCRIPT);
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => {
    if (m.type() === 'error' || m.type() === 'warning')
      errors.push(m.type() + ': ' + m.text());
  });
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      await page.goto(URL, { timeout: 180000 });
      await page.waitForSelector('[role=grid]', { timeout: 180000 });
      break;
    } catch (e) {
      console.log('load retry', attempt, e.message);
      await page.waitForTimeout(15000);
    }
  }
  await page.waitForTimeout(1500);
  return { browser, context, page, errors };
}

// The root (.euiSheet) of the n-th sheet on the page.
function sheetSel(n) {
  return `xpath=(//div[contains(concat(' ', normalize-space(@class), ' '), ' euiSheet ')])[${n + 1}]`;
}

async function sheetIndexByLabel(page, label, nth = 0) {
  return page.evaluate(
    ({ label, nth }) => {
      const sheets = [...document.querySelectorAll('div.euiSheet')];
      const hits = sheets
        .map((s, i) => [s, i])
        .filter(
          ([s]) =>
            s.querySelector('[role=grid]')?.getAttribute('aria-label') === label
        );
      return hits[nth] ? hits[nth][1] : -1;
    },
    { label, nth }
  );
}

// Scrolls the n-th sheet to the middle of the viewport (no smooth scroll).
async function centerSheet(page, n) {
  await page.evaluate((n) => {
    document.documentElement.style.scrollBehavior = 'auto';
    document
      .querySelectorAll('div.euiSheet')
      [n].scrollIntoView({ block: 'center' });
  }, n);
  await page.waitForTimeout(800);
}

// Turns on the d08 demo's "Freeze the first field" switch (a real click on
// the switch whose label is exactly that text); whether the row then renders
// all 31 data cells (the frozen grid renders every column of the rows in view).
async function freezeFirstField(page, n) {
  const box = await page.evaluate(() => {
    const sw = [...document.querySelectorAll('button[role=switch]')].find(
      (b) => {
        const ids = (b.getAttribute('aria-labelledby') || '')
          .split(' ')
          .filter(Boolean);
        const label =
          ids
            .map((id) => document.getElementById(id)?.textContent.trim())
            .join(' ') || b.closest('.euiSwitch')?.textContent.trim();
        return label === 'Freeze the first field';
      }
    );
    if (!sw) return null;
    sw.scrollIntoView({ block: 'center' });
    const r = sw.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  });
  if (!box) throw new Error('no "Freeze the first field" switch');
  await page.mouse.click(box.x, box.y);
  await page.waitForTimeout(800);
  await centerSheet(page, n);
  return page.evaluate((n) => {
    const s = document.querySelectorAll('div.euiSheet')[n];
    const sw = [...document.querySelectorAll('button[role=switch]')].find(
      (b) =>
        b.closest('.euiSwitch')?.textContent.trim() === 'Freeze the first field'
    );
    const cells = s.querySelectorAll(
      '[role=gridcell][data-gridcell-visible-row-index="3"]'
    ).length;
    // the frozen grid renders the frozen columns and the ones in view (no
    // longer all 31), so the check is the first field's frozen class
    const code = s.querySelector(
      '[role=gridcell][data-gridcell-visible-row-index="3"][data-gridcell-column-id="code"]'
    );
    return {
      checked: sw?.getAttribute('aria-checked'),
      cellsInRow: cells,
      frozenCell: !!code?.classList.contains('euiSheet__cell--frozen')
    };
  }, n);
}

// Moves the mouse to the middle of the n-th sheet's grid (where the wheel goes).
async function hoverGrid(page, n) {
  const box = await page.evaluate((n) => {
    const r = document
      .querySelectorAll('div.euiSheet')
      [n].querySelector('[role=grid]')
      .getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  }, n);
  await page.mouse.move(box.x, box.y);
  return box;
}

// The docs header's theme switch: 'Light', 'Dark' or 'System'.
async function setTheme(page, label) {
  const btn = page
    .locator('.euiHeader button.euiButton', { hasText: /Light|Dark|System/ })
    .first();
  await btn.scrollIntoViewIfNeeded();
  const box = await btn.boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(500);
  const opt = page
    .locator(
      '.euiPopover__panel button, .euiPopover__panel [role=option], .euiContextMenuItem',
      { hasText: new RegExp('^\\s*' + label) }
    )
    .first();
  const ob = await opt.boundingBox();
  await page.mouse.click(ob.x + ob.width / 2, ob.y + ob.height / 2);
  await page.waitForTimeout(1500);
}

// Clicks a data cell of the n-th sheet (visible row index, field id): a
// selected cell shows the fill handle. Returns the selected cell's text and
// whether the fill handle is shown.
async function selectCell(page, n, row, fieldId) {
  const box = await page.evaluate(
    ({ n, row, fieldId }) => {
      const s = document.querySelectorAll('div.euiSheet')[n];
      const c = s.querySelector(
        `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-id="${fieldId}"]`
      );
      const r = c.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    },
    { n, row, fieldId }
  );
  await page.mouse.click(box.x, box.y);
  await page.waitForTimeout(500);
  return page.evaluate((n) => {
    const s = document.querySelectorAll('div.euiSheet')[n];
    return {
      fillHandle: !!s.querySelector('[data-test-subj=euiSheetFillHandle]'),
      selected: s.querySelector('.euiSheet__cell--selected')?.textContent.trim()
    };
  }, n);
}

module.exports = {
  selectCell,
  setTheme,
  PORT,
  URL,
  open,
  sheetSel,
  sheetIndexByLabel,
  centerSheet,
  freezeFirstField,
  hoverGrid
};
