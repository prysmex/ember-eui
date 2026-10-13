import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiFilterButton from '#src/components/eui-filter-button.gts';
import EuiFilterGroup from '#src/components/eui-filter-group.gts';
import EuiFilterSelectItem from '#src/components/eui-filter-select-item.gts';
import { euiBadgeColors } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

/** Borealis empty-button text token, normalized to computed `rgb()`. */
function emptyButtonColor(color: 'Primary' | 'Text') {
  const tokens = resolveBorealisTheme('light').euiTheme.components
    .buttons as unknown as Record<string, string>;
  const probe = document.createElement('span');
  probe.style.color = tokens[`textColor${color}`]!;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

module('Integration | Component | eui-filter-group', function (hooks) {
  setupRenderingTest(hooks);

  test('a group of filter buttons', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFilterGroup @fullWidth={{true}}>
          <EuiFilterButton class="on" @withNext={{true}} @hasActiveFilters={{true}} {{on "click" onClick}}>On</EuiFilterButton>
          <EuiFilterButton class="off">Off</EuiFilterButton>
        </EuiFilterGroup>
      </template>
    );

    // Latest-only: full width is `display: flex` instead of a modifier class.
    assert.strictEqual(getComputedStyle(document.querySelector('.euiFilterGroup')!).display, 'flex');
    assert
      .dom('.on')
      .hasClass('euiFilterButton')
      .hasClass('euiFilterButton-hasActiveFilters')
      .hasClass('euiButtonEmpty');
    // Latest-only EuiButtonEmpty has no color modifier classes: check the style.
    assert.strictEqual(getComputedStyle(this.element.querySelector('.on')!).color, emptyButtonColor('Text'));
    // Upstream text wrapper is `euiFilterButton__text` (was `__textShift`).
    assert.dom('.on .euiFilterButton__text').hasText('On').hasAttribute('data-text', 'On').hasAttribute('title', 'On');
    // `@withNext` has no class any more: the next wrapper overlaps by the
    // container padding (measured in eui-buttons-misc-test.gts).

    await click('.on');
    assert.strictEqual(clicks, 1);
  });

  test('badges count available or active filters', async function (assert) {
    await render(
      <template>
        <EuiFilterButton class="available" @iconType="arrowDown" @numFilters={{12}}>Status</EuiFilterButton>
        <EuiFilterButton class="active" @iconType="arrowDown" @numFilters={{12}} @numActiveFilters={{2}} @hasActiveFilters={{true}} @isSelected={{true}}>Tags</EuiFilterButton>
        <EuiFilterButton class="none">Plain</EuiFilterButton>
      </template>
    );

    // Upstream has no `--hasIcon` class; the icon is rendered in the content.
    assert.dom('.available').hasClass('euiFilterButton-hasNotification');
    assert.dom('.available .euiFilterButton__content > svg.euiIcon').exists();
    assert.dom('.available .euiFilterButton__notification').hasText('12').hasAria('label', '12 available filters');
    // Latest-only styles: compare the Borealis badge colors, not legacy classes.
    const badgeColors = euiBadgeColors(resolveBorealisTheme('light')) as {
      subdued: { backgroundColor: string };
      accentText: { backgroundColor: string };
    };
    const background = (selector: string) =>
      getComputedStyle(document.querySelector(selector)!).backgroundColor;
    assert.strictEqual(
      background('.available .euiFilterButton__notification'),
      rgb(badgeColors.subdued.backgroundColor),
      'available count is subdued'
    );
    // A popover anchor (arrowDown) announces expanded, not pressed (upstream).
    assert.dom('.active').hasClass('euiFilterButton-isSelected').hasAria('expanded', 'true').doesNotHaveAria('pressed');
    assert.dom('.active .euiFilterButton__notification').hasText('2').hasAria('label', '2 active filters');
    assert.strictEqual(
      background('.active .euiFilterButton__notification'),
      rgb(badgeColors.accentText.backgroundColor),
      'active count is accent'
    );
    assert.dom('.none .euiFilterButton__notification').doesNotExist();
  });

  test('filter select items show whether they are applied', async function (assert) {
    await render(
      <template>
        <div role="listbox" aria-label="Status">
          <EuiFilterSelectItem class="on" @checked="on">Open</EuiFilterSelectItem>
          <EuiFilterSelectItem class="off" @checked="off">Closed</EuiFilterSelectItem>
          <EuiFilterSelectItem class="none" @isFocused={{true}}>Draft</EuiFilterSelectItem>
          <EuiFilterSelectItem class="noicons" @showIcons={{false}} @disabled={{true}}>Archived</EuiFilterSelectItem>
        </div>
      </template>
    );

    assert.dom('.on').hasAttribute('role', 'option').hasText('Open');
    assert.dom('.on .euiIcon').exists();
    assert.dom('.off .euiIcon').exists();
    // Upstream: aria-selected follows `@checked="on"`, not focus; focus is
    // the focus background (no `-isFocused` class).
    assert.dom('.on').hasAria('selected', 'true');
    assert.dom('.none').hasAria('selected', 'false');
    assert.notStrictEqual(
      getComputedStyle(document.querySelector('.none')!).backgroundColor,
      getComputedStyle(document.querySelector('.off')!).backgroundColor
    );
    assert.dom('.noicons .euiIcon').doesNotExist();
    assert.dom('.noicons').isDisabled();
  });
});

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}
