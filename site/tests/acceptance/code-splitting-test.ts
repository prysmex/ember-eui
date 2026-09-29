import { module, test } from 'qunit';
import { visit } from '@ember/test-helpers';

import { setupApplicationTest } from 'site/tests/helpers';

import type DocfyService from '@docfy/ember/services/docfy';

interface RouteBundle {
  names: string[];
  load: () => Promise<unknown>;
}

const routeBundles = () =>
  (window as unknown as { _embroiderRouteBundles_?: RouteBundle[] })
    ._embroiderRouteBundles_ ?? [];

// `/docs/a/b` is the route `docs.a.b`, `/docs/a/` is `docs.a.index`
const routeName = (url: string) =>
  (url.endsWith('/') ? `${url}index` : url)
    .replace(/^\//, '')
    .replaceAll('/', '.');

module('Acceptance | code splitting', function (hooks) {
  setupApplicationTest(hooks);

  test('every docs page loads with its own bundle', async function (assert) {
    await visit('/');

    const docfy = this.owner.lookup('service:docfy') as DocfyService;
    const pages = docfy.flat.map((page) => routeName(page.url));
    const bundles = routeBundles();
    const bundleOf = (name: string) =>
      bundles.find((bundle) => bundle.names.includes(name));

    // e.g. a page added in a way lib/docs-routes.mjs does not know
    const inMain = pages.filter((name) => !bundleOf(name));

    assert.deepEqual(inMain, [], 'no page is in the main bundle');

    // a route splits with its child routes, so a page shares its bundle only
    // with its sub-pages
    const shared = pages
      .map((name) => bundleOf(name)?.names ?? [])
      .filter(([parent, ...others]) =>
        others.some((name) => !name.startsWith(`${parent}.`)),
      )
      .map((names) => names.join(', '));

    assert.deepEqual(shared, [], 'bundles hold one page and its sub-pages');
  });
});
