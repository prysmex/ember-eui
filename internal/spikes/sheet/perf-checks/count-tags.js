// Glimmer tag computes, re-walks and tracked writes per 120 px wheel step on
// the d08 demo, and who writes (stacks). Needs the instrumented template chunk
// (node instrument.mjs apply).
//   PORT=4195 node count-tags.js [frozen] [selected]
// Prints a table of 12 steps, the writers, then
//   RESULT {"case":"plain","computes":..,"rewalks":..,"writes":..}  (medians over the steps)
const L = require('./lib');
const frozen = process.argv.includes('frozen');
// `selected`: click a cell first (the fill handle is then shown while scrolling)
const selected = process.argv.includes('selected');
const caseName = [frozen ? 'frozen' : 'plain', selected ? 'selected' : '']
  .filter(Boolean)
  .join('-');
(async () => {
  const { browser, page, errors } = await L.open({ width: 1400, height: 900 });
  const n = await L.sheetIndexByLabel(page, 'Employees');
  await L.centerSheet(page, n);
  if (frozen) {
    const on = await L.freezeFirstField(page, n);
    console.log('frozen:', JSON.stringify(on));
    if (on.checked !== 'true' || on.cellsInRow < 31)
      throw new Error('the first field is not frozen');
  }
  if (selected)
    console.log(
      'selected:',
      JSON.stringify(await L.selectCell(page, n, 2, 'name'))
    );
  await L.hoverGrid(page, n);
  await page.waitForTimeout(300);
  const instrumented = await page.evaluate(
    () => typeof globalThis.__tc === 'number'
  );
  if (!instrumented)
    throw new Error(
      'the template chunk is not instrumented (node instrument.mjs apply)'
    );
  const snap = () =>
    page.evaluate(() => ({
      tc: globalThis.__tc || 0,
      rc: globalThis.__rc || 0,
      dc: globalThis.__dc || 0
    }));
  await page.evaluate(() => {
    globalThis.__stacks = [];
    globalThis.__rec = true;
  });
  const rows = [];
  for (let i = 0; i < 12; i++) {
    const a = await snap();
    await page.mouse.wheel(0, 120);
    await page.waitForTimeout(250);
    const b = await snap();
    rows.push({
      step: i,
      computes: b.tc - a.tc,
      rewalks: b.rc - a.rc,
      writes: b.dc - a.dc
    });
  }
  console.table(rows);
  const stacks = await page.evaluate(() => {
    globalThis.__rec = false;
    return globalThis.__stacks;
  });
  // who writes: the first frames of each stack outside the template chunk
  const who = new Map();
  for (const s of stacks) {
    const frames = s
      .split('\n')
      .slice(2, 9)
      .map((l) =>
        l
          .trim()
          .replace(/^at /, '')
          .replace(/\(?https?:\/\/[^/]+\/assets\//, '')
          .replace(/-[A-Za-z0-9_]{8}\.js/, '.js')
          .replace(/\)$/, '')
      );
    const key = frames
      .filter((f) => !/^template/.test(f) && !/^(u|x) /.test(f))
      .slice(0, 4)
      .join(' < ');
    who.set(key, (who.get(key) || 0) + 1);
  }
  console.log(`\ntracked writes recorded: ${stacks.length}`);
  for (const [k, v] of [...who].sort((a, b) => b[1] - a[1]).slice(0, 15))
    console.log(String(v).padStart(5), k);
  const med = (k) => {
    const s = rows.map((r) => r[k]).sort((a, b) => a - b);
    return s[Math.floor(s.length / 2)];
  };
  console.log('errors:', errors.length, errors.slice(0, 5).join(' | '));
  console.log(
    'RESULT ' +
      JSON.stringify({
        case: caseName,
        computes: med('computes'),
        rewalks: med('rewalks'),
        writes: med('writes'),
        errors: errors.length
      })
  );
  await browser.close();
})();
