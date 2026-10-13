import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { on } from '@ember/modifier';

import EuiFacetButton from '#src/components/eui-facet-button.gts';
import EuiFacetGroup from '#src/components/eui-facet-group.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import { euiBadgeColors } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

// Latest-only badges: compare Borealis colors instead of legacy classes.
const badgeColors = euiBadgeColors(resolveBorealisTheme('light')) as {
  subdued: { backgroundColor: string };
  accentText: { backgroundColor: string };
};

function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

const SUBDUED = { backgroundColor: rgb(badgeColors.subdued.backgroundColor) };
const ACCENT = { backgroundColor: rgb(badgeColors.accentText.backgroundColor) };

module('Integration | Component | eui-facet-button and eui-facet-group', function (hooks) {
  setupRenderingTest(hooks);

  test('a facet button shows its name, quantity and icon', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFacetButton @quantity={{6}} {{on "click" onClick}}>
          <:default>Errors</:default>
          <:icon><EuiIcon class="euiFacetButton__icon" @type="dot" @color="danger" /></:icon>
        </EuiFacetButton>
      </template>
    );

    assert.dom('button.euiFacetButton').hasAttribute('title', 'Errors');
    // Latest-only: the unselected text is not bold (no `--unSelected` class).
    assert.notStrictEqual(getComputedStyle(document.querySelector('.euiFacetButton__text')!).fontWeight, '600');
    assert.dom('.euiFacetButton__text').hasText('Errors').hasAttribute('data-text', 'Errors');
    assert.dom('.euiFacetButton__quantity').hasText('6').hasStyle(SUBDUED);
    assert.dom('.euiFacetButton__icon').exists();

    await click('button');
    assert.strictEqual(clicks, 1);
  });

  test('selected, loading and disabled states', async function (assert) {
    await render(
      <template>
        <EuiFacetButton class="selected" @quantity={{2}} @isSelected={{true}}>A</EuiFacetButton>
        <EuiFacetButton class="loading" @quantity={{2}} @isLoading={{true}}>B</EuiFacetButton>
        <EuiFacetButton class="disabled" @quantity={{0}} @isSelected={{true}} @isDisabled={{true}}>C</EuiFacetButton>
      </template>
    );

    // Latest-only: selected text is bold (no `--isSelected` class).
    assert.strictEqual(getComputedStyle(document.querySelector('.selected .euiFacetButton__text')!).fontWeight, '600');
    // accent is the badge's default color
    assert.dom('.selected .euiFacetButton__quantity').hasStyle(ACCENT);
    assert.dom('.loading').isDisabled();
    assert.dom('.loading .euiFacetButton__spinner').exists();
    assert.dom('.loading .euiFacetButton__quantity').doesNotExist();
    assert.dom('.disabled').isDisabled();
    assert.dom('.disabled .euiFacetButton__quantity').hasText('0').hasStyle(SUBDUED);
  });

  test('a facet group lays out its buttons', async function (assert) {
    await render(
      <template>
        <EuiFacetGroup class="vertical"><EuiFacetButton>A</EuiFacetButton></EuiFacetGroup>
        <EuiFacetGroup class="horizontal" @layout="horizontal" @gutterSize="l"><EuiFacetButton>B</EuiFacetButton></EuiFacetGroup>
      </template>
    );

    assert
      .dom('.vertical')
      .hasClass('euiFacetGroup');
    // Latest-only: upstream EuiFacetGroup is a plain flex div (no EuiFlexGroup,
    // no layout/gutter modifier classes); gaps are measured in
    // eui-buttons-misc-test.gts.
    // EuiFlexGroup is latest-only: check native flex styles, not legacy classes.
    assert.strictEqual(
      getComputedStyle(document.querySelector('.vertical')!).flexDirection,
      'column'
    );
    assert.strictEqual(
      getComputedStyle(document.querySelector('.horizontal')!).flexDirection,
      'row'
    );
    assert.strictEqual(
      getComputedStyle(document.querySelector('.horizontal')!).flexWrap,
      'wrap'
    );
  });
});
