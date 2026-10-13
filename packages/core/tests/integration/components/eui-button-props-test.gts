import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';
import EuiDataGridToolbarControl from '#src/components/eui-data-grid-toolbar-control.gts';
import EuiFacetButton from '#src/components/eui-facet-button.gts';
import EuiFilterButton from '#src/components/eui-filter-button.gts';
import EuiFormControlButton from '#src/components/eui-form-control-button.gts';
import EuiHeaderLink from '#src/components/eui-header-link.gts';
import EuiHeaderSectionItemButton from '#src/components/eui-header-section-item-button.gts';
import EuiModalHeaderTitle from '#src/components/eui-modal-header-title.gts';
import EuiPaginationButton from '#src/components/eui-pagination-button.gts';
import EuiPanel from '#src/components/eui-panel.gts';
import EuiSkipLink from '#src/components/eui-skip-link.gts';

const contentProps = { className: 'myContent', 'data-test-subj': 'content', 'aria-label': 'c' };
const textProps = { class: 'myText', 'data-test-subj': 'text', title: 'tt' };
const noop = () => {};

module('Integration | Component | button props (contentProps, textProps, ...)', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiButton applies contentProps and textProps', async function (assert) {
    await render(
      <template><EuiButton @contentProps={{contentProps}} @textProps={{textProps}}>Hi</EuiButton></template>
    );
    assert.dom('.euiButton__content').hasClass('myContent').hasAttribute('data-test-subj', 'content').hasAttribute('aria-label', 'c');
    assert.dom('.euiButton__text').hasClass('myText').hasAttribute('data-test-subj', 'text').hasAttribute('title', 'tt');
  });

  test('EuiButtonEmpty applies contentProps and textProps', async function (assert) {
    await render(
      <template><EuiButtonEmpty @contentProps={{contentProps}} @textProps={{textProps}}>Hi</EuiButtonEmpty></template>
    );
    assert.dom('.euiButtonEmpty__content').hasClass('myContent').hasAttribute('data-test-subj', 'content');
    assert.dom('.euiButtonEmpty__text').hasClass('myText').hasAttribute('title', 'tt');
  });

  test('contentProps css is composed into the content class', async function (assert) {
    const cp = { css: { color: 'rgb(1, 2, 3)' } };
    await render(<template><EuiButton @contentProps={{cp}}>Hi</EuiButton></template>);
    assert.strictEqual(getComputedStyle(document.querySelector('.euiButton__content')!).color, 'rgb(1, 2, 3)');
  });

  test('EuiHeaderLink forwards contentProps, textProps and hasAriaDisabled', async function (assert) {
    await render(
      <template>
        <EuiHeaderLink @contentProps={{contentProps}} @textProps={{textProps}} @isDisabled={{true}} @hasAriaDisabled={{true}}>x</EuiHeaderLink>
      </template>
    );
    assert.dom('.euiButtonEmpty__content').hasClass('myContent');
    assert.dom('.euiButtonEmpty__text').hasClass('myText');
    assert.dom('.euiHeaderLink').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
  });

  test('EuiSkipLink forwards the EuiButton args', async function (assert) {
    await render(
      <template>
        <EuiSkipLink @destinationId="m" @color="accent" @fullWidth={{true}} @isSelected={{false}} @contentProps={{contentProps}} @textProps={{textProps}} @iconType="check" @size="m">go</EuiSkipLink>
      </template>
    );
    assert.dom('a.euiSkipLink .euiButton__content').hasClass('myContent');
    assert.dom('a.euiSkipLink .euiButton__text').hasClass('myText');
    assert.dom('a.euiSkipLink .euiButtonContent__icon').exists();
  });

  test('EuiSkipLink fill can be turned off', async function (assert) {
    await render(<template><EuiSkipLink @destinationId="m" @fill={{false}}>go</EuiSkipLink></template>);
    assert.dom('a.euiSkipLink').exists();
  });

  test('EuiHeaderSectionItemButton forwards button args', async function (assert) {
    await render(
      <template>
        <EuiHeaderSectionItemButton @isLoading={{true}} @contentProps={{contentProps}} @textProps={{textProps}} @iconType="bell" @size="m" @color="primary" aria-label="x">c</EuiHeaderSectionItemButton>
      </template>
    );
    assert.dom('.euiHeaderSectionItemButton').hasAttribute('aria-busy', 'true').isDisabled();
    assert.dom('.euiButtonEmpty__content').hasClass('myContent');
    assert.dom('.euiButtonEmpty__text').hasClass('myText');
    assert.dom('.euiButtonContent__spinner').exists();
  });

  test('EuiHeaderSectionItemButton isDisabled and isSelected', async function (assert) {
    await render(
      <template><EuiHeaderSectionItemButton @isDisabled={{true}} @isSelected={{true}} aria-label="x">c</EuiHeaderSectionItemButton></template>
    );
    assert.dom('.euiHeaderSectionItemButton').isDisabled().hasAttribute('aria-pressed', 'true');
  });

  test('EuiPaginationButton forwards button args', async function (assert) {
    await render(
      <template>
        <EuiPaginationButton @pageIndex={{0}} @isDisabled={{true}} @contentProps={{contentProps}} @textProps={{textProps}} @color="primary" />
      </template>
    );
    assert.dom('.euiPaginationButton').isDisabled();
    assert.dom('.euiButtonEmpty__content').hasClass('myContent');
    assert.dom('.euiButtonEmpty__text').hasClass('myText');
  });

  test('EuiDataGridToolbarControl contentProps and textProps', async function (assert) {
    await render(
      <template>
        <EuiDataGridToolbarControl @contentProps={{contentProps}} @textProps={{textProps}} @isLoading={{true}}>Cols</EuiDataGridToolbarControl>
      </template>
    );
    assert.dom('.euiButtonEmpty__content').hasClass('myContent');
    assert.dom('.euiDataGridToolbarControl__text').hasClass('myText').hasAttribute('title', 'tt').hasClass('eui-textTruncate');
    assert.dom('.euiDataGridToolbarControl').isDisabled();
  });

  test('EuiFacetButton element, fullWidth, size, hasAriaDisabled, contentProps, minWidth', async function (assert) {
    await render(
      <template>
        <EuiFacetButton @contentProps={{contentProps}} @fullWidth={{true}} @size="m" @minWidth={{120}} @isDisabled={{true}} @hasAriaDisabled={{true}}>f</EuiFacetButton>
        <EuiFacetButton @element="span" class="asSpan">s</EuiFacetButton>
      </template>
    );
    assert.dom('.euiFacetButton__content').hasClass('myContent').hasAttribute('data-test-subj', 'content');
    assert.dom('button.euiFacetButton').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
    assert.strictEqual((document.querySelector('button.euiFacetButton') as HTMLElement).style.minInlineSize, '120px');
    assert.dom('span.asSpan').exists().doesNotHaveAttribute('type');
  });

  test('EuiFilterButton contentProps, textProps, isLoading, hasAriaDisabled', async function (assert) {
    await render(
      <template>
        <EuiFilterButton @contentProps={{contentProps}} @textProps={{textProps}} @isLoading={{true}} @iconType="check" @iconSize="l">Filt</EuiFilterButton>
        <EuiFilterButton class="aria" @isDisabled={{true}} @hasAriaDisabled={{true}}>Aria</EuiFilterButton>
      </template>
    );
    assert.dom('.euiFilterButton__content').hasClass('myContent').hasAttribute('data-test-subj', 'content');
    assert.dom('.euiFilterButton__text').hasClass('myText').hasAttribute('title', 'tt');
    assert.dom('.euiButtonContent__spinner').exists();
    assert.dom('.euiButtonContent__icon').doesNotExist();
    assert.dom('button.aria').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
  });

  test('EuiFormControlButton contentProps, textProps, hasAriaDisabled', async function (assert) {
    await render(
      <template>
        <EuiFormControlButton @value="v" @contentProps={{contentProps}} @textProps={{textProps}} @isDisabled={{true}} @hasAriaDisabled={{true}} />
      </template>
    );
    assert.dom('.euiButtonEmpty__content').hasClass('myContent');
    assert.dom('.euiFormControlButton .myText').hasText('v').hasAttribute('title', 'tt');
    assert.dom('.euiFormControlButton').hasAttribute('aria-disabled', 'true');
  });

  test('EuiModalHeaderTitle tagName, size and textTransform', async function (assert) {
    await render(
      <template>
        <EuiModalHeaderTitle @tagName="h2" @size="l" @textTransform="uppercase">T</EuiModalHeaderTitle>
        <EuiModalHeaderTitle class="plain">P</EuiModalHeaderTitle>
      </template>
    );
    assert.dom('h2.euiModalHeader__title').hasText('T');
    assert.strictEqual(getComputedStyle(document.querySelector('h2.euiModalHeader__title')!).textTransform, 'uppercase');
    assert.dom('div.plain.euiModalHeader__title').exists();
  });

  test('EuiPanel element="button" renders a native button', async function (assert) {
    await render(
      <template>
        <EuiPanel @onClick={{noop}} @element="button" class="b">B</EuiPanel>
        <EuiPanel @onClick={{noop}} class="d">D</EuiPanel>
      </template>
    );
    assert.dom('button.b[data-eui-panel]').hasAttribute('type', 'button');
    assert.dom('div.d').hasAttribute('role', 'button');
  });
});
