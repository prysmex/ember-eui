import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  focus,
  render,
  rerender,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiCheckableCard from '#src/components/eui-checkable-card.gts';
import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiFieldPassword from '#src/components/eui-field-password.gts';
import EuiFilePicker from '#src/components/eui-file-picker.gts';
import EuiFilterSelectItem from '#src/components/eui-filter-select-item.gts';
import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';
import EuiFormControlLayoutDelimited from '#src/components/eui-form-control-layout-delimited.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import EuiProgress from '#src/components/eui-progress.gts';
import EuiSelectable from '#src/components/eui-selectable.gts';
import EuiSelectableTemplateSitewide from '#src/components/eui-selectable-template-sitewide.gts';
import EuiDatePopoverButton from '#src/components/eui-super-date-picker/date-popover/eui-date-popover-button.gts';
import EuiQuickSelectPanel from '#src/components/eui-super-date-picker/eui-quick-select-popover/eui-quick-select-panel.gts';
import EuiSuperUpdateButton from '#src/components/eui-super-date-picker/eui-super-update-button.gts';

import type { EuiSelectableTemplateSitewideOption } from '#src/components/eui-selectable-template-sitewide.gts';

const noop = () => {};
const el = (selector: string) => document.querySelector<HTMLElement>(selector)!;

module('Integration | Component | upstream props: forms and date pickers', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiDatePickerRange @iconSide, @isCustom and the prepend/append blocks', async function (assert) {
    await render(
      <template>
        <EuiDatePickerRange class="custom" @iconType="clock" @iconSide="right" @isCustom={{true}}>
          <:prepend as |classes|><span class="{{classes}} my-prepend">From</span></:prepend>
          <:start as |className|><input class={{className}} aria-label="Start" /></:start>
          <:end as |className|><input class={{className}} aria-label="End" /></:end>
          <:append as |classes|><span class="{{classes}} my-append">UTC</span></:append>
        </EuiDatePickerRange>
        <EuiDatePickerRange class="inline" @inline={{true}}>
          <:prepend><span class="inline-prepend">From</span></:prepend>
          <:start as |className|><input class={{className}} aria-label="Start 2" /></:start>
          <:end as |className|><input class={{className}} aria-label="End 2" /></:end>
        </EuiDatePickerRange>
      </template>
    );

    assert.dom('.custom .euiFormControlLayout__prepend .my-prepend').hasText('From');
    assert.dom('.custom .euiFormControlLayout__append .my-append').hasText('UTC');
    // the icon on the right side: after the end control
    const icon = el('.custom [data-icon-type="clock"]');
    const end = el('input[aria-label="End"]');
    assert.true(Boolean(end.compareDocumentPosition(icon) & Node.DOCUMENT_POSITION_FOLLOWING), 'icon after the inputs');
    // isCustom: only the delimited input class
    assert.dom('input[aria-label="Start"]').hasClass('euiFormControlLayoutDelimited__input').doesNotHaveClass('euiDatePickerRange__start');
    assert.dom('input[aria-label="End"]').doesNotHaveClass('euiDatePicker');
    // inline pickers drop prepend/append (upstream)
    assert.dom('.inline-prepend').doesNotExist();
    assert.dom('input[aria-label="Start 2"]').hasClass('euiDatePickerRange__start');
  });

  test('EuiFormControlLayout @wrapperProps', async function (assert) {
    const wrapperProps = { className: 'myWrapper', id: 'wrapper-id', 'data-test-subj': 'wrap', css: { outline: '3px solid rgb(255, 0, 0)' } };

    await render(
      <template>
        <EuiFormControlLayout @wrapperProps={{wrapperProps}}><input aria-label="x" /></EuiFormControlLayout>
      </template>
    );

    assert.dom('.euiFormControlLayout__childrenWrapper').hasClass('myWrapper').hasAttribute('id', 'wrapper-id').hasAttribute('data-test-subj', 'wrap');
    assert.strictEqual(getComputedStyle(el('.myWrapper')).outlineColor, 'rgb(255, 0, 0)');
  });

  test('EuiFormControlLayoutDelimited @iconsPosition, @isDropdown, @inputId and @wrapperProps', async function (assert) {
    const wrapperProps = { className: 'delimWrapper', css: { outline: '2px solid rgb(0, 128, 0)' } };

    await render(
      <template>
        <EuiFormControlLayoutDelimited @icon="search" @iconsPosition="absolute" @isDropdown={{true}} @inputId="start-input" @wrapperProps={{wrapperProps}}>
          <:startControl as |classes|><input id="start-input" class={{classes}} aria-label="Start" /></:startControl>
          <:endControl as |classes|><input class={{classes}} aria-label="End" /></:endControl>
        </EuiFormControlLayoutDelimited>
      </template>
    );

    assert.strictEqual(getComputedStyle(el('.euiFormControlLayoutIcons')).position, 'absolute', '@iconsPosition="absolute"');
    assert.dom('.euiFormControlLayout [data-icon-type="chevronSingleDown"]').exists('dropdown arrow');
    assert.dom('.euiFormControlLayout__childrenWrapper').hasClass('delimWrapper');
    assert.strictEqual(getComputedStyle(el('.delimWrapper')).outlineColor, 'rgb(0, 128, 0)');
  });

  test('EuiSuperUpdateButton passes EuiButton args through', async function (assert) {
    await render(
      <template>
        <EuiSuperUpdateButton
          @onClick={{noop}}
          @responsive={{false}}
          @fullWidth={{true}}
          @isSelected={{true}}
          @iconSide="right"
          @iconSize="s"
          @isDisabled={{true}}
          @hasAriaDisabled={{true}}
        />
      </template>
    );

    assert.dom('button.euiSuperUpdateButton').hasAttribute('aria-pressed', 'true').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
    assert.strictEqual(getComputedStyle(el('button.euiSuperUpdateButton')).width, getComputedStyle(el('button.euiSuperUpdateButton').parentElement!).width, 'full width');
  });

  test('EuiDatePopoverButton @buttonProps', async function (assert) {
    const focused: string[] = [];
    const buttonProps = {
      className: 'myDateButton',
      id: 'date-button',
      'data-test-subj': 'myDate',
      'aria-label': 'Start date',
      onFocus: () => focused.push('buttonProps')
    };
    const onFocus = () => focused.push('arg');

    await render(
      <template>
        <EuiDatePopoverButton @value="now-15m" @position="start" @onChange={{noop}} @buttonProps={{buttonProps}} @onFocus={{onFocus}} />
      </template>
    );

    assert.dom('button.euiDatePopoverButton').hasClass('myDateButton').hasClass('euiDatePopoverButton--start').hasAttribute('id', 'date-button').hasAttribute('data-test-subj', 'myDate').hasAria('label', 'Start date');
    await focus('button.euiDatePopoverButton');
    assert.deepEqual(focused, ['buttonProps', 'arg']);
  });

  test('EuiQuickSelectPanel @component', async function (assert) {
    await render(
      <template>
        <EuiQuickSelectPanel class="fs" @component="fieldset" @title="Recently used" @titleId="t1">x</EuiQuickSelectPanel>
        <EuiQuickSelectPanel class="dv" @title="Other">y</EuiQuickSelectPanel>
      </template>
    );

    assert.dom('.fs').hasTagName('fieldset');
    assert.dom('.fs legend#t1').hasText('Recently used');
    assert.dom('.dv').hasTagName('div');
    assert.dom('.dv span.euiQuickSelectPanel__title').hasText('Other');
  });

  test('EuiFieldPassword @dualToggleProps', async function (assert) {
    const clicks: string[] = [];
    const dualToggleProps = {
      'data-test-subj': 'toggle',
      'aria-label': 'Reveal',
      iconType: 'lock',
      color: 'danger',
      className: 'myToggle',
      onClick: () => clicks.push('clicked')
    };

    await render(<template><EuiFieldPassword @type="dual" @dualToggleProps={{dualToggleProps}} aria-label="Password" /></template>);

    assert.dom('[data-test-subj="toggle"]').hasClass('myToggle').hasAria('label', 'Reveal');
    assert.dom('[data-test-subj="toggle"] [data-icon-type="lock"]').exists();
    await click('[data-test-subj="toggle"]');
    assert.dom('input[aria-label="Password"]').hasAttribute('type', 'text');
    assert.deepEqual(clicks, ['clicked']);
  });

  test('EuiFilePicker @files sets the prompt; a new array replaces what was picked', async function (assert) {
    class State {
      @tracked files: File[] | null = [new File(['a'], 'report.pdf')];
    }
    const state = new State();

    await render(<template><EuiFilePicker @files={{state.files}} @display="default" /></template>);

    assert.dom('.euiFilePicker__promptText').hasText('report.pdf');
    assert.dom('.euiFilePicker').hasClass('euiFilePicker-hasFiles');

    state.files = [new File(['a'], 'a.txt'), new File(['b'], 'b.txt')];
    await rerender();
    assert.dom('.euiFilePicker__promptText').hasText('2 files selected');

    // the user removes the files: the picked state wins until @files changes
    await click('.euiFilePicker__clearButton');
    assert.dom('.euiFilePicker__promptText').hasText('Select or drag and drop a file');

    state.files = null;
    await rerender();
    assert.dom('.euiFilePicker').doesNotHaveClass('euiFilePicker-hasFiles');
  });

  test('EuiFormRow @describedByIds come first in the control aria-describedby', async function (assert) {
    const ids = ['external-hint'];

    await render(
      <template>
        <p id="external-hint">Hint</p>
        <EuiFormRow @label="Name" @helpText="Help" @id="row" @describedByIds={{ids}}>
          <input type="text" class="described" />
        </EuiFormRow>
      </template>
    );

    await waitUntil(() => el('input.described').getAttribute('aria-describedby'));
    assert.strictEqual(el('input.described').getAttribute('aria-describedby'), 'external-hint row-help-0');
  });

  test('EuiCheckableCard @labelProps', async function (assert) {
    const labelProps = { id: 'card-label', title: 'Card title', 'data-test-subj': 'cardLabel' };

    await render(<template><EuiCheckableCard @id="c1" @label="Option" @labelProps={{labelProps}} /></template>);

    assert.dom('label.euiCheckableCard__label').hasAttribute('id', 'card-label').hasAttribute('title', 'Card title').hasAttribute('data-test-subj', 'cardLabel').hasAttribute('for', 'c1');
  });

  test('EuiFilterSelectItem @toolTipContent and @toolTipProps', async function (assert) {
    class State {
      @tracked isFocused = false;
    }
    const state = new State();
    const toolTipProps = { position: 'right' as const, anchorClassName: 'myAnchor' };

    await render(
      <template>
        <EuiFilterSelectItem class="tipped" @toolTipContent="More about it" @toolTipProps={{toolTipProps}} @isFocused={{state.isFocused}}>Option</EuiFilterSelectItem>
        <EuiFilterSelectItem class="disabled" @toolTipContent="Hidden" @disabled={{true}}>Disabled</EuiFilterSelectItem>
      </template>
    );

    assert.dom('.myAnchor button.euiFilterSelectItem.tipped').exists('wrapped in the tooltip anchor');
    assert.dom('.disabled').exists();
    assert.dom('.myAnchor .disabled').doesNotExist('no tooltip when disabled');

    await triggerEvent('.tipped', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTipPopover'));
    assert.dom('.euiToolTipPopover', document.body).hasText('More about it');
    await triggerEvent('.tipped', 'mouseout');
    await waitUntil(() => !document.querySelector('.euiToolTipPopover'));

    // focusing the option (keyboard navigation) shows the tooltip
    state.isFocused = true;
    await rerender();
    await waitUntil(() => document.querySelector('.euiToolTipPopover'));
    assert.dom('.euiToolTipPopover', document.body).hasText('More about it');
  });

  test('EuiProgress @labelProps', async function (assert) {
    const labelProps = { className: 'myLabel', id: 'progress-label', css: { color: 'rgb(255, 0, 0)' } };

    await render(<template><EuiProgress @value={{20}} @max={{100}} @label="Uploading" @labelProps={{labelProps}} /></template>);

    assert.dom('.euiProgress__label').hasClass('myLabel').hasAttribute('id', 'progress-label').hasText('Uploading');
    assert.strictEqual(getComputedStyle(el('.myLabel')).color, 'rgb(255, 0, 0)');
  });

  test('EuiSelectable listProps.windowProps: size, class, initial offset and onScroll', async function (assert) {
    const options = Array.from({ length: 30 }, (_, i) => ({ label: `Option ${i}` }));
    const scrolls: { scrollOffset: number; scrollDirection: string }[] = [];
    const listProps = {
      windowProps: {
        height: 100,
        width: 250,
        className: 'myWindow',
        initialScrollOffset: 64,
        onScroll: (props: { scrollOffset: number; scrollDirection: 'forward' | 'backward' }) => scrolls.push(props)
      }
    };
    const unvirtualized = { isVirtualized: false, windowProps: { height: 100, className: 'ignored' } };

    await render(
      <template>
        <EuiSelectable class="windowed" @options={{options}} @onChange={{noop}} @listProps={{listProps}} aria-label="Many" />
        <EuiSelectable class="plain" @options={{options}} @onChange={{noop}} @listProps={{unvirtualized}} aria-label="Plain" />
      </template>
    );

    const list = el('.windowed .euiSelectableList__list');

    assert.dom(list).hasClass('myWindow');
    assert.strictEqual(list.style.height, '100px');
    assert.strictEqual(list.style.width, '250px');
    assert.strictEqual(list.scrollTop, 64, 'initialScrollOffset');

    list.scrollTop = 128;
    await triggerEvent(list, 'scroll');
    assert.strictEqual(scrolls[scrolls.length - 1]?.scrollOffset, 128);
    assert.strictEqual(scrolls[scrolls.length - 1]?.scrollDirection, 'forward');

    assert.dom('.plain .euiSelectableList__list').doesNotHaveClass('ignored', 'only while virtualized (upstream)');
  });

  test('EuiSelectableTemplateSitewide <:option> replaces the option content', async function (assert) {
    const options: EuiSelectableTemplateSitewideOption[] = [
      { label: 'Dashboards', icon: { type: 'dashboardApp' }, meta: [{ text: 'Analytics' }] }
    ];

    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{options}}>
          <:option as |option searchValue|><b class="custom">{{option.label}}!{{searchValue}}</b></:option>
        </EuiSelectableTemplateSitewide>
      </template>
    );

    await focus('input.euiSelectableTemplateSitewide__search');
    await waitUntil(() => document.querySelector('.euiSelectableTemplateSitewide__listItem'));

    assert.dom('.euiSelectableTemplateSitewide__listItem .custom', document.body).hasText('Dashboards!');
    assert.dom('.euiSelectableTemplateSitewide__listItem [data-icon-type="dashboardApp"]', document.body).exists('the icon stays');
    assert.dom('.euiSelectableTemplateSitewide__listItemTitle', document.body).doesNotExist();
  });
});
