import { registerDeprecationHandler } from '@ember/debug';

/**
 * The test app runs on ember-source 6.x, where APIs removed in Ember 7 only
 * log a deprecation. Turn those into errors so we notice before apps on
 * Ember 7 do (e.g. `import { inject } from '@ember/service'` throws there).
 * Loaded from its own <script type="module"> in tests/index.html, before
 * the tests (and the components they import) are evaluated.
 */
registerDeprecationHandler((message, options, next) => {
  const removedIn = Number.parseInt(String(options?.until ?? ''), 10);

  if (removedIn <= 7) {
    throw new Error(`Uses an API removed in ember-source ${options.until}: ${message}`);
  }

  next(message, options);
});
