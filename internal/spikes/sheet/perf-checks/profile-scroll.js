// CPU profile + frame times of real wheel scrolling on the d08 demo
// ("Employees", 10,000 records x 31 fields): 40 wheel steps of 120 px down,
// 20 right, 20 up, 30 ms apart.
//   PORT=4195 node profile-scroll.js [frozen] [selected]
// Prints the top self-time files and functions, then one line
//   RESULT {"case":"plain","median":..,"p90":..,"over50":..,"frames":..,"tagShare":..}
// (tagShare: Glimmer's [TAG_COMPUTE] self time / busy time, busy = profiled
// time without (idle)).
const L = require('./lib');
const fs = require('fs');
const path = require('path');
const frozen = process.argv.includes('frozen');
// `selected`: click a cell first (the fill handle is then shown while scrolling)
const selected = process.argv.includes('selected');
const caseName = [frozen ? 'frozen' : 'plain', selected ? 'selected' : '']
  .filter(Boolean)
  .join('-');
const OUT = process.env.OUT || path.join(require('os').tmpdir(), 'sheet-perf');
fs.mkdirSync(OUT, { recursive: true });

(async () => {
  const { browser, page, errors } = await L.open({ width: 1400, height: 900 });
  const n = await L.sheetIndexByLabel(page, 'Employees');
  await L.centerSheet(page, n);
  if (frozen) {
    const on = await L.freezeFirstField(page, n);
    console.log('frozen:', JSON.stringify(on));
    if (on.checked !== 'true' || !on.frozenCell)
      throw new Error('the first field is not frozen');
  }
  if (selected)
    console.log(
      'selected:',
      JSON.stringify(await L.selectCell(page, n, 2, 'name'))
    );
  await L.hoverGrid(page, n);

  // frame times in the page
  await page.evaluate(() => {
    window.__frames = [];
    let last = performance.now();
    const loop = (t) => {
      window.__frames.push(t - last);
      last = t;
      if (window.__recording) requestAnimationFrame(loop);
    };
    window.__recording = true;
    requestAnimationFrame(loop);
  });

  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Profiler.enable');
  await cdp.send('Profiler.setSamplingInterval', { interval: 200 });
  await cdp.send('Profiler.start');
  const t0 = Date.now();
  for (let i = 0; i < 40; i++) {
    await page.mouse.wheel(0, 120);
    await page.waitForTimeout(30);
  }
  for (let i = 0; i < 20; i++) {
    await page.mouse.wheel(120, 0);
    await page.waitForTimeout(30);
  }
  for (let i = 0; i < 20; i++) {
    await page.mouse.wheel(0, -120);
    await page.waitForTimeout(30);
  }
  await page.waitForTimeout(500);
  const wall = Date.now() - t0;
  const { profile } = await cdp.send('Profiler.stop');
  const frames = await page.evaluate(() => {
    window.__recording = false;
    return window.__frames;
  });
  fs.writeFileSync(
    `${OUT}/scroll-${caseName}.cpuprofile`,
    JSON.stringify(profile)
  );

  // self time per function and per file
  const byId = new Map(profile.nodes.map((nd) => [nd.id, nd]));
  const self = new Map();
  const dts = profile.timeDeltas;
  profile.samples.forEach((id, i) =>
    self.set(id, (self.get(id) || 0) + (dts[i] || 0))
  );
  const total = [...self.values()].reduce((a, b) => a + b, 0) / 1000;
  const fnAgg = new Map();
  const fileAgg = new Map();
  for (const [id, us] of self) {
    const cf = byId.get(id).callFrame;
    const file = (cf.url || '(native)')
      .replace(/^.*\/assets\//, '')
      .replace(/-[A-Za-z0-9_]{8}\.js$/, '.js');
    const key = `${cf.functionName || '(anonymous)'}  [${file}:${cf.lineNumber + 1}]`;
    fnAgg.set(key, (fnAgg.get(key) || 0) + us / 1000);
    fileAgg.set(file, (fileAgg.get(file) || 0) + us / 1000);
  }
  const top = (m, k) => [...m].sort((a, b) => b[1] - a[1]).slice(0, k);
  const special = (re) =>
    [...fnAgg].filter(([k]) => re.test(k)).reduce((a, [, v]) => a + v, 0);
  const idle = special(/^\(idle\)/);
  const busy = total - idle;
  // Glimmer's [TAG_COMPUTE] (minified, named after its class): the function
  // that starts at `[X](){let{lastChecked:` in the template chunk
  const chunkUrl = profile.nodes
    .map((nd) => nd.callFrame.url)
    .find((u) => /\/assets\/template-(?!only)[^/]*\.js$/.test(u));
  let tag = 0;
  if (chunkUrl) {
    const src = await page.evaluate(
      async (u) => (await fetch(u)).text(),
      chunkUrl
    );
    const m = /\[\w+\]\(\)\{let\{lastChecked:/.exec(src);
    if (m) {
      const before = src.slice(0, m.index);
      const line = before.split('\n').length - 1;
      const col = m.index - (before.lastIndexOf('\n') + 1);
      for (const [id, us] of self) {
        const cf = byId.get(id).callFrame;
        if (
          cf.url === chunkUrl &&
          cf.lineNumber === line &&
          cf.columnNumber >= col &&
          cf.columnNumber <= col + 6
        )
          tag += us / 1000;
      }
    }
  }
  console.log(
    `\n== ${caseName}: wall ${wall} ms, profiled ${total.toFixed(0)} ms, busy ${busy.toFixed(0)} ms`
  );
  const sorted = frames.slice(2).sort((a, b) => a - b);
  const pct = (p) => sorted[Math.floor(sorted.length * p)];
  console.log(
    `frames: ${frames.length}, median ${pct(0.5)?.toFixed(1)} ms, p90 ${pct(0.9)?.toFixed(1)} ms, max ${sorted.at(-1)?.toFixed(1)} ms, >50ms: ${sorted.filter((f) => f > 50).length}`
  );
  console.log('-- by file (self ms):');
  for (const [k, v] of top(fileAgg, 12))
    console.log(`  ${v.toFixed(0).padStart(6)}  ${k}`);
  console.log('-- by function (self ms):');
  for (const [k, v] of top(fnAgg, 30))
    console.log(`  ${v.toFixed(1).padStart(7)}  ${k}`);
  console.log('errors:', errors.length, errors.slice(0, 5).join(' | '));
  console.log(
    'RESULT ' +
      JSON.stringify({
        case: caseName,
        wall,
        busy: Math.round(busy),
        frames: frames.length,
        median: +pct(0.5).toFixed(1),
        p90: +pct(0.9).toFixed(1),
        over50: sorted.filter((f) => f > 50).length,
        tagShare: +(tag / busy).toFixed(3),
        errors: errors.length
      })
  );
  await browser.close();
})();
