/**
 * A small Jest-compatible layer over QUnit, so upstream EUI's pure unit
 * tests (reducers, selectors, validation) can be ported nearly verbatim:
 * `describe`/`it`/`beforeEach`/`afterEach`, `expect(...)` with the matchers
 * those tests use, and `jest.fn`/`jest.spyOn`.
 */
import { module, test } from 'qunit';

type Fn = (...args: any[]) => any;

interface Hooks {
  beforeEach(fn: () => void | Promise<void>): void;
  afterEach(fn: () => void | Promise<void>): void;
}

let currentAssert: Assert | undefined;
const hookStack: Hooks[] = [];

export function describe(name: string, body: () => void): void {
  module(name, function (hooks) {
    hookStack.push(hooks as unknown as Hooks);
    try {
      body();
    } finally {
      hookStack.pop();
    }
  });
}

export function it(name: string, body: () => void | Promise<void>): void {
  test(name, async function (assert) {
    currentAssert = assert;
    try {
      await body();
    } finally {
      currentAssert = undefined;
    }
  });
}

function currentHooks(): Hooks {
  const hooks = hookStack[hookStack.length - 1];
  if (!hooks) throw new Error('beforeEach/afterEach must be inside describe');
  return hooks;
}

export function beforeEach(fn: () => void | Promise<void>): void {
  currentHooks().beforeEach(fn);
}

export function afterEach(fn: () => void | Promise<void>): void {
  currentHooks().afterEach(fn);
}

// Mocks

export interface Mock<T extends Fn = Fn> {
  (...args: Parameters<T>): ReturnType<T>;
  mock: { calls: Parameters<T>[]; results: { value: unknown }[] };
  mockImplementation(impl: T): Mock<T>;
  mockReturnValue(value: ReturnType<T>): Mock<T>;
  mockClear(): Mock<T>;
  mockRestore(): void;
  _isMock: true;
}

function fn<T extends Fn = Fn>(impl?: T): Mock<T> {
  let implementation: Fn | undefined = impl;
  const mock = function (this: unknown, ...args: unknown[]) {
    mock.mock.calls.push(args as Parameters<T>);
    const value = implementation?.apply(this, args);
    mock.mock.results.push({ value });
    return value;
  } as unknown as Mock<T>;
  mock.mock = { calls: [], results: [] };
  mock._isMock = true;
  mock.mockImplementation = (next: T) => {
    implementation = next;
    return mock;
  };
  mock.mockReturnValue = (value) => {
    implementation = () => value;
    return mock;
  };
  mock.mockClear = () => {
    mock.mock.calls = [];
    mock.mock.results = [];
    return mock;
  };
  mock.mockRestore = () => {};
  return mock;
}

function spyOn<O extends object, K extends keyof O>(object: O, method: K) {
  const original = object[method] as unknown as Fn;
  const spy = fn(original.bind(object));
  spy.mockRestore = () => {
    object[method] = original as O[K];
  };
  object[method] = spy as unknown as O[K];
  return spy;
}

export const jest = { fn, spyOn };

// Matching

class Any {
  constructor(readonly type: unknown) {}
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return (
    typeof value === 'object' &&
    value !== null &&
    !Array.isArray(value) &&
    !(value instanceof Any)
  );
}

/** Jest's `toEqual`: recursive, ignoring properties that are `undefined`. */
function equals(a: unknown, b: unknown, partial = false): boolean {
  if (b instanceof Any) {
    if (b.type === Function) return typeof a === 'function';
    if (b.type === String) return typeof a === 'string';
    if (b.type === Number) return typeof a === 'number';
    if (b.type === Symbol) return typeof a === 'symbol';
    if (b.type === Object) return typeof a === 'object' && a !== null;
    return a instanceof (b.type as new () => unknown);
  }
  if (Object.is(a, b)) return true;
  if (Array.isArray(a) && Array.isArray(b)) {
    if (!partial && a.length !== b.length) return false;
    if (partial && a.length !== b.length) return false;
    return a.every((value, index) => equals(value, b[index], partial));
  }
  if (isPlainObject(a) && isPlainObject(b)) {
    const keys = new Set(
      partial ? Object.keys(b) : [...Object.keys(a), ...Object.keys(b)]
    );
    for (const key of keys) {
      if (!equals(a[key], b[key], partial)) return false;
    }
    return true;
  }
  return false;
}

function describeValue(value: unknown): string {
  try {
    return JSON.stringify(value, (_key, v: unknown) =>
      typeof v === 'symbol'
        ? v.toString()
        : typeof v === 'function'
          ? '[Function]'
          : v
    );
  } catch {
    return String(value);
  }
}

function report(
  pass: boolean,
  negate: boolean,
  actual: unknown,
  expected: unknown,
  message: string
) {
  const assert = currentAssert;
  if (!assert) throw new Error('expect() called outside of it()');
  const result = negate ? !pass : pass;
  assert.pushResult({
    result,
    actual: describeValue(actual),
    expected: `${negate ? 'not ' : ''}${describeValue(expected)}`,
    message
  });
}

function matchers(actual: unknown, negate: boolean) {
  const calls = () => (actual as Mock).mock.calls;

  return {
    toBe: (expected: unknown) =>
      report(Object.is(actual, expected), negate, actual, expected, 'toBe'),
    toEqual: (expected: unknown) =>
      report(equals(actual, expected), negate, actual, expected, 'toEqual'),
    toStrictEqual: (expected: unknown) =>
      report(equals(actual, expected), negate, actual, expected, 'toStrictEqual'),
    toMatchObject: (expected: unknown) =>
      report(equals(actual, expected, true), negate, actual, expected, 'toMatchObject'),
    toHaveLength: (length: number) =>
      report(
        (actual as { length: number }).length === length,
        negate,
        (actual as { length: number }).length,
        length,
        'toHaveLength'
      ),
    toBeUndefined: () =>
      report(actual === undefined, negate, actual, undefined, 'toBeUndefined'),
    toBeDefined: () =>
      report(actual !== undefined, negate, actual, 'defined', 'toBeDefined'),
    toBeNull: () => report(actual === null, negate, actual, null, 'toBeNull'),
    toBeTruthy: () => report(Boolean(actual), negate, actual, true, 'toBeTruthy'),
    toBeFalsy: () => report(!actual, negate, actual, false, 'toBeFalsy'),
    toBeGreaterThan: (value: number) =>
      report((actual as number) > value, negate, actual, `> ${value}`, 'toBeGreaterThan'),
    toMatch: (pattern: RegExp | string) =>
      report(
        typeof pattern === 'string'
          ? String(actual).includes(pattern)
          : pattern.test(String(actual)),
        negate,
        actual,
        String(pattern),
        'toMatch'
      ),
    toContain: (item: unknown) =>
      report(
        (actual as unknown[]).includes(item),
        negate,
        actual,
        item,
        'toContain'
      ),
    toThrow: (pattern?: RegExp | string) => {
      let error: unknown;
      try {
        (actual as Fn)();
      } catch (e) {
        error = e;
      }
      const message = error instanceof Error ? error.message : String(error);
      const pass =
        error !== undefined &&
        (pattern === undefined ||
          (typeof pattern === 'string'
            ? message.includes(pattern)
            : pattern.test(message)));
      report(pass, negate, message, pattern ?? 'an error', 'toThrow');
    },
    toHaveBeenCalled: () =>
      report(calls().length > 0, negate, calls().length, '> 0 calls', 'toHaveBeenCalled'),
    toHaveBeenCalledTimes: (times: number) =>
      report(calls().length === times, negate, calls().length, times, 'toHaveBeenCalledTimes'),
    toHaveBeenCalledWith: (...args: unknown[]) =>
      report(
        calls().some((call) => equals(call, args)),
        negate,
        calls(),
        args,
        'toHaveBeenCalledWith'
      ),
    toHaveBeenNthCalledWith: (n: number, ...args: unknown[]) =>
      report(
        equals(calls()[n - 1], args),
        negate,
        calls()[n - 1],
        args,
        'toHaveBeenNthCalledWith'
      )
  };
}

export function expect(actual: unknown) {
  return { ...matchers(actual, false), not: matchers(actual, true) };
}

expect.any = (type: unknown) => new Any(type);
