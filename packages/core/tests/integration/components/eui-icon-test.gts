import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, getRootElement, render } from '@ember/test-helpers';

import EuiBadge from '#src/components/eui-badge.gts';
import EuiButton from '#src/components/eui-button.gts';
import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiFieldPassword from '#src/components/eui-field-password.gts';
import EuiFieldSearch from '#src/components/eui-field-search.gts';
import EuiIcon, { TYPES } from '#src/components/eui-icon.gts';
import EuiIconTip from '#src/components/eui-icon-tip.gts';
import EuiLink from '#src/components/eui-link.gts';
import EuiPagination from '#src/components/eui-pagination.gts';
import {
  deprecatedIconTypes,
  legacyIconAliases,
  legacyIconTypes,
  typeToPathMap
} from '#src/utils/css-mappings/eui-icon.ts';
import { clearIconCache } from '#src/-private/icon-loader.ts';
import { iconsFromGlob } from '#src/utils/icons-from-glob.ts';
import { preloadIcons } from '#src/utils/preload-icons.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiIconType } from '#src/components/eui-icon.gts';
import type EuiConfigService from '#src/services/eui-config.ts';
import type { TOC } from '@ember/component/template-only';

const CustomIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg class="my-custom-icon" viewBox="0 0 16 16" ...attributes><circle
      cx="8"
      cy="8"
      r="4"
    /></svg>
</template>;

/**
 * Child element count of the first svg rendered by `callback`, captured as
 * soon as it is in the DOM (before a lazily loaded icon can arrive).
 */
async function firstRenderedChildren(callback: () => Promise<void>) {
  let children: number | undefined;
  const observer = new MutationObserver(() => {
    const svg = getRootElement().querySelector('svg');

    if (svg && children === undefined) children = svg.childElementCount;
  });

  observer.observe(getRootElement(), { childList: true, subtree: true });
  await callback();
  observer.disconnect();

  return children;
}

const light = resolveBorealisTheme('light').euiTheme;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** Splits the icon catalog into tests that each finish well within the timeout. */
function chunks<T>(items: T[], size = 120): T[][] {
  const result: T[][] = [];

  for (let i = 0; i < items.length; i += size) result.push(items.slice(i, i + size));

  return result;
}

/** Names whose rendered svg (`[data-icon-name]`) has no content or viewBox. */
function emptyIcons(element: Element, types: readonly string[]): string[] {
  return types.filter((type) => {
    const svg = element.querySelector(`svg[data-icon-name="${type}"]`);

    return !svg || svg.children.length === 0 || !svg.getAttribute('viewBox');
  });
}

const DATA_URL =
  'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"></svg>';

module('Integration | Component | eui-icon', function (hooks) {
  setupRenderingTest(hooks);

  module('named EUI icons', function () {
    test('it renders a named icon as an inline svg', async function (assert) {
      await render(<template><EuiIcon @type="arrowDown" /></template>);

      assert.dom('svg').exists({ count: 1 });
      assert.dom('svg').hasClass('euiIcon');
      assert.dom('svg').hasStyle({ width: '16px', height: '16px' }, 'defaults to size m');
      assert.dom('svg').hasAttribute('viewBox', '0 0 16 16');
      assert.dom('svg path').exists();
    });

    test('it keeps the classes inside the svg that EUI styles rely on', async function (assert) {
      await render(<template><EuiIcon @type="apmApp" /></template>);

      assert.dom('svg').hasAttribute('viewBox', '0 0 32 32');
      assert.dom('svg .euiIcon__fillSecondary').exists();
    });

    test('it keeps the data-type of the Elastic logo', async function (assert) {
      // upstream outlines the logo through its own logoElasticOutline style
      await render(<template><EuiIcon @type="logoElastic" /></template>);

      assert.dom('svg').hasAttribute('data-type', 'logoElastic');
      // the EUI 123 logo is four filled, white-stroked shapes (no `.outline`)
      assert.dom('svg path[fill]').exists();
    });

    test('it resolves icons that live in sub folders (tokens)', async function (assert) {
      await render(<template><EuiIcon @type="tokenAlias" /></template>);

      assert.dom('svg').exists();
      assert.dom('svg > *').exists();
    });

  });

  module('icon set (EUI 123.1.0)', function () {
    // Each chunk renders its icons together: one render per icon, or the
    // whole catalog in one test, can exceed the browser timeout under load.
    for (const [index, chunk] of chunks(TYPES.filter((type) => type !== 'empty')).entries()) {
      test(`every named icon renders an svg with content (${index + 1})`, async function (assert) {
        await render(<template>
          {{#each chunk as |type|}}<EuiIcon @type={{type}} data-icon-name={{type}} />{{/each}}
        </template>);

        assert.dom('svg[data-icon-name]').exists({ count: chunk.length });
        assert.deepEqual(emptyIcons(this.element, chunk), [], `${chunk.length} icons render`);
      });
    }

    test('every upstream icon name is bundled', function (assert) {
      const legacy = new Set<string>([...Object.keys(legacyIconAliases), ...legacyIconTypes]);
      const upstream = TYPES.filter((type) => !legacy.has(type));

      // 567 names of upstream's icon map + EuiNotificationIcon's infoFill
      // and warningStatic; a different count means the set drifted from 123.1.0
      assert.strictEqual(upstream.length, 569);

      for (const type of ['external', 'question', 'magnify', 'eyeSlash', 'chevronSingleDown',
        'infoFill', 'checkCircleFill', 'warningStatic', 'errorFill', 'stopFill',
        'transitionLeftIn', 'transitionLeftOut', 'textBold', 'listBullet', 'return', 'copy',
        'tokenVectorDense', 'tokenSemanticText', 'sparkles', 'workflow',
        // deprecated upstream, still upstream names
        'search', 'alert', 'help', 'apps']) {
        assert.true(Object.prototype.hasOwnProperty.call(typeToPathMap, type), type);
      }
    });

    test('legacy names and upstream deprecations point at bundled icons', function (assert) {
      for (const [name, target] of Object.entries(legacyIconAliases)) {
        assert.strictEqual(
          typeToPathMap[name as EuiIconType],
          typeToPathMap[target],
          `${name} renders ${target}`
        );
        assert.false(target in legacyIconAliases, `${target} is not an alias itself`);
      }

      for (const name of legacyIconTypes) {
        assert.true(typeToPathMap[name].startsWith('legacy/'), `${name} keeps its legacy svg`);
      }

      for (const [name, replacement] of Object.entries(deprecatedIconTypes)) {
        if (replacement) {
          assert.true(replacement in typeToPathMap, `${name} → ${replacement}`);
        }
      }
    });

    test('legacy aliases render the same svg as their upstream icon', async function (assert) {
      const pairs = Object.entries(legacyIconAliases).map(([name, target]) => ({ name, target }));

      await render(<template>
        {{#each pairs as |pair|}}
          <EuiIcon @type={{pair.name}} data-alias={{pair.name}} />
          <EuiIcon @type={{pair.target}} data-target={{pair.name}} />
        {{/each}}
      </template>);

      const different = pairs
        .filter(({ name }) => {
          const alias = this.element.querySelector(`svg[data-alias="${name}"]`);
          const target = this.element.querySelector(`svg[data-target="${name}"]`);

          return !alias?.innerHTML || alias.innerHTML !== target?.innerHTML;
        })
        .map(({ name }) => name);

      assert.deepEqual(different, [], `${pairs.length} aliases`);
      assert.dom('svg[data-alias="arrowDown"]').hasAttribute('data-icon-type', 'arrowDown');
    });

    test('renamed icons render the upstream artwork', async function (assert) {
      const renamed = [
        { old: 'arrowDown', current: 'chevronSingleDown' },
        { old: 'popout', current: 'external' },
        { old: 'questionInCircle', current: 'question' },
        { old: 'iInCircle', current: 'info' },
        { old: 'eyeClosed', current: 'eyeSlash' },
        { old: 'editorBold', current: 'textBold' },
        { old: 'returnKey', current: 'return' },
        { old: 'copyClipboard', current: 'copy' },
        { old: 'tokenDenseVector', current: 'tokenVectorDense' },
        // upstream deprecations keep upstream's own mapping
        { old: 'search', current: 'magnify' },
        { old: 'alert', current: 'warning' }
      ];

      await render(<template>
        {{#each renamed as |pair|}}
          <EuiIcon @type={{pair.old}} data-old={{pair.old}} />
          <EuiIcon @type={{pair.current}} data-new={{pair.old}} />
        {{/each}}
      </template>);

      for (const { old, current } of renamed) {
        const before = this.element.querySelector(`svg[data-old="${old}"]`)!;
        const after = this.element.querySelector(`svg[data-new="${old}"]`)!;

        assert.ok(before.innerHTML.length > 0, `${old} has content`);
        assert.strictEqual(before.innerHTML, after.innerHTML, `${old} renders ${current}`);
        assert.strictEqual(before.getAttribute('viewBox'), after.getAttribute('viewBox'));
      }
    });

    test('legacy names without an upstream equivalent keep their artwork', async function (assert) {
      const types = [...legacyIconTypes];

      await render(<template>
        {{#each types as |type|}}<EuiIcon @type={{type}} data-icon-name={{type}} />{{/each}}
      </template>);

      assert.dom('svg[data-icon-name]').exists({ count: types.length });
      assert.deepEqual(emptyIcons(this.element, types), []);
    });
  });

  module('components use the upstream icon names', function () {
    test('callout defaults, icon tip, external link, search, password, pagination', async function (assert) {
      const noop = () => {};

      await render(
        <template>
          <EuiCallOut @title="i" data-co="primary" />
          <EuiCallOut @title="s" @color="success" data-co="success" />
          <EuiCallOut @title="w" @color="warning" data-co="warning" />
          <EuiCallOut @title="d" @color="danger" data-co="danger" />
          <EuiIconTip @content="Help" data-tip />
          <EuiLink @href="https://example.com" @target="_blank" data-link>Out</EuiLink>
          <EuiFieldSearch @onSearch={{noop}} data-search />
          <EuiFieldPassword data-password />
          <EuiPagination @pageCount={{5}} @activePage={{2}} @responsive={{false}} data-pagination />
        </template>
      );

      const type = (selector: string) =>
        [...document.querySelectorAll(`${selector} [data-icon-type]`)].map((icon) =>
          icon.getAttribute('data-icon-type')
        );

      // upstream EuiNotificationIcon glyphs
      assert.deepEqual(type('[data-co="primary"]'), ['infoFill']);
      assert.deepEqual(type('[data-co="success"]'), ['checkCircleFill']);
      assert.deepEqual(type('[data-co="warning"]'), ['warningStatic']);
      assert.deepEqual(type('[data-co="danger"]'), ['errorFill']);
      assert.deepEqual(type('.euiToolTipAnchor'), ['question']);
      assert.deepEqual(type('[data-link]'), ['external']);
      assert.true(type('.euiFormControlLayout:has([data-search])').includes('magnify'));
      assert.true(type('[data-pagination]').includes('chevronSingleLeft'));
      assert.true(type('[data-pagination]').includes('chevronSingleRight'));

      const password = '.euiFormControlLayout:has([data-password])';

      assert.true(type(password).includes('eye'));
      await click(`${password} button`);
      assert.true(type(password).includes('eyeSlash'), 'eyeSlash while the text shows');
    });
  });

  module('size, color and classes', function () {
    test('it applies the size', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="bell" @size="s" class="small" />
          <EuiIcon @type="bell" @size="xl" />
          <EuiIcon @type="bell" @size="original" />
        </template>
      );

      const svgs = [...(this.element as HTMLElement).querySelectorAll('svg')];

      // upstream sizes are emotion styles now, not legacy --small/--xLarge classes
      assert.strictEqual(getComputedStyle(svgs[0]!).width, '12px');
      assert.strictEqual(getComputedStyle(svgs[1]!).width, '32px');
      assert.strictEqual(
        getComputedStyle(svgs[2]!).width,
        '16px',
        'original keeps the svg width attribute'
      );
    });

    test('no style attribute is bound without a custom color', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="bell" />
          <EuiIcon @type="bell" @color="danger" />
        </template>
      );

      assert.dom('svg[style]').doesNotExist();
    });

    test('a named color sets the theme text color', async function (assert) {
      await render(<template><EuiIcon @type="bell" @color="danger" /></template>);

      // was the legacy euiIcon--danger class; upstream colors through `color`
      const danger = rgb(light.colors.textDanger);
      assert.dom('svg').hasStyle({ color: danger, fill: danger });
    });

    test('a custom color sets color, filled with currentColor', async function (assert) {
      await render(<template><EuiIcon @type="bell" @color="#ff0000" /></template>);

      // upstream: `color` (inline there, a class here) + `fill: currentColor`
      assert.dom('svg').hasStyle({ color: 'rgb(255, 0, 0)', fill: 'rgb(255, 0, 0)' });
      assert.dom('svg').doesNotHaveAttribute('style');
    });

    test('app icons are two-toned unless they are colored', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="apmApp" />
          <EuiIcon @type="apmApp" @color="primary" />
        </template>
      );

      const svgs = [...(this.element as HTMLElement).querySelectorAll('svg')];

      // was the legacy euiIcon--app class: upstream app styles fill the
      // secondary shapes with the primary color
      const secondary = (svg: SVGSVGElement) =>
        getComputedStyle(svg.querySelector('.euiIcon__fillSecondary')!).fill;
      assert.strictEqual(secondary(svgs[0]!), rgb(light.colors.primary));
      assert.strictEqual(secondary(svgs[1]!), getComputedStyle(svgs[1]!).fill);
    });

    test('extra attributes are passed to the svg', async function (assert) {
      await render(
        <template><EuiIcon @type="bell" data-test-bell id="bell-icon" /></template>
      );

      assert.dom('svg[data-test-bell]').hasAttribute('id', 'bell-icon');
    });

    test('@iconClasses are added to the svg', async function (assert) {
      await render(
        <template><EuiIcon @type="bell" @iconClasses="foo bar" /></template>
      );

      assert.dom('svg').hasClass('foo');
      assert.dom('svg').hasClass('bar');
    });
  });

  module('accessibility', function () {
    test('it is presentational without a title', async function (assert) {
      await render(<template><EuiIcon @type="bell" /></template>);

      // upstream 123: decorative icons get role="presentation"; aria-hidden is
      // only set when the caller passes it
      assert.dom('svg').hasAttribute('role', 'presentation');
      assert.dom('svg').doesNotHaveAttribute('aria-hidden');
    });

    test('it is not aria-hidden with a title', async function (assert) {
      await render(<template><EuiIcon @type="bell" @title="Bell" /></template>);

      assert.notStrictEqual(
        document.querySelector('svg')?.getAttribute('aria-hidden'),
        'true'
      );
      assert.dom('svg').hasAttribute('role', 'img');
    });

    test('@title renders a <title> that labels the svg', async function (assert) {
      await render(<template><EuiIcon @type="bell" @title="Notifications" /></template>);

      const titleId = document.querySelector('svg title')?.id;

      assert.dom('svg title').hasText('Notifications');
      assert.ok(titleId, 'the title has an id');
      assert.dom('svg').hasAttribute('aria-labelledby', titleId as string);
      assert.dom('svg').doesNotHaveAttribute('aria-label');
      assert.dom('svg').doesNotHaveAttribute('aria-hidden');
    });

    test('@titleId sets the id of the <title>', async function (assert) {
      await render(
        <template><EuiIcon @type="bell" @title="Notifications" @titleId="bell-title" /></template>
      );

      assert.dom('svg title#bell-title').exists();
      assert.dom('svg').hasAttribute('aria-labelledby', 'bell-title');
    });

    test('@aria-label alone makes the icon accessible', async function (assert) {
      await render(<template><EuiIcon @type="bell" @aria-label="Notifications" /></template>);

      assert.dom('svg').hasAttribute('aria-label', 'Notifications');
      assert.dom('svg').doesNotHaveAttribute('aria-hidden');
      assert.dom('svg title').doesNotExist();
    });

    test('it passes aria-label and tabIndex through', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="bell" @aria-label="Notifications" @tabIndex={{0}} />
        </template>
      );

      assert.dom('svg').hasAttribute('aria-label', 'Notifications');
      assert.dom('svg').hasAttribute('tabindex', '0');
    });
  });

  module('other icon sources', function () {
    test('a string that is not a named icon renders an <img>', async function (assert) {
      await render(
        <template><EuiIcon @type={{DATA_URL}} @title="Custom" /></template>
      );

      assert.dom('svg').doesNotExist();
      assert.dom('img').hasAttribute('src', DATA_URL);
      assert.dom('img').hasAttribute('alt', 'Custom');
      assert.dom('img').hasClass('euiIcon');
    });

    test('icons registered in the euiIcon.icons config render by name', async function (assert) {
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;

      config.updateConfig({ 'euiIcon.icons': { myLogo: CustomIcon } });

      await render(
        <template><EuiIcon @type="myLogo" @size="l" @color="primary" /></template>
      );

      assert.dom('img').doesNotExist();
      assert.dom('svg.my-custom-icon').exists();
      assert.dom('svg.my-custom-icon').hasClass('euiIcon');
      assert.dom('svg.my-custom-icon').hasStyle({ width: '24px', color: rgb(light.colors.textPrimary) });
      assert.dom('svg.my-custom-icon').hasAttribute('role', 'presentation');
    });

    test('an icon registered under an EUI icon name wins over the EUI icon', async function (assert) {
      // EUI 123 added names apps may already register (e.g. `rocket`, `copy`)
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;

      config.updateConfig({ 'euiIcon.icons': { copy: CustomIcon } });

      await render(
        <template>
          <EuiIcon @type="copy" data-registered />
          <EuiIcon @type="copyClipboard" data-eui />
        </template>
      );

      assert.dom('svg[data-registered]').hasClass('my-custom-icon');
      assert.dom('svg[data-registered]').doesNotHaveAttribute('data-icon-type');
      assert.dom('svg[data-registered]').doesNotHaveAttribute('data-is-loading');
      assert.dom('svg[data-eui]').doesNotHaveClass('my-custom-icon');
      assert.dom('svg[data-eui]').hasAttribute('data-icon-type', 'copyClipboard');
    });

    test('a folder of svgs can be registered with iconsFromGlob', async function (assert) {
      // real svg files, turned into components by @svg-jar/plugin
      const icons = iconsFromGlob(
        import.meta.glob('../../fixtures/icons/**/*.svg', { eager: true })
      );
      const config = this.owner.lookup('service:eui-config') as EuiConfigService;

      assert.deepEqual(Object.keys(icons).sort(), ['app-logo', 'rocket']);

      config.updateConfig({ 'euiIcon.icons': icons });

      await render(
        <template>
          <EuiIcon @type="app-logo" @size="l" />
          <EuiButton @iconType="rocket">Launch</EuiButton>
        </template>
      );

      // plain `.svg` imports use @svg-jar/plugin's sprite mode in builds:
      // the svg references a symbol in the emitted sprite sheet
      const logo = document.querySelector('svg.euiIcon:not(.euiButton svg) use');
      const rocket = document.querySelector('.euiButton svg.euiIcon use');

      assert.dom('img').doesNotExist();
      assert.ok(logo?.getAttribute('href')?.includes('#'), 'logo uses a symbol');
      assert.ok(rocket?.getAttribute('href')?.includes('#'), 'rocket uses a symbol');
      assert.notStrictEqual(logo?.getAttribute('href'), rocket?.getAttribute('href'));
    });

    test('a component passed as @type renders as a component', async function (assert) {
      await render(
        <template><EuiIcon @type={{CustomIcon}} @size="l" @color="danger" /></template>
      );

      assert.dom('img').doesNotExist();
      assert.dom('svg.my-custom-icon').exists({ count: 1 });
      assert.dom('svg.my-custom-icon').hasClass('euiIcon');
      assert.dom('svg.my-custom-icon').hasStyle({ width: '24px', color: rgb(light.colors.textDanger) });
    });

    test('components passed as @iconType work through other components', async function (assert) {
      // EuiBadge forwards @iconType to EuiIcon, but not @useComponent
      await render(
        <template><EuiBadge @iconType={{CustomIcon}}>Badge</EuiBadge></template>
      );

      assert.dom('.euiBadge svg.my-custom-icon').exists();
      assert.dom('.euiBadge svg.my-custom-icon').hasClass('euiIcon');
    });

    test('@useComponent renders the given component with the icon classes', async function (assert) {
      await render(
        <template>
          <EuiIcon @type={{CustomIcon}} @useComponent={{true}} @size="l" />
        </template>
      );

      assert.dom('svg.my-custom-icon').exists();
      assert.dom('svg.my-custom-icon').hasClass('euiIcon');
      assert.dom('svg.my-custom-icon').hasStyle({ width: '24px', height: '24px' });
    });
  });

  module('lazy loading', function (hooks) {
    hooks.beforeEach(function () {
      clearIconCache();
    });

    test('it renders the empty icon until the icon has loaded', async function (assert) {
      const children = await firstRenderedChildren(() =>
        render(<template><EuiIcon @type="bell" @size="l" /></template>)
      );

      assert.strictEqual(children, 0, 'the empty icon renders first');
      assert.dom('svg path').exists('await render() waits for the icon');
      assert.dom('svg').hasStyle({ width: '24px' });
    });

    test('preloaded icons render right away', async function (assert) {
      await preloadIcons(['bell']);

      const children = await firstRenderedChildren(() =>
        render(<template><EuiIcon @type="bell" /></template>)
      );

      assert.true((children ?? 0) > 0, 'no empty icon first');
    });

    test('preloadIcons rejects names that are not EUI icons', async function (assert) {
      await assert.rejects(
        // @ts-expect-error not an icon name
        preloadIcons(['notAnIcon']),
        /"notAnIcon" is not an EUI icon/
      );
    });
  });
});
