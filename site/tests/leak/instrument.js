// Injected before any page script (Page.addScriptToEvaluateOnNewDocument).
// Counts the resources a torn-down component could forget to release:
// listeners on the long-lived roots (window, document, <html>, <body>),
// live intervals, pending timeouts / animation frames, and observers that
// observe without having been disconnected. Counters only: it never keeps
// a reference to something the page has already released.
(() => {
  const L = (window.__leak = {
    listeners: new Map(), // "target|type|capture" -> Set(listener)
    intervals: new Set(),
    timeouts: new Set(),
    rafs: new Set(),
    timeoutTokens: new Map(),
    observers: { ResizeObserver: 0, MutationObserver: 0, IntersectionObserver: 0 },
    observerCreated: { ResizeObserver: 0, MutationObserver: 0, IntersectionObserver: 0 },
  });

  // creation stacks of live observers / root listeners, for attribution
  L.live = new Map(); // token -> { kind, stack }
  let token = 0;
  const stack = () =>
    (new Error().stack || '')
      .split('\n')
      .slice(3, 11)
      .map((l) => l.trim().replace(/^at /, '').replace(/https?:\/\/[^/]+\/assets\//, '').replace(/-[A-Za-z0-9_-]{8}\.js/, '.js'))
      .join(' < ');
  const liveTokens = new WeakMap(); // observer / listener fn -> token
  const rootName = (t) =>
    t === window
      ? 'window'
      : t === document
        ? 'document'
        : t === document.documentElement
          ? 'html'
          : t && t === document.body
            ? 'body'
            : null;
  const capOf = (o) => (typeof o === 'boolean' ? o : !!(o && o.capture));

  const forget = (key, fn) => {
    L.listeners.get(key)?.delete(fn);
    const m = liveTokens.get(fn);
    if (m?.has(key)) {
      L.live.delete(m.get(key));
      m.delete(key);
    }
  };
  const add = EventTarget.prototype.addEventListener;
  const remove = EventTarget.prototype.removeEventListener;
  EventTarget.prototype.addEventListener = function (type, fn, opts) {
    const name = rootName(this);
    if (name && fn) {
      const key = `${name}|${type}|${capOf(opts)}`;
      let set = L.listeners.get(key);
      if (!set) L.listeners.set(key, (set = new Set()));
      if (!set.has(fn)) {
        set.add(fn);
        const t = ++token;
        let m = liveTokens.get(fn);
        if (!m) liveTokens.set(fn, (m = new Map()));
        m.set(key, t);
        L.live.set(t, { kind: key, stack: stack() });
      }
      // { signal } removal
      if (opts && typeof opts === 'object' && opts.signal) {
        opts.signal.addEventListener('abort', () => forget(key, fn), { once: true });
      }
      if (opts && typeof opts === 'object' && opts.once) {
        // approximate: once-listeners drop after the first event
        add.call(this, type, () => forget(key, fn), { once: true, capture: capOf(opts) });
      }
    }
    return add.call(this, type, fn, opts);
  };
  EventTarget.prototype.removeEventListener = function (type, fn, opts) {
    const name = rootName(this);
    if (name && fn) {
      forget(`${name}|${type}|${capOf(opts)}`, fn);
    }
    return remove.call(this, type, fn, opts);
  };

  const si = window.setInterval;
  const ci = window.clearInterval;
  const st = window.setTimeout;
  const ct = window.clearTimeout;
  window.setInterval = function (...a) {
    const id = si.apply(this, a);
    L.intervals.add(id);
    return id;
  };
  window.clearInterval = function (id) {
    L.intervals.delete(id);
    return ci.call(this, id);
  };
  window.setTimeout = function (fn, ...rest) {
    let id;
    const wrapped =
      typeof fn === 'function'
        ? function (...args) {
            L.timeouts.delete(id);
            L.timeoutTokens.delete(id);
            return fn.apply(this, args);
          }
        : fn;
    id = st.call(this, wrapped, ...rest);
    L.timeouts.add(id);
    // long timers are the ones that can outlive a component: keep their stack
    if (Number(rest[0]) >= 500) L.timeoutTokens.set(id, `timeout(${rest[0]}ms) @ ${stack()}`);
    return id;
  };
  window.clearTimeout = function (id) {
    L.timeouts.delete(id);
    L.timeoutTokens.delete(id);
    // clearTimeout and clearInterval share one id space
    L.intervals.delete(id);
    return ct.call(this, id);
  };
  const raf = window.requestAnimationFrame;
  const caf = window.cancelAnimationFrame;
  window.requestAnimationFrame = function (fn) {
    let id;
    id = raf.call(this, (t) => {
      L.rafs.delete(id);
      fn(t);
    });
    L.rafs.add(id);
    return id;
  };
  window.cancelAnimationFrame = function (id) {
    L.rafs.delete(id);
    return caf.call(this, id);
  };

  for (const name of ['ResizeObserver', 'MutationObserver', 'IntersectionObserver']) {
    const Orig = window[name];
    if (!Orig) continue;
    // observer -> { targets: WeakSet, n } ; an observer counts as live while
    // it observes at least one target (unobserve / disconnect release it)
    const state = new WeakMap();
    const Patched = class extends Orig {
      constructor(...a) {
        super(...a);
        L.observerCreated[name]++;
        state.set(this, { targets: new WeakSet(), n: 0, stack: stack() });
      }
      observe(target, ...a) {
        const st = state.get(this);
        if (st && target && typeof target === 'object' && !st.targets.has(target)) {
          st.targets.add(target);
          if (st.n++ === 0) {
            L.observers[name]++;
            st.token = ++token;
            L.live.set(st.token, { kind: name, stack: st.stack });
          }
        }
        return super.observe(target, ...a);
      }
      unobserve(target) {
        const st = state.get(this);
        if (st && target && st.targets.has(target)) {
          st.targets.delete(target);
          if (--st.n === 0) {
            L.observers[name]--;
            L.live.delete(st.token);
          }
        }
        return super.unobserve(target);
      }
      disconnect() {
        const st = state.get(this);
        if (st && st.n > 0) {
          L.observers[name]--;
          L.live.delete(st.token);
        }
        if (st) state.set(this, { targets: new WeakSet(), n: 0, stack: st.stack });
        return super.disconnect();
      }
    };
    Object.defineProperty(Patched, 'name', { value: name });
    window[name] = Patched;
  }

  // the crawler clicks every demo button: keep it on the page
  window.open = () => null;
  window.alert = () => {};
  window.confirm = () => true;
  window.prompt = () => null;
  window.print = () => {};

  window.__leakSnapshot = () => {
    const listeners = {};
    let listenerTotal = 0;
    for (const [k, s] of L.listeners) {
      if (s.size) {
        listeners[k] = s.size;
        listenerTotal += s.size;
      }
    }
    let cssRules = 0;
    for (const sheet of document.styleSheets) {
      try {
        cssRules += sheet.cssRules.length;
      } catch {
        /* cross-origin */
      }
    }
    const bodyChildren = [...(document.body?.children ?? [])].map(
      (el) => `${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}${el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : ''}`,
    );
    return {
      attachedElements: document.getElementsByTagName('*').length,
      bodyChildren,
      styleElements: document.querySelectorAll('style').length,
      cssRules,
      rootListeners: listenerTotal,
      listeners,
      intervals: L.intervals.size,
      pendingTimeouts: L.timeouts.size,
      pendingRafs: L.rafs.size,
      observers: { ...L.observers },
      observerCreated: { ...L.observerCreated },
      live: (() => {
        const by = {};
        for (const { kind, stack } of L.live.values()) {
          const k = `${kind} @ ${stack}`;
          by[k] = (by[k] ?? 0) + 1;
        }
        for (const k of L.timeoutTokens.values()) by[k] = (by[k] ?? 0) + 1;
        return by;
      })(),
    };
  };
})();
