import { registerDeprecationHandler, registerWarnHandler } from '@ember/debug';

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

/**
 * Binding a plain (not htmlSafe) string to `style` makes Ember warn about
 * XSS in development, once per render, in every app using the component.
 * Bind an htmlSafe value or undefined instead.
 */
registerWarnHandler((message, options, next) => {
  if (options?.id === 'ember-htmlbars.style-xss-warning') {
    throw new Error(message);
  }

  next(message, options);
});
