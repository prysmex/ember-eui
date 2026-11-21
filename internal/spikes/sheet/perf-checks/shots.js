// Screenshots of the sheets whose cells show chips, and the chips' DOM
// (classes, title, text of the badge and its two inner spans), to compare
// two builds (compare.js).
//   PORT=4195 node shots.js <out-dir> [dark]
const L = require('./lib');
const fs = require('fs');
const path = require('path');
const out = process.argv[2];
const dark = process.argv[3] === 'dark';
fs.mkdirSync(out, { recursive: true });

(async () => {
  const { browser, page, errors } = await L.open({ width: 1400, height: 900 });
  if (dark) await L.setTheme(page, 'Dark');
  const dom = {};
  // every sheet on the page that shows chips (d08's "Employees" among them)
  const sheets = await page.evaluate(() =>
    [...document.querySelectorAll('div.euiSheet')]
      .map((s, n) => ({
        n,
        label: s.querySelector('[role=grid]')?.getAttribute('aria-label') || '',
        chips: s.querySelectorAll('[data-test-subj=euiSheetChip]').length
      }))
      .filter((s) => s.chips > 0)
  );
  for (const { n, label } of sheets) {
    const name = `sheet${String(n).padStart(2, '0')}-${label.replace(/\W+/g, '-').toLowerCase()}`;
    await L.centerSheet(page, n);
    await page.mouse.move(5, 5); // no hover
    await page.waitForTimeout(500);
    await page
      .locator(L.sheetSel(n))
      .screenshot({ path: path.join(out, `${name}.png`) });
    dom[name] = await page.evaluate((n) => {
      const s = document.querySelectorAll('div.euiSheet')[n];
      return [...s.querySelectorAll('[data-test-subj=euiSheetChip]')].map(
        (b) => ({
          tag: b.tagName,
          cls: b.className,
          title: b.getAttribute('title'),
          attrs: [...b.attributes]
            .map((a) => a.name)
            .sort()
            .join(' '),
          inner: [...b.querySelectorAll('span')]
            .map((c) => c.className)
            .join(' | '),
          text: b.innerText,
          width: Math.round(b.getBoundingClientRect().width * 100) / 100
        })
      );
    }, n);
    console.log(name, dom[name].length, 'chips');
  }
  fs.writeFileSync(path.join(out, 'chips.json'), JSON.stringify(dom, null, 1));
  console.log('errors:', errors.length, errors.slice(0, 5).join(' | '));
  await browser.close();
})();
