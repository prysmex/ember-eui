// d08 after real input: the first field frozen, a range selected (Name of
// rows 3-4, Shift+click), then wheel steps down and right; a screenshot
// after each stage, and the cells' classes and attributes (what
// setCellProps sets: selected, frozen, row numbers) in cells.json.
//   PORT=4195 node shots-d08.js <out-dir>
const L = require('./lib');
const fs = require('fs');
const path = require('path');
const out = process.argv[2];
fs.mkdirSync(out, { recursive: true });

(async () => {
  const { browser, page, errors } = await L.open({ width: 1400, height: 900 });
  const n = await L.sheetIndexByLabel(page, 'Employees');
  await L.centerSheet(page, n);
  await L.freezeFirstField(page, n);
  await L.selectCell(page, n, 2, 'name');
  const b = await page.evaluate((n) => {
    const c = document
      .querySelectorAll('div.euiSheet')
      [n].querySelector(
        '[role=gridcell][data-gridcell-visible-row-index="3"][data-gridcell-column-id="department"]'
      );
    const r = c.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, n);
  await page.keyboard.down('Shift');
  await page.mouse.click(b.x, b.y);
  await page.keyboard.up('Shift');
  await page.waitForTimeout(500);
  const cells = {};
  const snap = async (name) => {
    await page.waitForTimeout(600);
    await page
      .locator(L.sheetSel(n))
      .screenshot({ path: path.join(out, `${name}.png`) });
    cells[name] = await page.evaluate(
      (n) =>
        [
          ...document
            .querySelectorAll('div.euiSheet')
            [n].querySelectorAll('[role=gridcell]')
        ]
          .map((c) =>
            [...c.attributes]
              .filter((a) => a.name !== 'tabindex')
              .map((a) => `${a.name}=${a.value}`)
              .sort()
              .join(' ')
          )
          .sort(),
      n
    );
  };
  await snap('d08-selected');
  await L.hoverGrid(page, n);
  for (let i = 0; i < 3; i++) {
    await page.mouse.wheel(0, 120);
    await page.waitForTimeout(100);
  }
  await page.mouse.move(5, 5);
  await snap('d08-scrolled-down');
  await L.hoverGrid(page, n);
  for (let i = 0; i < 3; i++) {
    await page.mouse.wheel(240, 0);
    await page.waitForTimeout(100);
  }
  await page.mouse.move(5, 5);
  await snap('d08-scrolled-right');
  await L.hoverGrid(page, n);
  for (let i = 0; i < 3; i++) {
    await page.mouse.wheel(0, -120);
    await page.waitForTimeout(100);
  }
  await page.mouse.move(5, 5);
  await snap('d08-scrolled-back');
  fs.writeFileSync(
    path.join(out, 'chips.json'),
    JSON.stringify(cells, null, 1)
  );
  console.log('errors:', errors.length, errors.slice(0, 5).join(' | '));
  await browser.close();
})();
