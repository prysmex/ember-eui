// Tiny Chrome DevTools Protocol client: launches Chromium and talks to one
// page target over the WebSocket that ships with Node >= 22. No dependencies.
import { spawn } from 'node:child_process';
import { mkdtempSync, readFileSync, readdirSync, rmSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export function findChrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const pw = join(homedir(), '.cache/ms-playwright');
  if (existsSync(pw)) {
    const dirs = readdirSyncSafe(pw).filter((d) => d.startsWith('chromium-')).sort();
    for (const d of dirs.reverse()) {
      const p = join(pw, d, 'chrome-linux/chrome');
      if (existsSync(p)) return p;
    }
  }
  return 'google-chrome';
}

function readdirSyncSafe(dir) {
  try {
    return readdirSync(dir);
  } catch {
    return [];
  }
}

export async function launch({ headless = true, width = 1400, height = 1000 } = {}) {
  const userDataDir = mkdtempSync(join(tmpdir(), 'eui-leak-chrome-'));
  const args = [
    `--user-data-dir=${userDataDir}`,
    '--remote-debugging-port=0',
    '--no-first-run',
    '--no-default-browser-check',
    '--no-sandbox',
    '--disable-gpu',
    '--disable-dev-shm-usage', // /dev/shm is 64MB here: ERR_INSUFFICIENT_RESOURCES on chunk loads
    '--disable-extensions',
    '--disable-background-timer-throttling',
    '--disable-renderer-backgrounding',
    '--disable-backgrounding-occluded-windows',
    `--window-size=${width},${height}`,
    // In this sandbox (aarch64, 16K kernel pages) a forced, memory-reducing
    // GC kills the renderer when V8 decommits pooled pages: PartitionAlloc's
    // mprotect CHECK (page_allocator_internals_posix.h:357, errno EINVAL).
    // Discarding them instead avoids it and doesn't change what is retained.
    `--js-flags=${process.env.JS_FLAGS ?? '--no-decommit-pooled-pages,--expose-gc'}`,
    ...(process.env.CHROME_LOG ? ['--enable-logging=stderr'] : []),
    ...(process.env.CHROME_FLAGS ? process.env.CHROME_FLAGS.split(' ') : []),
    ...(headless ? ['--headless=new'] : []),
    'about:blank',
  ];
  const proc = spawn(findChrome(), args, { stdio: ['ignore', 'ignore', 'pipe'] });
  // never orphan Chromium when the crawler dies (timeouts, Ctrl-C)
  process.on('exit', () => proc.kill());
  let stderr = '';
  proc.stderr.on('data', (d) => {
    stderr += d;
    if (stderr.length > 200000) stderr = stderr.slice(-100000);
    if (process.env.CHROME_LOG) process.stderr.write(d);
  });

  const portFile = join(userDataDir, 'DevToolsActivePort');
  for (let i = 0; i < 100 && !existsSync(portFile); i++) await sleep(100);
  if (!existsSync(portFile)) throw new Error(`Chrome did not start:\n${stderr}`);
  await sleep(100);
  const port = Number(readFileSync(portFile, 'utf8').split('\n')[0]);

  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const page = targets.find((t) => t.type === 'page');
  const client = await connect(page.webSocketDebuggerUrl);

  client.close = async () => {
    try {
      await client.send('Browser.close');
    } catch {
      /* already gone */
    }
    proc.kill();
    await sleep(1000);
    try {
      rmSync(userDataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
    } catch {
      /* chrome still writing; a stray temp dir is harmless */
    }
  };
  return client;
}

export function connect(url) {
  return new Promise((resolveConn, rejectConn) => {
    const ws = new WebSocket(url);
    let id = 0;
    const pending = new Map();
    const listeners = new Map();
    const client = {
      send(method, params = {}, timeout = method === 'HeapProfiler.takeHeapSnapshot' ? 600000 : 180000) {
        const msgId = ++id;
        ws.send(JSON.stringify({ id: msgId, method, params }));
        return new Promise((res, rej) => {
          const timer = setTimeout(() => {
            pending.delete(msgId);
            rej(new Error(`${method}: no reply in ${timeout}ms`));
          }, timeout);
          pending.set(msgId, {
            res: (v) => (clearTimeout(timer), res(v)),
            rej: (e) => (clearTimeout(timer), rej(e)),
            method,
          });
        });
      },
      on(event, fn) {
        if (!listeners.has(event)) listeners.set(event, []);
        listeners.get(event).push(fn);
        return () => listeners.set(event, listeners.get(event).filter((f) => f !== fn));
      },
      async evaluate(expression, { awaitPromise = true } = {}) {
        const params = { expression, awaitPromise, returnByValue: true };
        let r;
        try {
          r = await client.send('Runtime.evaluate', params);
        } catch (e) {
          // the sandbox VM is sometimes suspended for minutes; give the page
          // one more chance before calling it hung
          if (!/no reply/.test(e.message)) throw e;
          console.error(`[cdp] evaluate timed out, retrying once: ${expression.slice(0, 80)}`);
          r = await client.send('Runtime.evaluate', params);
        }
        if (r.exceptionDetails) {
          throw new Error(
            `evaluate failed: ${r.exceptionDetails.exception?.description ?? r.exceptionDetails.text}`,
          );
        }
        return r.result.value;
      },
    };
    ws.addEventListener('open', () => resolveConn(client));
    ws.addEventListener('error', (e) => rejectConn(e));
    ws.addEventListener('message', (ev) => {
      const msg = JSON.parse(typeof ev.data === 'string' ? ev.data : ev.data.toString());
      if (msg.id) {
        const p = pending.get(msg.id);
        if (!p) return;
        pending.delete(msg.id);
        if (msg.error) p.rej(new Error(`${p.method}: ${msg.error.message}`));
        else p.res(msg.result);
      } else if (msg.method) {
        for (const fn of listeners.get(msg.method) ?? []) fn(msg.params);
      }
    });
  });
}
