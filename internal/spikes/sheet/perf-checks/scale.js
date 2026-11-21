// The large-data scenarios on the harness page (build-large.sh): first
// render, scroll steps, a range drag, a paste of 1,000 lines and its undo, in
// that order on one page, with real input (Playwright's mouse and keyboard;
// the paste through the real clipboard).
//   PORT=4197 node scale.js rows=100000 [frozen] [throttle=4] [profile] [mode=grid]
// Each scenario's time runs from the input event (its timeStamp, read by a
// capturing listener) to the end of the first frame after the result is on
// screen: the task after the next requestAnimationFrame, so style, layout
// and paint of that frame are in it. Prints one
//   RESULT {...}
// line; with the instrumented template chunk (instrument.mjs) also the tag
// computes, re-walks and writes of each scenario; with `profile`, the top
// functions of each scenario's CPU profile (profiles go to $OUT).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const arg = (name, dflt) => {
  const hit = process.argv.find((a) => a.startsWith(name + '='));
  return hit ? hit.slice(name.length + 1) : dflt;
};
const ROWS = Number(arg('rows', 10000));
const THROTTLE = Number(arg('throttle', 1));
const MODE = arg('mode', 'sheet');
const FROZEN = process.argv.includes('frozen');
const PROFILE = process.argv.includes('profile');
// scenarios to run (default all), joined by +: mount+scroll+drag+paste+undo
const ONLY = arg('only', 'mount+scroll+drag+paste+undo').split(/[+,]/);
const PASTE_LINES = Number(arg('lines', 1000));
const PORT = process.env.PORT || '4197';
const OUT = process.env.OUT || path.join(require('os').tmpdir(), 'sheet-perf');
fs.mkdirSync(OUT, { recursive: true });
const caseName = `${MODE}-${ROWS}${FROZEN ? '-frozen' : ''}-x${THROTTLE}`;

// in the page: the end of the first frame from now on (after the next
// requestAnimationFrame, the task that follows its paint)
const FRAME_END = `new Promise((r) => requestAnimationFrame(() => setTimeout(() => r(performance.now()), 0)))`;

async function main() {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1400, height: 900 },
    deviceScaleFactor: 2
  });
  await context.grantPermissions(['clipboard-read', 'clipboard-write'], {
    origin: `http://127.0.0.1:${PORT}`
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(m.type() + ': ' + m.text());
  });
  const q = `rows=${ROWS}${FROZEN ? '&frozen=1' : ''}${MODE === 'grid' ? '&mode=grid' : ''}`;
  await page.goto(`http://127.0.0.1:${PORT}/docs/sheet/docs/perf-large?${q}`, {
    timeout: 300000
  });
  await page.waitForSelector('[data-test-subj=perfMount]', { timeout: 300000 });
  await page.waitForTimeout(1000);
  const cdp = await context.newCDPSession(page);
  if (PROFILE) {
    await cdp.send('Profiler.enable');
    await cdp.send('Profiler.setSamplingInterval', { interval: 200 });
  }
  if (THROTTLE > 1)
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });

  // input timestamps (capturing listeners) and frame times
  await page.evaluate(() => {
    const ev = (globalThis.__ev = {});
    for (const type of [
      'click',
      'wheel',
      'mousedown',
      'mousemove',
      'mouseup',
      'keydown',
      'paste'
    ])
      window.addEventListener(
        type,
        (e) => {
          ev[type] = e.timeStamp;
          ev[type + 'N'] = (ev[type + 'N'] || 0) + 1;
        },
        true
      );
    // the n+1-th event of a type: input may reach the page after Playwright's call returns
    globalThis.__waitEv = async (type, n) => {
      while ((ev[type + 'N'] || 0) <= n)
        await new Promise((r) => setTimeout(r, 1));
      return ev[type];
    };
    globalThis.__frames = [];
    let last = performance.now();
    const loop = (t) => {
      globalThis.__frames.push([t, t - last]);
      last = t;
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  });
  const counters = await page.evaluate(
    () => typeof globalThis.__tc === 'number'
  );
  const snap = () =>
    page.evaluate(() => ({
      tc: globalThis.__tc,
      rc: globalThis.__rc,
      dc: globalThis.__dc
    }));
  const countOf = (type) =>
    page.evaluate((t) => globalThis.__ev[t + 'N'] || 0, type);
  const frameMark = () => page.evaluate(() => globalThis.__frames.length);
  const framesSince = (i) =>
    page.evaluate((i) => globalThis.__frames.slice(i).map((f) => f[1]), i);

  const result = {
    case: caseName,
    rows: ROWS,
    throttle: THROTTLE,
    frozen: FROZEN,
    mode: MODE
  };
  const counts = {};
  const profiles = {};
  // runs fn (the input and the wait for its result), with counters and profile
  async function scenario(name, fn) {
    const a = counters ? await snap() : null;
    if (PROFILE) await cdp.send('Profiler.start');
    const out = await fn();
    if (PROFILE) {
      const { profile } = await cdp.send('Profiler.stop');
      fs.writeFileSync(
        `${OUT}/${caseName}-${name}.cpuprofile`,
        JSON.stringify(profile)
      );
      profiles[name] = summarize(profile);
    }
    if (counters) {
      const b = await snap();
      counts[name] = {
        computes: b.tc - a.tc,
        rewalks: b.rc - a.rc,
        writes: b.dc - a.dc
      };
    }
    return out;
  }

  const gridBox = () =>
    page.evaluate(() => {
      const r = document.querySelector('[role=grid]').getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
    });
  const cellBox = (row, col) =>
    page.evaluate(
      ({ row, col }) => {
        const c = document.querySelector(
          `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-id="${col}"]`
        );
        if (!c) return null;
        const r = c.getBoundingClientRect();
        return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
      },
      { row, col }
    );

  // 1. first render: the click on "Mount" to the first frame with the rows
  if (ONLY.includes('mount')) {
    const box = await page.evaluate(() => {
      const b = document.querySelector('[data-test-subj=perfMount]');
      b.scrollIntoView({ block: 'start' });
      const r = b.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
    });
    result.mount = await scenario('mount', async () => {
      const n = await countOf('click');
      await page.mouse.click(box.x, box.y);
      return page.evaluate(
        async ({ FRAME_END, n }) => {
          const frameEnd = () => eval(FRAME_END);
          const t0 = await globalThis.__waitEv('click', n);
          let end;
          for (let i = 0; i < 2000; i++) {
            end = await frameEnd();
            if (document.querySelector('[role=grid] [role=gridcell]')) break;
          }
          return +(end - t0).toFixed(1);
        },
        { FRAME_END, n }
      );
    });
    result.generateMs = await page.evaluate(
      () => +globalThis.__perf.generateMs.toFixed(1)
    );
    await page.waitForTimeout(1500 * THROTTLE);
  }
  // the grid in the middle of the viewport (the wheel goes to its middle)
  const centerGrid = async () => {
    await page.evaluate(() => {
      document.documentElement.style.scrollBehavior = 'auto';
      (
        document.querySelector('div.euiSheet') ??
        document.querySelector('[role=grid]')
      ).scrollIntoView({ block: 'center' });
    });
    await page.waitForTimeout(500);
  };
  await centerGrid();

  // 2. scroll: 10 wheel steps of 120 px down, each waited out (the step's
  // time: the wheel event to the end of the last frame its renders took,
  // i.e. until two frames in a row are short), then frame times of 40 quick
  // steps down (30 ms apart) as profile-scroll.js measures them
  if (ONLY.includes('scroll')) {
    const g = await gridBox();
    await page.mouse.move(g.x, g.y);
    const scrollTop = () =>
      page.evaluate(() => [
        window.scrollY,
        document.querySelector('.euiDataGrid__virtualized')?.scrollTop
      ]);
    const startScroll = await scrollTop();
    const steps = await scenario('scroll', async () => {
      const times = [];
      for (let i = 0; i < 10; i++) {
        const n = await page.evaluate(() => globalThis.__ev.wheelN || 0);
        await page.mouse.wheel(0, 120);
        times.push(
          await page.evaluate(
            async ({ FRAME_END, n }) => {
              const frameEnd = () => eval(FRAME_END);
              // the wheel event may reach the page after mouse.wheel returns
              while ((globalThis.__ev.wheelN || 0) <= n)
                await new Promise((r) => setTimeout(r, 1));
              const t0 = globalThis.__ev.wheel;
              let end = await frameEnd();
              // settled: a frame that ends within 34 ms of the previous end
              for (let k = 0; k < 100; k++) {
                const next = await frameEnd();
                if (next - end < 34) break;
                end = next;
              }
              return end - t0;
            },
            { FRAME_END, n }
          )
        );
      }
      return times;
    });
    const endScroll = await scrollTop();
    // the wheel must scroll the grid, not the page
    if (endScroll[0] !== startScroll[0] || !(endScroll[1] > startScroll[1]))
      throw new Error(
        `the wheel did not scroll the grid: ${startScroll} -> ${endScroll}`
      );
    console.log('steps', steps.map((t) => t.toFixed(1)).join(' '));
    const s = [...steps].sort((a, b) => a - b);
    result.scrollStep = { median: +s[5].toFixed(1), max: +s[9].toFixed(1) };
    const mark = await frameMark();
    for (let i = 0; i < 40; i++) {
      await page.mouse.wheel(0, 120);
      await page.waitForTimeout(30);
    }
    await page.waitForTimeout(500 * THROTTLE);
    const fr = (await framesSince(mark)).slice(1).sort((a, b) => a - b);
    result.scrollFrames = {
      median: +fr[Math.floor(fr.length / 2)].toFixed(1),
      p90: +fr[Math.floor(fr.length * 0.9)].toFixed(1),
      over50: fr.filter((f) => f > 50).length
    };
    // back to the top
    await page.evaluate(() => {
      const s = document.querySelector('.euiDataGrid__virtualized');
      s?.scrollTo?.(0, 0);
    });
    for (let i = 0; i < 60; i++) await page.mouse.wheel(0, -1200);
    await page.waitForTimeout(1500 * THROTTLE);
    await centerGrid();
  }

  // 3. a range drag: from Name of row 2 to Week 3 of row 9, in 14 moves;
  // each move's time: the mousemove to the end of the next frame
  if (ONLY.includes('drag') && MODE === 'sheet') {
    const from = await cellBox(2, 'name');
    const to = await cellBox(9, 'w3');
    if (!from || !to) throw new Error('drag cells not rendered');
    result.drag = await scenario('drag', async () => {
      const moves = [];
      await page.mouse.move(from.x, from.y);
      await page.mouse.down();
      await page.evaluate(FRAME_END);
      for (let i = 1; i <= 14; i++) {
        const n = await countOf('mousemove');
        await page.mouse.move(
          from.x + ((to.x - from.x) * i) / 14,
          from.y + ((to.y - from.y) * i) / 14
        );
        moves.push(
          await page.evaluate(
            async ({ FRAME_END, n }) => {
              const t0 = await globalThis.__waitEv('mousemove', n);
              return (await eval(FRAME_END)) - t0;
            },
            { FRAME_END, n }
          )
        );
      }
      const nu = await countOf('mouseup');
      await page.mouse.up();
      const up = await page.evaluate(
        async ({ FRAME_END, n }) => {
          const t0 = await globalThis.__waitEv('mouseup', n);
          return (await eval(FRAME_END)) - t0;
        },
        { FRAME_END, n: nu }
      );
      const m = [...moves].sort((a, b) => a - b);
      return {
        moveMedian: +m[7].toFixed(1),
        moveMax: +m[13].toFixed(1),
        up: +up.toFixed(1)
      };
    });
    result.dragRange = await page.evaluate(
      () =>
        document.querySelectorAll(
          '[role=gridcell].euiSheet__cell--selected, [role=gridcell][aria-selected=true]'
        ).length
    );
    await page.waitForTimeout(500 * THROTTLE);
  }

  // 4. a paste of 1,000 lines x 6 fields (Name, Department, Hours, Start,
  // Active, Week 1) on Name of row 2: patches of existing records, through
  // the real clipboard (written with navigator.clipboard, Ctrl+V)
  if (ONLY.includes('paste') && MODE === 'sheet') {
    const at = await cellBox(2, 'name');
    await page.mouse.click(at.x, at.y);
    await page.waitForTimeout(500 * THROTTLE);
    const tsv = Array.from({ length: PASTE_LINES }, (_, i) =>
      [
        `Pasted ${i}`,
        ['Operations', 'Safety', 'Quality', 'IT'][i % 4],
        i % 60,
        `2024-0${1 + (i % 9)}-1${i % 9}`,
        i % 2 ? 'true' : 'false',
        i % 40
      ].join('\t')
    ).join('\n');
    await page.evaluate((t) => navigator.clipboard.writeText(t), tsv);
    result.clipboard =
      (await page.evaluate(() => navigator.clipboard.readText())) === tsv
        ? 'real'
        : 'mismatch';
    const before = await page.evaluate(() => globalThis.__perf.applies.length);
    result.paste = await scenario('paste', async () => {
      const n = await countOf('keydown');
      await page.keyboard.press('Control+V');
      return page.evaluate(
        async ({ FRAME_END, before, n }) => {
          const frameEnd = () => eval(FRAME_END);
          const t0 = await globalThis.__waitEv('keydown', n);
          let end;
          for (let i = 0; i < 4000; i++) {
            end = await frameEnd();
            const a = globalThis.__perf.applies;
            if (
              a.length > before &&
              document
                .querySelector(
                  '[role=gridcell][data-gridcell-visible-row-index="2"][data-gridcell-column-id="name"]'
                )
                ?.textContent.includes('Pasted 0')
            )
              break;
          }
          const ap = globalThis.__perf.applies[before];
          return {
            total: +(end - t0).toFixed(1),
            toOnChange: ap ? +(ap.at - t0).toFixed(1) : null,
            apply: ap ? +ap.ms.toFixed(1) : null,
            patches: ap?.patches,
            inserts: ap?.inserts,
            pasteEvent: globalThis.__ev.paste != null
          };
        },
        { FRAME_END, before, n }
      );
    });
    await page.waitForTimeout(1000 * THROTTLE);
  }

  // 5. undo of that paste (Ctrl+Z)
  if (ONLY.includes('undo') && ONLY.includes('paste') && MODE === 'sheet') {
    const before = await page.evaluate(() => globalThis.__perf.applies.length);
    result.undo = await scenario('undo', async () => {
      const n = await countOf('keydown');
      await page.keyboard.press('Control+Z');
      return page.evaluate(
        async ({ FRAME_END, before, n }) => {
          const frameEnd = () => eval(FRAME_END);
          const t0 = await globalThis.__waitEv('keydown', n);
          let end;
          for (let i = 0; i < 4000; i++) {
            end = await frameEnd();
            if (
              globalThis.__perf.applies.length > before &&
              !document
                .querySelector(
                  '[role=gridcell][data-gridcell-visible-row-index="2"][data-gridcell-column-id="name"]'
                )
                ?.textContent.includes('Pasted')
            )
              break;
          }
          const ap = globalThis.__perf.applies[before];
          return {
            total: +(end - t0).toFixed(1),
            toOnChange: ap ? +(ap.at - t0).toFixed(1) : null,
            apply: ap ? +ap.ms.toFixed(1) : null,
            source: ap?.source,
            patches: ap?.patches
          };
        },
        { FRAME_END, before, n }
      );
    });
  }

  if (counters) result.counts = counts;
  result.errors = errors.length;
  if (PROFILE)
    for (const [name, top] of Object.entries(profiles)) {
      console.log(`\n-- ${name}: busy ${top.busy} ms; top self time:`);
      for (const [k, v] of top.fns)
        console.log(`  ${v.toFixed(1).padStart(8)}  ${k}`);
    }
  console.log('errors:', errors.length, errors.slice(0, 5).join(' | '));
  console.log('RESULT ' + JSON.stringify(result));
  await browser.close();
}

// self time per function (top 25) and busy time (without idle)
function summarize(profile) {
  const byId = new Map(profile.nodes.map((nd) => [nd.id, nd]));
  const self = new Map();
  profile.samples.forEach((id, i) =>
    self.set(id, (self.get(id) || 0) + (profile.timeDeltas[i] || 0))
  );
  const fns = new Map();
  let idle = 0;
  let total = 0;
  for (const [id, us] of self) {
    const cf = byId.get(id).callFrame;
    total += us;
    if (cf.functionName === '(idle)') idle += us;
    const file = (cf.url || '(native)')
      .replace(/^.*\/assets\//, '')
      .replace(/-[A-Za-z0-9_]{8}\.js$/, '.js');
    const key = `${cf.functionName || '(anonymous)'}  [${file}:${cf.lineNumber + 1}:${cf.columnNumber + 1}]`;
    fns.set(key, (fns.get(key) || 0) + us / 1000);
  }
  return {
    busy: Math.round((total - idle) / 1000),
    fns: [...fns].sort((a, b) => b[1] - a[1]).slice(0, 25)
  };
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
