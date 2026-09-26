import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiBadge from '#src/components/eui-badge.gts';
import EuiIcon, { TYPES } from '#src/components/eui-icon.gts';

import type EuiConfigService from '#src/services/eui-config.ts';
import type { TOC } from '@ember/component/template-only';

const CustomIcon: TOC<{ Element: SVGSVGElement }> = <template>
  <svg class="my-custom-icon" viewBox="0 0 16 16" ...attributes><circle
      cx="8"
      cy="8"
      r="4"
    /></svg>
</template>;

const DATA_URL =
  'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"></svg>';

module('Integration | Component | eui-icon', function (hooks) {
  setupRenderingTest(hooks);

  module('named EUI icons', function () {
    test('it renders a named icon as an inline svg', async function (assert) {
      await render(<template><EuiIcon @type="arrowDown" /></template>);

      assert.dom('svg').exists({ count: 1 });
      assert.dom('svg').hasClass('euiIcon');
      assert.dom('svg').hasClass('euiIcon--medium', 'defaults to size m');
      assert.dom('svg').hasAttribute('viewBox', '0 0 16 16');
      assert.dom('svg path').exists();
    });

    test('it keeps the classes inside the svg that EUI styles rely on', async function (assert) {
      await render(<template><EuiIcon @type="apmApp" /></template>);

      assert.dom('svg').hasAttribute('viewBox', '0 0 32 32');
      assert.dom('svg .euiIcon__fillSecondary').exists();
    });

    test('it keeps the data-type EUI styles the Elastic logo with', async function (assert) {
      // .euiIcon--ghost[data-type=logoElastic] ... in the EUI theme
      await render(<template><EuiIcon @type="logoElastic" /></template>);

      assert.dom('svg').hasAttribute('data-type', 'logoElastic');
      assert.dom('svg .outline').exists();
    });

    test('it resolves icons that live in sub folders (tokens)', async function (assert) {
      await render(<template><EuiIcon @type="tokenAlias" /></template>);

      assert.dom('svg').exists();
      assert.dom('svg > *').exists();
    });

    test('every named icon renders an svg with content', async function (assert) {
      const empty: string[] = [];

      // `empty` is intentionally an svg without content
      for (const type of TYPES.filter((t) => t !== 'empty')) {
        await render(<template><EuiIcon @type={{type}} /></template>);

        const svg = (this.element as HTMLElement).querySelector('svg');

        if (!svg || svg.children.length === 0 || !svg.getAttribute('viewBox')) {
          empty.push(type);
        }
      }

      assert.deepEqual(empty, [], `all ${TYPES.length} icons render`);
    });
  });

  module('size, color and classes', function () {
    test('it applies the size class', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="bell" @size="s" class="small" />
          <EuiIcon @type="bell" @size="xl" />
          <EuiIcon @type="bell" @size="original" />
        </template>
      );

      const svgs = [...(this.element as HTMLElement).querySelectorAll('svg')];

      assert.true(svgs[0]?.classList.contains('euiIcon--small'));
      assert.true(svgs[1]?.classList.contains('euiIcon--xLarge'));
      assert.false(
        [...(svgs[2]?.classList ?? [])].some((c) => /--(small|medium|large)/.test(c)),
        'original has no size class'
      );
    });

    test('a named color becomes a class', async function (assert) {
      await render(<template><EuiIcon @type="bell" @color="danger" /></template>);

      assert.dom('svg').hasClass('euiIcon--danger');
      assert.dom('svg').doesNotHaveClass('euiIcon--customColor');
    });

    test('a custom color becomes an inline fill', async function (assert) {
      await render(<template><EuiIcon @type="bell" @color="#ff0000" /></template>);

      assert.dom('svg').hasClass('euiIcon--customColor');
      assert.dom('svg').hasStyle({ fill: 'rgb(255, 0, 0)' });
    });

    test('app icons get euiIcon--app unless they are colored', async function (assert) {
      await render(
        <template>
          <EuiIcon @type="apmApp" />
          <EuiIcon @type="apmApp" @color="primary" />
        </template>
      );

      const svgs = [...(this.element as HTMLElement).querySelectorAll('svg')];

      assert.true(svgs[0]?.classList.contains('euiIcon--app'));
      assert.false(svgs[1]?.classList.contains('euiIcon--app'));
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
    test('it is aria-hidden without a title', async function (assert) {
      await render(<template><EuiIcon @type="bell" /></template>);

      assert.dom('svg').hasAttribute('aria-hidden', 'true');
    });

    test('it is not aria-hidden with a title', async function (assert) {
      await render(<template><EuiIcon @type="bell" @title="Bell" /></template>);

      assert.notStrictEqual(
        document.querySelector('svg')?.getAttribute('aria-hidden'),
        'true'
      );
      assert.dom('svg').hasAttribute('role', 'image');
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
      assert.dom('svg.my-custom-icon').hasClass('euiIcon--large');
      assert.dom('svg.my-custom-icon').hasClass('euiIcon--primary');
      assert.dom('svg.my-custom-icon').hasAttribute('aria-hidden', 'true');
    });

    test('a component passed as @type renders as a component', async function (assert) {
      await render(
        <template><EuiIcon @type={{CustomIcon}} @size="l" @color="danger" /></template>
      );

      assert.dom('img').doesNotExist();
      assert.dom('svg.my-custom-icon').exists({ count: 1 });
      assert.dom('svg.my-custom-icon').hasClass('euiIcon');
      assert.dom('svg.my-custom-icon').hasClass('euiIcon--large');
      assert.dom('svg.my-custom-icon').hasClass('euiIcon--danger');
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
      assert.dom('svg.my-custom-icon').hasClass('euiIcon--large');
    });
  });
});
