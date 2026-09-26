import { module, test } from 'qunit';

import { iconsFromGlob } from '#src/utils/icons-from-glob.ts';

// stand-ins for components; iconsFromGlob only checks they are objects/functions
const Logo = { name: 'Logo' };
const Rocket = { name: 'Rocket' };

module('Unit | utils | icons-from-glob', function () {
  test('names icons by file name, without folders or extension', function (assert) {
    const icons = iconsFromGlob({
      '../icons/logo.svg': { default: Logo },
      '../icons/brands/rocket.svg': { default: Rocket }
    });

    assert.deepEqual(icons, { logo: Logo, rocket: Rocket });
  });

  test('accepts `import: "default"` globs (components instead of modules)', function (assert) {
    assert.deepEqual(iconsFromGlob({ './logo.svg': Logo }), { logo: Logo });
  });

  test('supports a prefix and a custom name function', function (assert) {
    assert.deepEqual(
      iconsFromGlob({ './logo.svg': { default: Logo } }, { prefix: 'app-' }),
      { 'app-logo': Logo }
    );

    assert.deepEqual(
      iconsFromGlob(
        { '../icons/brands/rocket.svg': { default: Rocket } },
        { name: (path) => path.replace('../icons/', '').replace('.svg', '') }
      ),
      { 'brands/rocket': Rocket }
    );
  });

  test('throws on duplicate names', function (assert) {
    assert.throws(
      () =>
        iconsFromGlob({
          './a/logo.svg': { default: Logo },
          './b/logo.svg': { default: Rocket }
        }),
      /"\.\/a\/logo\.svg" and "\.\/b\/logo\.svg" both map to the icon name "logo"/
    );
  });

  test('throws on values that are not components', function (assert) {
    assert.throws(
      () => iconsFromGlob({ './logo.svg': { default: '/assets/logo.svg' } }),
      /is not a component/
    );
  });
});
