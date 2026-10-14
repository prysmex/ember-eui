/**
 * Self-contained counters for leak regression tests (work without `?leaks`).
 * Each `start*` patches a global for the duration of a test; call `restore()`
 * in a finally block.
 */

type ObserverName = 'ResizeObserver' | 'MutationObserver' | 'IntersectionObserver';

/** Counts observers that observe something and were never disconnected. */
export function startObserverCounter(names: ObserverName[] = ['ResizeObserver', 'MutationObserver', 'IntersectionObserver']) {
  const live = new Set<object>();
  const created = { count: 0 };
  const originals = new Map<ObserverName, any>();
  for (const name of names) {
    const Native = (window as any)[name];
    if (!Native) continue;
    originals.set(name, Native);
    (window as any)[name] = class extends Native {
      constructor(...args: any[]) {
        super(...args);
        created.count++;
      }
      observe(...args: any[]) {
        live.add(this);
        return super.observe(...args);
      }
      disconnect() {
        live.delete(this);
        return super.disconnect();
      }
    };
  }
  return {
    get live() {
      return live.size;
    },
    get created() {
      return created.count;
    },
    restore() {
      for (const [name, Native] of originals) (window as any)[name] = Native;
    }
  };
}

/** Counts listeners on window/document/<html>/<body> added and not removed. */
export function startGlobalListenerCounter() {
  const proto = EventTarget.prototype;
  const add = proto.addEventListener;
  const remove = proto.removeEventListener;
  const targets = new Set<EventTarget>([window, document, document.documentElement, document.body]);
  const live = new Map<string, number>();
  const key = (t: EventTarget, type: string, l: unknown, o: unknown) =>
    `${t === window ? 'window' : t === document ? 'document' : (t as Element).tagName}:${type}:${typeof o === 'boolean' ? o : !!(o as any)?.capture}:${ids.get(l as object) ?? ids.set(l as object, ids.size + 1).get(l as object)}`;
  const ids = new Map<object, number>();
  proto.addEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
    if (l && targets.has(this)) {
      const k = key(this, type, l, o);
      live.set(k, 1);
    }
    return add.call(this, type, l, o);
  };
  proto.removeEventListener = function (this: EventTarget, type: string, l: any, o?: any) {
    if (l && targets.has(this)) live.delete(key(this, type, l, o));
    return remove.call(this, type, l, o);
  };
  return {
    get live() {
      return live.size;
    },
    keys() {
      return [...live.keys()];
    },
    restore() {
      proto.addEventListener = add;
      proto.removeEventListener = remove;
    }
  };
}

/** Counts setTimeout/setInterval/requestAnimationFrame callbacks pending. */
export function startTimerCounter() {
  const st = window.setTimeout;
  const ct = window.clearTimeout;
  const si = window.setInterval;
  const ci = window.clearInterval;
  const raf = window.requestAnimationFrame;
  const caf = window.cancelAnimationFrame;
  const pending = new Set<number>();
  const frames = new Set<number>();
  const ran = { frames: 0 };
  window.setTimeout = ((fn: any, ms?: number, ...a: any[]) => {
    const id: number = st(
      () => {
        pending.delete(id);
        if (typeof fn === 'function') fn(...a);
      },
      ms
    ) as unknown as number;
    pending.add(id);
    return id;
  }) as typeof window.setTimeout;
  window.setInterval = ((fn: any, ms?: number, ...a: any[]) => {
    const id = si(fn, ms, ...a) as unknown as number;
    pending.add(id);
    return id;
  }) as typeof window.setInterval;
  window.clearTimeout = ((id?: number) => {
    pending.delete(id!);
    ct(id);
  }) as typeof window.clearTimeout;
  window.clearInterval = ((id?: number) => {
    pending.delete(id!);
    ci(id);
  }) as typeof window.clearInterval;
  window.requestAnimationFrame = (fn) => {
    const id = raf((t) => {
      frames.delete(id);
      ran.frames++;
      fn(t);
    });
    frames.add(id);
    return id;
  };
  window.cancelAnimationFrame = (id) => {
    frames.delete(id);
    caf(id);
  };
  return {
    get timers() {
      return pending.size;
    },
    get frames() {
      return frames.size;
    },
    get framesRan() {
      return ran.frames;
    },
    restore() {
      window.setTimeout = st;
      window.clearTimeout = ct;
      window.setInterval = si;
      window.clearInterval = ci;
      window.requestAnimationFrame = raf;
      window.cancelAnimationFrame = caf;
    }
  };
}
