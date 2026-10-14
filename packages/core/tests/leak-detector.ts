/* eslint-disable */
// @ts-nocheck -- test-only instrumentation, deliberately loose
/**
 * Opt-in leak instrumentation for the core test suite.
 *
 * Enabled only by the `leaks` query param (`tests/index.html?leaks`), which
 * `EUI_LEAKS=1 testem --file testem.cjs ci` adds; normal runs never patch
 * anything. It is loaded from the first <script type="module"> in
 * tests/index.html so the patches land before Ember, QUnit, focus-trap or any
 * component module runs.
 *
 * Per test (attributed from QUnit.testStart to QUnit.testDone, and to any
 * timer/rAF/observer callback chain that started inside the test) it tracks:
 * - add/removeEventListener on every target, with the add-time stack. After
 *   teardown, listeners still on window, document, <html>, <body>,
 *   visualViewport, a MediaQueryList, or on a connected element outside the
 *   QUnit UI are reported. Listeners on detached elements are dropped (the
 *   WeakRef checks catch detached DOM that is still retained).
 * - Resize/Mutation/IntersectionObserver construction, observe, disconnect.
 * - setTimeout/setInterval/requestAnimationFrame/requestIdleCallback and their
 *   clears, plus callbacks that still run after the owning test finished.
 * - Ember run loop timers (`later`/`debounce`/`throttle`) still scheduled.
 *   Normally 0, because teardownContext() awaits settled().
 * - focus-trap: classified from the add-time stack of document listeners
 *   (focus-trap's activate() adds them, deactivate() removes them).
 * - Children appended to <body> (portals) and <head> growth (styles).
 * - WeakRefs to the test's owner, #ember-testing root and every component
 *   instance in the debug render tree (on Ember 7, render() goes through
 *   renderComponent's strict renderer, whose render tree the public
 *   captureRenderTree(owner) does not see, so in practice only the owner and
 *   the root, which retains the whole rendered subtree, are tracked), captured right after the test body
 *   (the test callback is wrapped at testStart), before setupRenderingTest's
 *   teardown. The report test at the end forces gc() and lists survivors;
 *   it tags a few surviving owners/roots with `LeakTag` objects so a heap
 *   snapshot (scripts/leak-cdp.mjs --snapshot) can show what retains them.
 *
 * Evaluation of test N happens in the global beforeEach of test N+1, after a
 * macrotask and an animation frame, so zero-delay cleanups scheduled during
 * teardown are not reported.
 */

/** Marker hung on surviving objects, searchable by name in heap snapshots. */
class LeakTag {
  constructor(
    public seq: number,
    public kind: string,
    public label: string,
    public test: string
  ) {}
}

export const LEAKS_ENABLED =
  typeof location !== 'undefined' &&
  new URLSearchParams(location.search).has('leaks');

const native = {
  setTimeout: window.setTimeout,
  clearTimeout: window.clearTimeout,
  setInterval: window.setInterval,
  clearInterval: window.clearInterval,
  requestAnimationFrame: window.requestAnimationFrame,
  cancelAnimationFrame: window.cancelAnimationFrame,
  requestIdleCallback: window.requestIdleCallback,
  cancelIdleCallback: window.cancelIdleCallback,
  addEventListener: EventTarget.prototype.addEventListener,
  removeEventListener: EventTarget.prototype.removeEventListener,
  ResizeObserver: window.ResizeObserver,
  MutationObserver: window.MutationObserver,
  IntersectionObserver: window.IntersectionObserver
};

export interface TestInfo {
  seq: number;
  module: string;
  name: string;
  finished: boolean;
  evaluated: boolean;
  items: any[];
  post: Record<string, { count: number; stack: string }>;
  refs: { kind: string; label: string; ref: WeakRef<object> }[];
  heapAfter?: number;
}

const state = {
  current: null as TestInfo | null,
  origin: null as TestInfo | null, // set while running a callback chain
  seq: 0,
  tests: [] as TestInfo[],
  listeners: new Set<any>(),
  listenerIndex: new WeakMap<EventTarget, any[]>(),
  timers: new Map<number, any>(),
  rafs: new Map<number, any>(),
  idles: new Map<number, any>(),
  observers: new Set<any>(),
  globalItems: [] as any[],
  heapSamples: [] as any[],
  growth: [] as any[]
};

(window as any).__leakState = state;

function stack(): string {
  const s = new Error().stack || '';
  return s.split('\n').slice(2).join('\n');
}

function origin(): TestInfo | null {
  return state.origin ?? state.current;
}

function runAs<T>(o: TestInfo | null, kind: string, s: string, fn: () => T): T {
  if (o && o.finished) {
    const p = (o.post[kind] ??= { count: 0, stack: s });
    p.count++;
  }
  const prev = state.origin;
  state.origin = o;
  try {
    return fn();
  } finally {
    state.origin = prev;
  }
}

function describeTarget(t: any): string {
  if (t === window) return 'window';
  if (t === document) return 'document';
  if (t === document.documentElement) return 'html';
  if (t === document.body) return 'body';
  if (typeof MediaQueryList !== 'undefined' && t instanceof MediaQueryList)
    return `MediaQueryList(${t.media})`;
  if (t === window.visualViewport) return 'visualViewport';
  if (t instanceof Element) {
    const cls = typeof t.className === 'string' ? t.className.split(/\s+/).filter((c) => c.startsWith('eui') || c.startsWith('ember')).slice(0, 2).join('.') : '';
    return `<${t.tagName.toLowerCase()}${t.id ? '#' + t.id : ''}${cls ? '.' + cls : ''}>`;
  }
  return t?.constructor?.name ?? String(t);
}

function isGlobalTarget(t: any) {
  return (
    t === window ||
    t === document ||
    t === document.documentElement ||
    t === document.body ||
    t === window.visualViewport ||
    (typeof MediaQueryList !== 'undefined' && t instanceof MediaQueryList)
  );
}

function captureFlag(options: any) {
  return typeof options === 'boolean' ? options : !!options?.capture;
}

function classify(s: string): string {
  if (/focus-trap/.test(s)) return 'focus-trap';
  if (/ember-basic-dropdown|basic-dropdown/i.test(s)) return 'ember-basic-dropdown';
  if (/qunit/i.test(s)) return 'qunit';
  if (/@ember\/test-helpers|test-helpers/.test(s)) return 'test-helpers';
  return '';
}

function install() {
  Error.stackTraceLimit = 40;

  // --- event listeners -----------------------------------------------------
  EventTarget.prototype.addEventListener = function (type, listener, options) {
    if (listener) {
      const capture = captureFlag(options);
      const list = state.listenerIndex.get(this) ?? [];
      const dup = list.find(
        (r) => r.type === type && r.capture === capture && r.listener.deref() === listener
      );
      if (!dup) {
        const o = origin();
        const s = stack();
        const strong = isGlobalTarget(this);
        const rec = {
          type,
          capture,
          once: typeof options === 'object' && !!options?.once,
          listener: new WeakRef(listener),
          target: strong ? null : new WeakRef(this),
          strongTarget: strong ? this : null,
          origin: o,
          stack: s,
          reported: false
        };
        list.push(rec);
        state.listenerIndex.set(this, list);
        if (o) state.listeners.add(rec);
        const signal = typeof options === 'object' ? options?.signal : null;
        if (signal) {
          const drop = () => {
            const i = list.indexOf(rec);
            if (i >= 0) list.splice(i, 1);
            state.listeners.delete(rec);
          };
          if (signal.aborted) drop();
          else native.addEventListener.call(signal, 'abort', drop, { once: true });
        }
      }
    }
    return native.addEventListener.call(this, type, listener, options);
  };

  EventTarget.prototype.removeEventListener = function (type, listener, options) {
    const list = state.listenerIndex.get(this);
    if (list && listener) {
      const capture = captureFlag(options);
      const i = list.findIndex(
        (r) => r.type === type && r.capture === capture && r.listener.deref() === listener
      );
      if (i >= 0) {
        state.listeners.delete(list[i]);
        list.splice(i, 1);
      }
    }
    return native.removeEventListener.call(this, type, listener, options);
  };

  if (typeof MediaQueryList !== 'undefined') {
    const add = MediaQueryList.prototype.addListener;
    const remove = MediaQueryList.prototype.removeListener;
    // the deprecated API routes through addEventListener('change') in Chromium,
    // keep it explicit anyway
    MediaQueryList.prototype.addListener = function (l) {
      return this.addEventListener('change', l);
    };
    MediaQueryList.prototype.removeListener = function (l) {
      return this.removeEventListener('change', l);
    };
    void add;
    void remove;
  }

  // --- timers ----------------------------------------------------------------
  const wrapTimer = (kind: string, repeat: boolean) =>
    function (fn: any, ms?: number, ...args: any[]) {
      const o = origin();
      const s = stack();
      const rec = { kind, ms: ms ?? 0, origin: o, stack: s, id: 0, reported: false };
      const nativeFn = repeat ? native.setInterval : native.setTimeout;
      const id = nativeFn.call(
        window,
        function (this: any) {
          if (!repeat) state.timers.delete(id);
          return runAs(o, kind, s, () =>
            typeof fn === 'function' ? fn.apply(this, args) : (0, eval)(fn)
          );
        },
        ms
      );
      rec.id = id;
      state.timers.set(id, rec);
      return id;
    };
  window.setTimeout = wrapTimer('setTimeout', false) as any;
  window.setInterval = wrapTimer('setInterval', true) as any;
  window.clearTimeout = window.clearInterval = function (id: any) {
    state.timers.delete(id);
    return native.clearTimeout.call(window, id);
  } as any;

  window.requestAnimationFrame = function (fn) {
    const o = origin();
    const s = stack();
    const id = native.requestAnimationFrame.call(window, (t) => {
      state.rafs.delete(id);
      return runAs(o, 'requestAnimationFrame', s, () => fn(t));
    });
    state.rafs.set(id, { kind: 'requestAnimationFrame', origin: o, stack: s, reported: false });
    return id;
  };
  window.cancelAnimationFrame = function (id) {
    state.rafs.delete(id);
    return native.cancelAnimationFrame.call(window, id);
  };
  if (native.requestIdleCallback) {
    window.requestIdleCallback = function (fn, opts) {
      const o = origin();
      const s = stack();
      const id = native.requestIdleCallback.call(
        window,
        (d) => {
          state.idles.delete(id);
          return runAs(o, 'requestIdleCallback', s, () => fn(d));
        },
        opts
      );
      state.idles.set(id, { kind: 'requestIdleCallback', origin: o, stack: s, reported: false });
      return id;
    };
    window.cancelIdleCallback = function (id) {
      state.idles.delete(id);
      return native.cancelIdleCallback.call(window, id);
    };
  }

  // --- observers -------------------------------------------------------------
  for (const name of ['ResizeObserver', 'MutationObserver', 'IntersectionObserver']) {
    const Native = native[name];
    if (!Native) continue;
    const Patched = class extends Native {
      constructor(cb: any, opts?: any) {
        const o = origin();
        const s = stack();
        const rec = {
          kind: name,
          origin: o,
          stack: s,
          targets: [] as WeakRef<Element>[],
          disconnected: false,
          reported: false,
          self: null as any
        };
        super(function (this: any, ...a: any[]) {
          return runAs(o, name, s, () => cb.apply(this, a));
        }, opts);
        rec.self = new WeakRef(this);
        (this as any).__leakRec = rec;
        if (o) state.observers.add(rec);
      }
      observe(target: any, opts?: any) {
        const rec = (this as any).__leakRec;
        if (!rec.targets.some((r) => r.deref() === target)) rec.targets.push(new WeakRef(target));
        rec.disconnected = false;
        return super.observe(target, opts);
      }
      unobserve(target: any) {
        const rec = (this as any).__leakRec;
        rec.targets = rec.targets.filter((r) => r.deref() && r.deref() !== target);
        return super.unobserve(target);
      }
      disconnect() {
        const rec = (this as any).__leakRec;
        rec.disconnected = true;
        rec.targets = [];
        state.observers.delete(rec);
        return super.disconnect();
      }
    };
    Object.defineProperty(Patched, 'name', { value: name });
    window[name] = Patched;
  }
}

// --- evaluation --------------------------------------------------------------

const baselineBodyIds = new Set(['qunit', 'qunit-fixture']);

function isQunitUi(el: Element) {
  const q = document.getElementById('qunit');
  return !!q && q.contains(el);
}

function extraBodyChildren(): Element[] {
  return [...document.body.children].filter(
    (el) => !baselineBodyIds.has(el.id) && el.tagName !== 'SCRIPT'
  );
}

function bodyChildLabel(el: Element) {
  return describeTarget(el) + ` (${el.querySelectorAll('*').length} descendants)`;
}

let seenBodyChildren = new WeakSet<Element>();

export function evaluate(test: TestInfo, final = false) {
  if (test.evaluated) return;
  test.evaluated = true;

  for (const rec of [...state.listeners]) {
    if (rec.origin !== test || rec.reported) continue;
    const t = rec.strongTarget ?? rec.target?.deref();
    if (!t || !rec.listener.deref()) {
      state.listeners.delete(rec);
      continue;
    }
    let where: string | null = null;
    if (isGlobalTarget(t)) where = describeTarget(t);
    else if (t instanceof Element && t.isConnected && !isQunitUi(t)) where = describeTarget(t);
    if (!where) {
      // detached element / other short-lived target: stop tracking
      state.listeners.delete(rec);
      continue;
    }
    rec.reported = true;
    test.items.push({
      kind: 'listener',
      detail: `${where} ${rec.type}${rec.capture ? ' (capture)' : ''}${rec.once ? ' (once)' : ''}`,
      category: classify(rec.stack),
      stack: rec.stack
    });
  }

  for (const rec of [...state.observers]) {
    if (rec.origin !== test || rec.reported) continue;
    rec.targets = rec.targets.filter((r) => r.deref());
    if (rec.disconnected || rec.targets.length === 0) {
      if (rec.targets.length === 0 && !rec.disconnected) {
        // never observed anything or all targets collected: harmless
        if (!rec.self.deref()) state.observers.delete(rec);
      }
      continue;
    }
    const connected = rec.targets.filter((r) => r.deref()?.isConnected && !isQunitUi(r.deref()));
    rec.reported = true;
    test.items.push({
      kind: 'observer',
      detail: `${rec.kind} not disconnected, ${rec.targets.length} target(s) alive, ${connected.length} connected: ${rec.targets
        .slice(0, 3)
        .map((r) => describeTarget(r.deref()))
        .join(', ')}`,
      connectedTargets: connected.length,
      category: classify(rec.stack),
      stack: rec.stack
    });
  }

  for (const [map, label] of [
    [state.timers, 'timer'],
    [state.rafs, 'raf'],
    [state.idles, 'idle']
  ] as const) {
    for (const rec of map.values()) {
      if (rec.origin !== test || rec.reported) continue;
      rec.reported = true;
      test.items.push({
        kind: 'pending-' + label,
        detail: `${rec.kind}${rec.ms !== undefined ? `(${rec.ms}ms)` : ''} still pending`,
        category: classify(rec.stack),
        stack: rec.stack
      });
    }
  }

  for (const el of extraBodyChildren()) {
    if (seenBodyChildren.has(el)) continue;
    seenBodyChildren.add(el);
    test.items.push({ kind: 'body-child', detail: bodyChildLabel(el), category: '', stack: '' });
  }

  try {
    const bb = (window as any).__leakBackburner;
    if (bb && bb.hasTimers()) {
      test.items.push({
        kind: 'runloop-timers',
        detail: `@ember/runloop has ${bb._timers.length / 2} scheduled timer(s) after teardown`,
        category: '',
        stack: ''
      });
    }
  } catch {}

  void final;
}

function evaluatePending(final = false) {
  for (const t of state.tests) if (t.finished && !t.evaluated) evaluate(t, final);
}

function macrotask() {
  return new Promise((r) => native.setTimeout.call(window, r, 0));
}
function frame() {
  return new Promise((r) => native.requestAnimationFrame.call(window, () => r(undefined)));
}

export async function forceGc(rounds = 6) {
  const gc = (window as any).gc;
  for (let i = 0; i < rounds; i++) {
    if (gc) gc();
    await macrotask();
  }
}

export function usedHeap(): number | undefined {
  return (performance as any).memory?.usedJSHeapSize;
}

/** Live counts across all tests, for the growth measurements. */
export function liveCounts() {
  let globalListeners = 0;
  let connectedElementListeners = 0;
  for (const list of [window, document, document.documentElement, document.body]) {
    globalListeners += (state.listenerIndex.get(list) ?? []).length;
  }
  for (const rec of state.listeners) {
    const t = rec.target?.deref();
    if (t instanceof Element && t.isConnected && !isQunitUi(t)) connectedElementListeners++;
  }
  let observers = 0;
  for (const rec of state.observers) {
    if (!rec.disconnected && rec.targets.some((r) => r.deref())) observers++;
  }
  let cssRules = 0;
  for (const sheet of [...document.styleSheets]) {
    try {
      cssRules += sheet.cssRules.length;
    } catch {}
  }
  return {
    globalListeners,
    connectedElementListeners,
    observers,
    timers: state.timers.size,
    rafs: state.rafs.size,
    bodyChildren: extraBodyChildren().length,
    headChildren: document.head.childElementCount,
    cssRules
  };
}

function captureRefs(test: TestInfo, ctx: any, captureRenderTree: any) {
  const add = (kind: string, label: string, obj: any) => {
    if (obj && (typeof obj === 'object' || typeof obj === 'function')) {
      test.refs.push({ kind, label, ref: new WeakRef(obj) });
    }
  };
  add('root', '#ember-testing', document.getElementById('ember-testing'));
  if (ctx?.owner) {
    add('owner', 'owner', ctx.owner);
    try {
      const walk = (nodes: any[]) => {
        for (const n of nodes) {
          if (n.type === 'component' && n.instance && typeof n.instance === 'object') {
            add('component', n.name, n.instance);
          }
          if (n.type === 'modifier' && n.instance && typeof n.instance === 'object') {
            add('modifier', n.name, n.instance);
          }
          walk(n.children ?? []);
        }
      };
      walk(captureRenderTree(ctx.owner));
    } catch (e) {
      (state as any).renderTreeError ??= String(e);
    }
  }
}

function post(report: any) {
  const body = JSON.stringify(report);
  return fetch('/__leak-report', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body
  }).catch(() => {
    (window as any).__leakReport = report;
  });
}

export function serializeTest(t: TestInfo) {
  return {
    seq: t.seq,
    module: t.module,
    name: t.name,
    items: t.items,
    post: t.post
  };
}

/**
 * Installs the QUnit hooks. Call from test-helper's start() before
 * qunitStart(); defines the final report module, so call it after the test
 * modules are imported.
 */
export function installLeakHooks(
  QUnit: any,
  deps: { captureRenderTree: any; backburner: any }
) {
  if (!LEAKS_ENABLED) return;
  (window as any).__leakBackburner = deps.backburner;
  QUnit.config.reorder = false;
  QUnit.config.testTimeout = Math.max(QUnit.config.testTimeout ?? 0, 120000);

  QUnit.log((d: any) => {
    if (!d.result) {
      console.warn(`[leak-mode failure] ${d.module} :: ${d.name} :: ${d.message ?? ''} (actual ${JSON.stringify(d.actual)}, expected ${JSON.stringify(d.expected)}) ${String(d.source ?? '').slice(0, 600)}`);
    }
  });

  QUnit.testStart(({ module, name }: any) => {
    const t: TestInfo = {
      seq: ++state.seq,
      module,
      name,
      finished: false,
      evaluated: false,
      items: [],
      post: {},
      refs: []
    };
    state.tests.push(t);
    state.current = t;
    // Capture WeakRefs right after the test body, before any afterEach hook
    // (setupRenderingTest's teardown) runs.
    const qtest = QUnit.config.current;
    const orig = qtest?.callback;
    if (typeof orig === 'function' && !orig.__leakWrapped) {
      const wrapped = function (this: any, ...a: any[]) {
        const after = () => captureRefs(t, this, deps.captureRenderTree);
        const r = orig.apply(this, a);
        if (r && typeof r.then === 'function') {
          return r.then(
            (v: any) => (after(), v),
            (e: any) => {
              after();
              throw e;
            }
          );
        }
        after();
        return r;
      };
      wrapped.__leakWrapped = true;
      if (orig.validTest) wrapped.validTest = true;
      qtest.callback = wrapped;
    }
  });

  QUnit.testDone(() => {
    if (state.current) state.current.finished = true;
    state.current = null;
  });

  QUnit.hooks.beforeEach(async function () {
    // let teardown's zero-delay work settle, then judge the previous test(s)
    const prev = state.current;
    state.current = null;
    await macrotask();
    await frame();
    await macrotask();
    evaluatePending();
    if (state.seq % 100 === 0) {
      await forceGc(3);
      state.heapSamples.push({ seq: state.seq, heap: usedHeap(), counts: liveCounts() });
    }
    state.current = prev;
  });


  QUnit.module('zz leak-detector | report', function () {
    const report = async function (assert: any) {
      state.current = null;
      console.log('[leaks] report: start');
      await macrotask();
      await frame();
      await macrotask();
      console.log('[leaks] report: evaluate');
      evaluatePending(true);
      console.log('[leaks] report: gc');
      const hasGc = typeof (window as any).gc === 'function';
      await forceGc(10);
      console.log('[leaks] report: survivors');
      const survivors: any[] = [];
      let tagged = 0;
      for (const t of state.tests) {
        const alive = t.refs.filter((r) => r.ref.deref() !== undefined);
        // tag survivors for heap-snapshot retainer analysis
        for (const r of alive) {
          if (tagged < 400 && (r.kind !== 'component' || tagged < 300)) {
            const obj: any = r.ref.deref();
            try {
              obj.__leakTag = new LeakTag(t.seq, r.kind, r.label, `${t.module} :: ${t.name}`);
              tagged++;
            } catch {}
          }
        }
        if (alive.length) {
          const byKind: Record<string, string[]> = {};
          for (const r of alive) (byKind[r.kind] ??= []).push(r.label);
          survivors.push({ seq: t.seq, module: t.module, name: t.name, total: t.refs.length, alive: byKind });
        }
      }
      // late activity: callbacks that ran after their test finished
      const result = {
        createdAt: new Date().toISOString(),
        userAgent: navigator.userAgent,
        hasGc,
        renderTreeError: (state as any).renderTreeError ?? null,
        testCount: state.tests.length,
        capturedRefs: state.tests.reduce((acc: Record<string, number>, t) => {
          for (const r of t.refs) acc[r.kind] = (acc[r.kind] ?? 0) + 1;
          return acc;
        }, {}),
        heapSamples: state.heapSamples,
        finalHeap: usedHeap(),
        finalCounts: liveCounts(),
        growth: state.growth,
        tests: state.tests
          .filter((t) => t.items.length || Object.keys(t.post).length)
          .map(serializeTest),
        survivors
      };
      (window as any).__leakReport = result;
      console.log('[leaks] report: post');
      await post(result);
      assert.ok(true, `leak report: ${result.tests.length} tests with items, ${survivors.length} with survivors, gc=${hasGc}`);
    };
    // QUnit's internal flag: runs even when ?filter / ?module select other tests
    (report as any).validTest = true;
    QUnit.test('collect and post the leak report', report);
  });
}

/** For tests that measure growth (only meaningful with ?leaks). */
export const leakState = state;

if (LEAKS_ENABLED) install();
