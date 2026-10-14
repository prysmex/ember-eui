// Memory-leak crawler for the docs site. See README.md in this directory.
//
//   node tests/leak/crawl.mjs passes [--base=http://127.0.0.1:4791] [--passes=3]
//   node tests/leak/crawl.mjs routes --routes=/docs/core/docs/a,/docs/core/docs/b [--reps=20] [--snapshots]
//   node tests/leak/crawl.mjs bisect [--reps=10]      every route, ranked by growth
//
// Common flags: --out=<dir> (JSON results + snapshots), --no-exercise,
// --away=/docs/introduction (the page visited between repetitions).
import { readFileSync, writeFileSync, mkdirSync, createWriteStream } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { launch } from './cdp.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = Object.fromEntries(
  process.argv.slice(3).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  }),
);
const mode = process.argv[2] ?? 'passes';
const BASE = args.base ?? 'http://127.0.0.1:4791';
const OUT = args.out ?? join(here, 'results');
const EXERCISE = !args['no-exercise'];
const AWAY = args.away ?? '/docs/introduction';
mkdirSync(OUT, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (...a) => console.log(new Date().toISOString().slice(11, 19), ...a);

const client = await launch();
log('chrome up');
process.on('uncaughtException', (e) => {
  log(`FATAL on ${currentRoute}: ${e.message}`);
  process.exit(3);
});
process.on('unhandledRejection', (e) => {
  log(`FATAL on ${currentRoute}: ${e?.message ?? e}`);
  process.exit(3);
});
const errors = [];
let currentRoute = '(load)';
await client.send('Runtime.enable');
await client.send('Page.enable');
await client.send('Performance.enable');
await client.send('HeapProfiler.enable');
client.on('Runtime.exceptionThrown', (p) =>
  errors.push({ route: currentRoute, text: p.exceptionDetails.exception?.description?.split('\n')[0] ?? p.exceptionDetails.text }),
);
client.on('Runtime.consoleAPICalled', (p) => {
  if (p.type === 'error')
    errors.push({ route: currentRoute, text: p.args.map((a) => a.value ?? a.description ?? '').join(' ').split('\n')[0].slice(0, 300) });
});
client.on('Inspector.targetCrashed', () => { log('RENDERER CRASHED on', currentRoute); process.exit(2); });
await client.send('Inspector.enable');
client.on('Page.javascriptDialogOpening', () => client.send('Page.handleJavaScriptDialog', { accept: true }));
await client.send('Page.addScriptToEvaluateOnNewDocument', {
  source: readFileSync(join(here, 'instrument.js'), 'utf8'),
});

await client.send('Page.navigate', { url: `${BASE}/docs/introduction` });
for (let i = 0; i < 100; i++) {
  await sleep(200);
  const ready = await client
    .evaluate(`!!(globalThis.emberInspectorApps?.[0]?.app?._applicationInstances?.size) && !!document.querySelector('.euiSideNav')`)
    .catch(() => false);
  if (ready) break;
}

log('app loaded');
// in-app navigation through the router service, so the Ember app stays alive
await client.evaluate(`(() => {
  const app = globalThis.emberInspectorApps[0].app;
  const owner = [...app._applicationInstances][0];
  window.__owner = owner;
  window.__router = owner.lookup('service:router');
  window.__nav = async (url) => {
    try { await window.__router.transitionTo(url); } catch (e) { if (e?.name !== 'TransitionAborted') throw e; }
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    return window.__router.currentURL;
  };
})()`);

log('router ready');
const ROUTES = JSON.parse(readFileSync(join(here, '../../dist/docfy-urls.json'), 'utf8'))
  .map((u) => u.replace(/\/$/, ''))
  .filter((u) => u.startsWith('/docs'))
  .filter((u) => !String(args.skip ?? '').split(',').includes(u));

async function nav(url) {
  currentRoute = url;
  if (args.debug) log('nav', url);
  const got = await client.evaluate(`window.__nav(${JSON.stringify(url)})`);
  await sleep(Number(args.settle ?? 250));
  return got;
}

async function pressEscape() {
  for (const type of ['keyDown', 'keyUp'])
    await client.send('Input.dispatchKeyEvent', {
      type,
      key: 'Escape',
      code: 'Escape',
      windowsVirtualKeyCode: 27,
      nativeVirtualKeyCode: 27,
    });
}

// Click every visible, enabled button inside the demo previews (not the code
// snippets, not the site chrome), each followed by Escape. Buttons are
// re-queried by index after every click because demos re-render.
async function exercise(url, max = Number(args['max-buttons'] ?? 25)) {
  const count = await client.evaluate(`window.__demoButtons = () => [...document.querySelectorAll('.docfy-demo__example button, .docfy-demo__example [role=button], .docfy-demo__example [role=switch]')]
    .filter((b) => b.offsetParent !== null && !b.disabled && !/download|export|print/i.test(b.textContent || '')), window.__demoButtons().length`);
  const n = Math.min(count, max);
  for (let i = 0; i < n; i++) {
    const clicked = await client.evaluate(`(() => {
      const b = window.__demoButtons()[${i}];
      if (!b || !b.isConnected) return false;
      const o = { bubbles: true, cancelable: true, composed: true, view: window, button: 0 };
      b.dispatchEvent(new PointerEvent('pointerdown', o));
      b.dispatchEvent(new MouseEvent('mousedown', o));
      b.focus?.();
      b.dispatchEvent(new PointerEvent('pointerup', o));
      b.dispatchEvent(new MouseEvent('mouseup', o));
      b.click();
      return true;
    })()`).catch(() => false);
    if (args.debug) log('  clicked', i, clicked);
    if (!clicked) continue;
    await sleep(60);
    await pressEscape();
    await sleep(40);
    // a demo button may have navigated
    const here = await client.evaluate('window.__router.currentURL').catch(() => url);
    if (here.split('?')[0].replace(/\/$/, '') !== url) await nav(url);
  }
  return n;
}

// Runtime.enable makes DevTools keep every logged object (the console
// panel's history); drop them so they don't show up as retained memory.
// Which routes log is recorded in results.consoleLogs.
const consoleLogs = {};
client.on('Runtime.consoleAPICalled', (p) => {
  if (p.type === 'error') return;
  const k = `${currentRoute} ${p.type}: ${p.args.map((a) => a.value ?? a.description ?? a.type).join(' ').slice(0, 120)}`;
  consoleLogs[k] = (consoleLogs[k] ?? 0) + 1;
});

async function measure(label) {
  await client.send('Runtime.discardConsoleEntries');
  if (args.debug) log('measure', label);
  for (let i = 0; i < 3; i++) {
    if (process.env.GC_MODE === 'none') break;
    await client.send('HeapProfiler.collectGarbage');
    await sleep(150);
  }
  const { metrics } = await client.send('Performance.getMetrics');
  const m = Object.fromEntries(metrics.map((x) => [x.name, x.value]));
  const heap = await client.send('Runtime.getHeapUsage');
  const page = await client.evaluate('window.__leakSnapshot()');
  const r = {
    label,
    jsHeapUsedMB: +(heap.usedSize / 1048576).toFixed(2),
    nodes: m.Nodes,
    jsEventListeners: m.JSEventListeners,
    documents: m.Documents,
    frames: m.Frames,
    layoutObjects: m.LayoutObjects,
    ...page,
  };
  return r;
}

async function snapshot(file) {
  const stream = createWriteStream(file);
  const off = client.on('HeapProfiler.addHeapSnapshotChunk', ({ chunk }) => stream.write(chunk));
  await client.send('Runtime.discardConsoleEntries');
  await client.send('HeapProfiler.collectGarbage');
  await client.send('HeapProfiler.takeHeapSnapshot', { reportProgress: false, captureNumericValue: false });
  off();
  await new Promise((r) => stream.end(r));
  log('snapshot', file);
}

const fmt = (r) =>
  `${r.label.padEnd(28)} styles=${r.styleElements} heap=${r.jsHeapUsedMB}MB nodes=${r.nodes} listeners=${r.jsEventListeners} docs=${r.documents} attached=${r.attachedElements} rootL=${r.rootListeners} int=${r.intervals} to=${r.pendingTimeouts} raf=${r.pendingRafs} obs=${JSON.stringify(r.observers)} css=${r.cssRules} body=${r.bodyChildren.length}`;

const results = { mode, base: BASE, exercise: EXERCISE, routes: ROUTES.length, rows: [], errors, consoleLogs };

async function pass(label, { doExercise }) {
  let buttons = 0;
  for (const url of ROUTES) {
    const got = await nav(url);
    if (got?.replace(/\/$/, '') !== url) log('WARN', url, '->', got);
    if (doExercise) buttons += await exercise(url).catch((e) => (log('exercise fail', url, e.message), 0));
  }
  await nav(AWAY);
  await sleep(500);
  const r = await measure(label);
  r.buttons = buttons;
  results.rows.push(r);
  log(fmt(r));
  return r;
}

if (mode === 'passes') {
  const passes = Number(args.passes ?? 3);
  results.rows.push(await measure('initial load'));
  log(fmt(results.rows.at(-1)));
  await pass('warm-up 1 (navigate only)', { doExercise: false });
  if (EXERCISE) await pass('warm-up 2 (exercise)', { doExercise: true });
  if (args.snapshots) await snapshot(join(OUT, 'passes-baseline.heapsnapshot'));
  for (let i = 1; i <= passes; i++) {
    await pass(`pass ${i}`, { doExercise: EXERCISE });
  }
  if (args.snapshots) await snapshot(join(OUT, 'passes-final.heapsnapshot'));
} else if (mode === 'routes' || mode === 'bisect') {
  const reps = Number(args.reps ?? 20);
  const routes = mode === 'routes' ? String(args.routes).split(',') : ROUTES;
  results.perRoute = [];
  for (const route of routes) {
    // warm the route once (first-visit caches), then measure reps visits
    await nav(route);
    if (EXERCISE) await exercise(route);
    await nav(AWAY);
    const before = await measure(`${route} before`);
    const slug = route.replace(/[^a-z0-9]+/gi, '_');
    if (args.snapshots) await snapshot(join(OUT, `${slug}-before.heapsnapshot`));
    for (let i = 0; i < reps; i++) {
      await nav(route);
      if (EXERCISE) await exercise(route);
      await nav(AWAY);
    }
    await sleep(500);
    const after = await measure(`${route} after`);
    if (args.snapshots) await snapshot(join(OUT, `${slug}-after.heapsnapshot`));
    const d = {
      route,
      reps,
      dHeapMB: +(after.jsHeapUsedMB - before.jsHeapUsedMB).toFixed(2),
      dNodes: after.nodes - before.nodes,
      dListeners: after.jsEventListeners - before.jsEventListeners,
      dDocuments: after.documents - before.documents,
      dAttached: after.attachedElements - before.attachedElements,
      dRootListeners: after.rootListeners - before.rootListeners,
      dIntervals: after.intervals - before.intervals,
      dTimeouts: after.pendingTimeouts - before.pendingTimeouts,
      dObservers: Object.fromEntries(Object.keys(after.observers).map((k) => [k, after.observers[k] - before.observers[k]])),
      dCssRules: after.cssRules - before.cssRules,
      dStyleElements: after.styleElements - before.styleElements,
      dBodyChildren: after.bodyChildren.length - before.bodyChildren.length,
      newBodyChildren: after.bodyChildren.filter((x, i) => before.bodyChildren[i] !== x),
      listenerDiff: Object.fromEntries(
        Object.keys({ ...before.listeners, ...after.listeners })
          .map((k) => [k, (after.listeners[k] ?? 0) - (before.listeners[k] ?? 0)])
          .filter(([, v]) => v),
      ),
      liveDiff: Object.fromEntries(
        Object.keys({ ...before.live, ...after.live })
          .map((k) => [k, (after.live[k] ?? 0) - (before.live[k] ?? 0)])
          .filter(([, v]) => v > 0),
      ),
    };
    results.perRoute.push({ ...d, before, after });
    log(JSON.stringify(d));
    writeFileSync(join(OUT, `${mode}.json`), JSON.stringify(results, null, 2));
  }
}

if (mode === 'css') {
  // which CSS rules does each visit add? (an unbounded style cache shows up
  // as rules with per-instance values: ids, counters, measured sizes)
  const reps = Number(args.reps ?? 3);
  const rules = () =>
    client.evaluate(`[...document.styleSheets].flatMap((s) => { try { return [...s.cssRules].map((r) => r.cssText) } catch { return [] } })`);
  results.css = [];
  for (const route of String(args.routes).split(',')) {
    await nav(route);
    if (EXERCISE) await exercise(route);
    await nav(AWAY);
    const before = new Set(await rules());
    const perRep = [];
    for (let i = 0; i < reps; i++) {
      await nav(route);
      if (EXERCISE) await exercise(route);
      await nav(AWAY);
      const all = await rules();
      perRep.push(`${all.length} total/${new Set(all).size} unique`);
    }
    const all = await rules();
    const added = all.filter((r) => !before.has(r));
    results.css.push({ route, reps, perRep, added });
    log(route, `+${added.length} rules; per rep: ${perRep.join(', ')}`);
    for (const r of added.slice(0, Number(args.show ?? 12))) console.log('   ', r.slice(0, 400));
  }
}

writeFileSync(join(OUT, `${mode}.json`), JSON.stringify(results, null, 2));
log(`errors: ${errors.length}`);
await client.close();
process.exit(0);
