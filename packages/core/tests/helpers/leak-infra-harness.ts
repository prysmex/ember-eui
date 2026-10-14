/*
 * Memory-leak audit harness (leak-infra): counts what outlives a component.
 *
 * - Listeners on long-lived targets (window, document, <html>, <body>,
 *   MediaQueryList): registered minus removed, deduplicated like the DOM
 *   (same target, type, listener and capture registers once).
 * - ResizeObserver / MutationObserver instances still observing something
 *   (`observe` without `disconnect`).
 * - Emotion cache size and style tags in <head>.
 *
 * `install()` patches the globals until `uninstall()`; call them from
 * `hooks.beforeEach` / `hooks.afterEach`.
 */

type Key = string;

const LONG_LIVED = () =>
  [window, document, document.documentElement, document.body] as EventTarget[];

let ids = new WeakMap<object, number>();
let nextId = 1;
const idOf = (value: object) => {
  let id = ids.get(value);
  if (!id) ids.set(value, (id = nextId++));
  return id;
};

const captureOf = (options?: boolean | AddEventListenerOptions) =>
  typeof options === 'boolean' ? options : Boolean(options?.capture);

export class LeakHarness {
  listeners = new Map<Key, { target: EventTarget; type: string }>();
  liveResizeObservers = new Set<object>();
  liveMutationObservers = new Set<object>();
  createdResizeObservers = 0;

  #restore: Array<() => void> = [];

  #tracked(target: EventTarget): boolean {
    return (
      LONG_LIVED().includes(target) ||
      (typeof MediaQueryList !== 'undefined' && target instanceof MediaQueryList)
    );
  }

  install(): void {
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    const harness = this;
    const proto = EventTarget.prototype;
    const add = proto.addEventListener;
    const remove = proto.removeEventListener;

    proto.addEventListener = function (
      this: EventTarget,
      type: string,
      listener: EventListenerOrEventListenerObject | null,
      options?: boolean | AddEventListenerOptions
    ) {
      if (listener && harness.#tracked(this)) {
        harness.listeners.set(
          `${idOf(this)}|${type}|${idOf(listener)}|${captureOf(options)}`,
          { target: this, type }
        );
      }
      return add.call(this, type, listener, options);
    };
    proto.removeEventListener = function (
      this: EventTarget,
      type: string,
      listener: EventListenerOrEventListenerObject | null,
      options?: boolean | EventListenerOptions
    ) {
      if (listener && harness.#tracked(this)) {
        harness.listeners.delete(
          `${idOf(this)}|${type}|${idOf(listener)}|${captureOf(options)}`
        );
      }
      return remove.call(this, type, listener, options);
    };
    this.#restore.push(() => {
      proto.addEventListener = add;
      proto.removeEventListener = remove;
    });

    const OriginalResize = window.ResizeObserver;
    class TrackedResizeObserver extends OriginalResize {
      #targets = new Set<Element>();
      constructor(callback: ResizeObserverCallback) {
        super(callback);
        harness.createdResizeObservers++;
      }
      observe(target: Element, options?: ResizeObserverOptions) {
        this.#targets.add(target);
        harness.liveResizeObservers.add(this);
        super.observe(target, options);
      }
      unobserve(target: Element) {
        this.#targets.delete(target);
        if (this.#targets.size === 0) harness.liveResizeObservers.delete(this);
        super.unobserve(target);
      }
      disconnect() {
        this.#targets.clear();
        harness.liveResizeObservers.delete(this);
        super.disconnect();
      }
    }
    window.ResizeObserver = TrackedResizeObserver;

    const OriginalMutation = window.MutationObserver;
    class TrackedMutationObserver extends OriginalMutation {
      observe(target: Node, options?: MutationObserverInit) {
        harness.liveMutationObservers.add(this);
        super.observe(target, options);
      }
      disconnect() {
        harness.liveMutationObservers.delete(this);
        super.disconnect();
      }
    }
    window.MutationObserver = TrackedMutationObserver;

    this.#restore.push(() => {
      window.ResizeObserver = OriginalResize;
      window.MutationObserver = OriginalMutation;
    });
  }

  uninstall(): void {
    this.#restore.reverse().forEach((restore) => restore());
    this.#restore = [];
    ids = new WeakMap();
  }

  /** Listeners on long-lived targets, as `target:type` strings. */
  listenerSummary(): string[] {
    const name = (target: EventTarget) =>
      target === window
        ? 'window'
        : target === document
          ? 'document'
          : target === document.documentElement
            ? 'html'
            : target === document.body
              ? 'body'
              : 'MediaQueryList';
    return [...this.listeners.values()]
      .map(({ target, type }) => `${name(target)}:${type}`)
      .sort();
  }

  snapshot() {
    return {
      listeners: this.listeners.size,
      resizeObservers: this.liveResizeObservers.size,
      mutationObservers: this.liveMutationObservers.size
    };
  }
}

/** Emotion instance (`@emotion/css/create-instance`) cache sizes. */
export function emotionCacheSize(emotion: {
  cache: { inserted: Record<string, unknown>; registered: Record<string, unknown> };
}) {
  return {
    inserted: Object.keys(emotion.cache.inserted).length,
    registered: Object.keys(emotion.cache.registered).length
  };
}

/** Number of CSS rules in every Emotion `<style>` tag of a cache key. */
export function emotionRuleCount(key: string): number {
  return [...document.head.querySelectorAll<HTMLStyleElement>(`style[data-emotion^="${key}"]`)]
    .map((style) => style.sheet?.cssRules.length ?? 0)
    .reduce((a, b) => a + b, 0);
}
