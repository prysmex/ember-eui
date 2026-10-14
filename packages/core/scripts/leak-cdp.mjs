#!/usr/bin/env node
/**
 * Leak-mode runner driven over the Chrome DevTools Protocol (no testem).
 * Serves dist-tests, opens tests/index.html?leaks[&filter=…], streams progress
 * and console errors, saves the report, and can take a heap snapshot at the
 * end to explain what retains surviving objects.
 *
 *   node scripts/leak-cdp.mjs [--filter <qunit filter>] [--out leak-report.json]
 *        [--snapshot <file.heapsnapshot>] [--port 9333] [--extra '&growth']
 *
 * Needs `google-chrome` (or $CHROME) on PATH and a prior
 * `vite build --mode=development --out-dir dist-tests`.
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const dist = path.join(root, 'dist-tests');

const args = process.argv.slice(2);
const opt = (name, def) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : def;
};
const filter = opt('filter', '');
const out = path.resolve(root, opt('out', 'leak-report.json'));
const snapshot = opt('snapshot', '');
const cdpPort = Number(opt('port', '9333'));
const extra = opt('extra', '');
const timeoutMin = Number(opt('timeout', '30'));

const types = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.svg': 'image/svg+xml',
  '.json': 'application/json',
  '.png': 'image/png',
  '.woff2': 'font/woff2'
};

let reportResolve;
const reportReceived = new Promise((r) => (reportResolve = r));

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  if (req.method === 'POST' && url.pathname === '/__leak-report') {
    let body = '';
    req.setEncoding('utf8');
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      fs.writeFileSync(out, body);
      res.writeHead(204).end();
      reportResolve();
    });
    return;
  }
  if (url.pathname === '/testem.js') {
    res.writeHead(200, { 'content-type': 'text/javascript' }).end('');
    return;
  }
  const file = path.join(dist, decodeURIComponent(url.pathname));
  if (!file.startsWith(dist) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404).end();
    return;
  }
  res.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const httpPort = server.address().port;

const userDir = fs.mkdtempSync('/tmp/leak-cdp-');
const chrome = spawn(
  process.env.CHROME || 'google-chrome',
  [
    '--no-sandbox',
    '--headless=old', // forced gc() crashes --headless=new here, see testem.cjs
    '--disable-dev-shm-usage',
    '--disable-software-rasterizer',
    '--disable-gpu',
    '--mute-audio',
    `--remote-debugging-port=${cdpPort}`,
    `--user-data-dir=${userDir}`,
    '--window-size=1440,900',
    '--js-flags=--expose-gc',
    // old headless throttles rAF/timers once a test opens another window
    '--disable-background-timer-throttling',
    '--disable-renderer-backgrounding',
    '--disable-backgrounding-occluded-windows',
    '--block-new-web-contents', // tests click links with target=_blank
    '--enable-precise-memory-info',
    'about:blank'
  ],
  { stdio: ['ignore', 'ignore', 'pipe'] }
);
chrome.stderr.on('data', (d) => {
  if (process.env.LEAK_CHROME_LOG) process.stderr.write(d);
});

async function getJson(p) {
  for (let i = 0; i < 100; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${cdpPort}${p}`);
      return await r.json();
    } catch {
      await new Promise((r) => setTimeout(r, 200));
    }
  }
  throw new Error('chrome did not start');
}

const targets = await getJson('/json/list');
const page = targets.find((t) => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));

let msgId = 0;
const pending = new Map();
const listeners = new Map();
ws.addEventListener('message', (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
  } else if (msg.method) {
    for (const fn of listeners.get(msg.method) ?? []) fn(msg.params);
  }
});
const send = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const id = ++msgId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });
const on = (method, fn) => listeners.set(method, [...(listeners.get(method) ?? []), fn]);

await send('Runtime.enable');
on('Runtime.exceptionThrown', (p) =>
  console.log('[exception]', p.exceptionDetails?.exception?.description?.slice(0, 400))
);
on('Runtime.consoleAPICalled', (p) => {
  if (p.type === 'error' || p.type === 'warning' || process.env.LEAK_VERBOSE) {
    const text = p.args.map((a) => a.value ?? a.description ?? '').join(' ');
    console.log(`[console.${p.type}]`, text.slice(0, 400));
  }
});

const q = `?hidepassed${args.includes('--plain') ? '' : '&leaks'}${filter ? `&filter=${encodeURIComponent(filter)}` : ''}${extra}`;
// report (and close) windows a test opens, e.g. links with target=_blank
await send('Target.setDiscoverTargets', { discover: true });
on('Target.targetCreated', async ({ targetInfo }) => {
  if (targetInfo.type === 'page' && targetInfo.targetId !== page.id) {
    const cur = await evaluate('window.__leakState?.current?.name').catch(() => '?');
    console.log(`[window-opened] ${targetInfo.url} during: ${cur}`);
    send('Target.closeTarget', { targetId: targetInfo.targetId }).catch(() => {});
  }
});
await send('Page.enable');
// testem's real window has focus; headless CDP pages need it emulated
await send('Emulation.setFocusEmulationEnabled', { enabled: true });
await send('Page.navigate', { url: `http://127.0.0.1:${httpPort}/tests/index.html${q}` });
console.log(`[leaks] running tests/index.html${q}`);

const evaluate = async (expression) =>
  Promise.race([
    send('Runtime.evaluate', { expression, returnByValue: true }).then((r) => r.result.value),
    new Promise((_, reject) => setTimeout(() => reject(new Error('main thread busy')), 15000))
  ]);

const started = Date.now();
let last = '';
let lastChange = Date.now();
let done = false;
reportReceived.then(() => (done = true));
while (!done) {
  await new Promise((r) => setTimeout(r, 5000));
  let status;
  try {
    status = await evaluate(
      `JSON.stringify({ seq: window.__leakState?.seq, cur: window.__leakState?.current && (window.__leakState.current.module + ' :: ' + window.__leakState.current.name), stats: window.QUnit?.config?.stats, t: Math.round(performance.now() / 1000), heapMB: Math.round(performance.memory.usedJSHeapSize / 1e6), L: window.__leakState?.listeners.size, T: window.__leakState?.timers.size, R: window.__leakState?.rafs.size, O: window.__leakState?.observers.size })`
    );
  } catch (e) {
    status = 'evaluate failed: ' + e.message;
  }
  if (process.env.LEAK_TRY_CDPGC && /testCount":1[0-9][0-9]/.test(String(status))) {
    const t0 = Date.now();
    await send('HeapProfiler.collectGarbage').catch((e) => console.log('cdp gc failed', e.message));
    console.log('[try-cdp-gc] ok in', Date.now() - t0, 'ms', await evaluate('performance.memory.usedJSHeapSize').catch((e) => e.message));
  }
  if (process.env.LEAK_TRY_GC && /testCount":1[0-9][0-9]/.test(String(status))) {
    console.log('[try-gc]', await evaluate(process.env.LEAK_TRY_GC_EXPR || '(gc(), "gc ok " + performance.memory.usedJSHeapSize)').catch((e) => e.message));
  }
  if (status !== last) {
    last = status;
    lastChange = Date.now();
    console.log('[progress]', status);
  } else if (Date.now() - lastChange > Number(opt('stuck', '120')) * 1000) {
    console.log('[stuck] no progress at', status);
    // the main thread may be blocked: pause it and print where
    await send('Debugger.enable');
    const paused = new Promise((r) => on('Debugger.paused', r));
    await send('Debugger.pause');
    const p = await Promise.race([paused, new Promise((r) => setTimeout(() => r(null), 10000))]);
    if (p) {
      for (const f of p.callFrames.slice(0, 25)) {
        console.log(`[stuck]   at ${f.functionName || '<anon>'} ${f.url.replace(/.*\//, '')}:${f.location.lineNumber + 1}`);
      }
      await send('Debugger.resume');
    }
    console.log(
      '[stuck] qunit current:',
      await evaluate(`JSON.stringify({ test: QUnit.config.current?.testName, module: QUnit.config.current?.module?.name, timers: window.__leakState?.timers.size, rafs: window.__leakState?.rafs.size, queue: QUnit.config.queue?.length, blocking: QUnit.config.blocking })`)
    );
    break;
  }
  if (Date.now() - started > timeoutMin * 60000) {
    console.log('[timeout]');
    break;
  }
}

if (done) {
  console.log(`[leaks] report written to ${out}`);
  if (snapshot) {
    await send('HeapProfiler.enable');
    await send('HeapProfiler.collectGarbage');
    const chunks = [];
    on('HeapProfiler.addHeapSnapshotChunk', (p) => chunks.push(p.chunk));
    await send('HeapProfiler.takeHeapSnapshot', { reportProgress: false });
    fs.writeFileSync(snapshot, chunks.join(''));
    console.log(`[leaks] heap snapshot written to ${snapshot}`);
  }
}

ws.close();
chrome.kill('SIGTERM');
await new Promise((r) => {
  chrome.once('exit', r);
  setTimeout(r, 5000);
});
server.close();
try {
  fs.rmSync(userDir, { recursive: true, force: true, maxRetries: 5 });
} catch {
  // chrome may still hold files; the temp dir is harmless
}
process.exit(done ? 0 : 1);
