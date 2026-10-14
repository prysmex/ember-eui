# `renderComponent` never releases its renderer, so every rendering test's owner and DOM stay in memory

## Summary

Since `@ember/test-helpers` switched `render()` to `renderComponent` (Ember ≥ 6.8), the owner of
every rendering test is never garbage collected. That includes all its services, component
instances and caches, plus the rendered DOM. Memory grows with every test. In our suite it is
about **5 MB per test, 657 MB after 123 tests**.

The cause is in ember-source. `renderComponent` registers a strict renderer in a module-level
`renderers` array, and that renderer is only removed during a later render transaction. When the
owner is destroyed at test teardown, nothing removes it.

## Versions

| Package | Version |
| --- | --- |
| ember-source | 7.3.0 |
| @ember/test-helpers | 5.5.0 |
| ember-qunit | 9.1.0 |
| qunit | 2.26.0 |
| Browser | Chromium 130, run with `--js-flags=--expose-gc` |

## Steps to reproduce

1. Run Chrome with `--js-flags=--expose-gc`, for example by adding it to `browser_args` in
   `testem.cjs`.
2. Add this test file and run it:

```gts
import { module, test } from 'qunit';
import { setupRenderingTest, setupTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

const rendered: WeakRef<object>[] = [];
const notRendered: WeakRef<object>[] = [];

module('render retention | rendering tests', function (hooks) {
  setupRenderingTest(hooks);
  for (let i = 0; i < 5; i++) {
    test(`render ${i}`, async function (assert) {
      rendered.push(new WeakRef(this.owner));
      await render(<template><p>hello</p></template>);
      assert.dom('p').hasText('hello');
    });
  }
});

module('render retention | plain tests (control)', function (hooks) {
  setupTest(hooks);
  for (let i = 0; i < 5; i++) {
    test(`no render ${i}`, function (assert) {
      notRendered.push(new WeakRef(this.owner));
      assert.ok(this.owner);
    });
  }
});

module('render retention | check', function () {
  test('owners of finished tests are garbage collected', async function (assert) {
    for (let i = 0; i < 10; i++) {
      globalThis.gc();
      await new Promise((r) => setTimeout(r, 50));
    }
    const alive = (refs) => refs.filter((r) => r.deref()).length;
    assert.strictEqual(alive(notRendered), 0, 'control: owners of tests without render() are collected');
    assert.strictEqual(alive(rendered), 0, 'owners of tests that called render() are collected');
  });
});
```

## Expected

All 10 owners are collected once their tests have finished.

## Actual

The 5 owners of the tests without `render()` are collected. **All 5 owners of the tests that
called `render()` are still alive**, even after 10 forced garbage collections:

```
not ok 11 - render retention | check: owners of finished tests are garbage collected
    actual: 5
    expected: 0
    message: owners of tests that called render() are collected
```

Calling the private `_resetRenderers()` from `@ember/-internals/glimmer` in a `hooks.afterEach`
makes the same test pass (11/11). That confirms the retention comes from the `renderers` array.

## What holds the memory

Heap snapshot retaining paths, from a run of 123 tests:

DOM (the whole `#ember-testing` container of each test):

```
Window → Context.renderers → Array → BaseRenderer.state → RendererState.#roots
  → ComponentRootState.#result → RenderResultImpl.bounds → AppendingBlockImpl.parent → #ember-testing
```

Owner (services, component instances, caches):

```
… renderers → BaseRenderer.state → RendererState.#data → context
  → EvaluationContextImpl.constants → ConstantsImpl.componentDefinitionCache → WeakMap
  → CompilableTemplateImpl.meta → owner
```

The numbers:

| Run | JS heap after `gc()` | Owners still alive |
| --- | --- | --- |
| 123 tests, as is | 533 MB at test 100, 657 MB at the end | 122 of 122 |
| 123 tests, `_resetRenderers()` after each test | 47 MB at the end | 0 |

## Cause

All references are to `ember-source` 7.3.0,
`dist/dev/packages/shared-chunks/index-COgCjiy-.js`.

1. `renderComponent` creates one strict renderer per owner and caches it in `RENDERER_CACHE`, a
   `WeakMap` keyed by owner.
2. `RendererState.renderRoot` pushes the root and calls `register(renderer)`, which adds the
   renderer to the module-level `renderers` array.
3. The renderer is removed again (`deregister`) in only two places:
   - at the end of a render transaction, when no roots are left;
   - in `clearAllRoots()`.
4. At test teardown the owner is destroyed. `renderComponent` only ties the render *result* to
   the owner (`associateDestroyableChild(owner, innerResult)`), so that result is destroyed, but:
   - `RendererState` does have a destructor that calls `clearAllRoots()`. The renderer and its
     state are never destroyed, though, because nothing ties them to the owner;
   - the destroyed root would be pruned only by a later render transaction on that renderer,
     which never happens.

So the renderer stays in `renderers` forever. Through the renderer, the module-level array keeps
the test's owner and DOM alive, and `RENDERER_CACHE` being a `WeakMap` doesn't help.

## Suggested fix

Either of these, in ember-source:

- In `renderComponent`, make the renderer a destroyable child of its owner, for example with
  `associateDestroyableChild(owner, renderer)`. Its destructor then calls `clearAllRoots()`, which
  deregisters it.
- Or, when a root is destroyed, have `RendererState` prune it and deregister the renderer once
  `#roots` is empty, without waiting for another render transaction.

## Impact

- **Test suites:** memory grows by the size of a whole app instance per rendering test. Large
  suites may slow down or crash the browser.
  - The leak also hides real application leaks in any memory check that runs in the test suite,
    because everything is retained anyway.
  - We work around it with `_resetRenderers()` after each test, but that is a private API.
- **Apps (from reading the code, not reproduced):** the same path exists whenever an owner that
  called `renderComponent` is destroyed, for example app instances in SSR / FastBoot, or
  engines.

## Workaround

This uses a private API:

```ts
import { _resetRenderers } from '@ember/-internals/glimmer';

hooks.afterEach(() => _resetRenderers());
```
