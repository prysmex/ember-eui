import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import {
  click,
  fillIn,
  focus,
  render,
  rerender,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiCard from '#src/components/eui-card.gts';
import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiFormControlLayoutDelimited from '#src/components/eui-form-control-layout-delimited.gts';
import EuiImage from '#src/components/eui-image.gts';
import EuiSelectable from '#src/components/eui-selectable.gts';
import EuiSelectableTemplateSitewide from '#src/components/eui-selectable-template-sitewide.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiTabbedContent from '#src/components/eui-tabbed-content.gts';
import EuiText from '#src/components/eui-text.gts';
import EuiTreeView from '#src/components/eui-tree-view.gts';

import type { EuiSelectableOption } from '#src/-private/selectable-options.ts';
import type { EuiTreeViewNode } from '#src/components/eui-tree-view.gts';

const URL = 'data:image/gif;base64,R0lGODlhAQABAAAAACw=';

function el<T extends Element = HTMLElement>(selector: string, root: ParentNode = document) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

class Options {
  @tracked options: EuiSelectableOption[] = [
    { label: 'Apple' },
    { label: 'Banana', checked: 'on' },
    { label: 'Carrot' }
  ];

  onChange = (options: EuiSelectableOption[]) => {
    this.options = options;
  };
}

module('Integration | Component | upstream small differences', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiText @component renders the given tag (upstream `component`)', async function (assert) {
    await render(
      <template>
        <EuiText @component="span" @size="xs" @color="subdued" data-test="span">Inline</EuiText>
        <EuiText data-test="div">Block</EuiText>
      </template>
    );
    assert.strictEqual(el('[data-test="span"]').tagName, 'SPAN');
    assert.dom('[data-test="span"]').hasClass('euiText').hasText('Inline');
    assert.strictEqual(el('[data-test="div"]').tagName, 'DIV', 'div by default');
  });

  test('delimited layouts default to the sortRight icon labelled "to"; @delimiter still wins', async function (assert) {
    class State {
      @tracked delimiter: string | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiFormControlLayoutDelimited @delimiter={{state.delimiter}}>
          <:startControl as |classes|><input class={{classes}} aria-label="Start" /></:startControl>
          <:endControl as |classes|><input class={{classes}} aria-label="End" /></:endControl>
        </EuiFormControlLayoutDelimited>
      </template>
    );
    const delimiter = el('.euiFormControlLayoutDelimited__delimiter');
    assert.dom('svg', delimiter).hasAttribute('data-icon-type', 'sortRight').hasAria('label', 'to').hasAttribute('role', 'img');
    assert.dom(delimiter).hasText('', 'no text arrow');

    state.delimiter = 'until';
    await rerender();
    assert.dom(delimiter).hasText('until');
    assert.dom('svg', delimiter).doesNotExist();

    state.delimiter = '';
    await rerender();
    assert.dom('svg', delimiter).doesNotExist('an empty string is a delimiter too (upstream `??`)');
  });

  test('EuiDatePickerRange @inline @showTimeSelect uses the wider container query', async function (assert) {
    await render(
      <template>
        <div style="width: 700px">
          <EuiDatePickerRange @inline={{true}} data-test="plain">
            <:start as |className|><div class={{className}} style="width: 200px">S</div></:start>
            <:end as |className|><div class={{className}} style="width: 200px">E</div></:end>
          </EuiDatePickerRange>
          <EuiDatePickerRange @inline={{true}} @showTimeSelect={{true}} data-test="time">
            <:start as |className|><div class={{className}} style="width: 200px">S</div></:start>
            <:end as |className|><div class={{className}} style="width: 200px">E</div></:end>
          </EuiDatePickerRange>
        </div>
      </template>
    );
    // 700px: wider than 2 × 268 + 16 (side by side) but narrower than
    // 2 × 374 + 16 (stacked with a time list), as upstream.
    const wrapper = (key: string) =>
      getComputedStyle(el(`[data-test="${key}"] .euiFormControlLayout__childrenWrapper`));
    assert.strictEqual(wrapper('plain').display, 'grid', 'without time select: side by side');
    assert.strictEqual(wrapper('time').display, 'block', 'with time select: stacked');
  });

  test('EuiSelectable: focusing the search makes no option current; keys and searches pick the first one', async function (assert) {
    const opts = new Options();
    const active: (string | null)[] = [];
    const onActive = (option: EuiSelectableOption | null) => active.push(option?.label ?? null);
    await render(
      <template>
        <EuiSelectable
          @options={{opts.options}}
          @onChange={{opts.onChange}}
          @searchable={{true}}
          @onActiveOptionChange={{onActive}}
        />
      </template>
    );
    const input = el<HTMLInputElement>('input.euiSelectableSearch');
    await focus(input);
    assert.dom('.euiSelectableListItem-isFocused').doesNotExist('focus alone: nothing current');
    assert.dom(input).doesNotHaveAria('activedescendant');

    // upstream: any other key resets and picks the first checked option
    await triggerKeyEvent(input, 'keydown', 'ArrowLeft');
    assert.dom('.euiSelectableListItem-isFocused').hasText(/Banana/, 'another key: first checked');

    await fillIn(input, 'a');
    assert.dom('.euiSelectableListItem-isFocused').exists('a search picks again while focused');
  });

  test('EuiSelectable: focusing the list still makes the first checked option current', async function (assert) {
    const opts = new Options();
    await render(<template><EuiSelectable @options={{opts.options}} @onChange={{opts.onChange}} /></template>);
    await focus('ul[role="listbox"]');
    assert.dom('.euiSelectableListItem-isFocused').hasText(/Banana/);
  });

  test('EuiSelectable searchProps: field args and other keys as attributes (upstream rest spread)', async function (assert) {
    const opts = new Options();
    const props = {
      fullWidth: false,
      isInvalid: true,
      readOnly: true,
      id: 'mySearch',
      name: 'fruit',
      maxlength: 12,
      placeholder: 'Find fruit',
      onFocus: () => {}
    };
    await render(
      <template>
        <EuiSelectable @options={{opts.options}} @onChange={{opts.onChange}} @searchable={{true}} @searchProps={{props}} />
      </template>
    );
    const input = el<HTMLInputElement>('input.euiSelectableSearch');
    assert.dom(input).hasAttribute('id', 'mySearch').hasAttribute('name', 'fruit').hasAttribute('maxlength', '12');
    assert.dom(input).hasAttribute('readonly').hasAria('invalid', 'true');
    assert.dom(input).hasAttribute('placeholder', 'Find fruit');
    assert.dom(input).doesNotHaveAttribute('onfocus', 'functions are not attributes');
    assert.dom(input).doesNotHaveAttribute('fullwidth');
    assert.notStrictEqual(getComputedStyle(input).maxWidth, '100%', 'fullWidth: false keeps the form width');
  });

  test('EuiSelectable searchProps: disabled and incremental', async function (assert) {
    const opts = new Options();
    await render(
      <template>
        <EuiSelectable @options={{opts.options}} @onChange={{opts.onChange}} @searchable={{true}} @searchProps={{hash disabled=true}} />
      </template>
    );
    assert.dom('input.euiSelectableSearch').isDisabled();
  });

  test('EuiSelectableTemplateSitewide forwards @css and searchProps attributes', async function (assert) {
    const options = [{ label: 'Dashboards' }];
    const css = { outlineStyle: 'dotted' };
    const searchProps = { name: 'site', 'aria-describedby': 'help' };
    await render(
      <template>
        <EuiSelectableTemplateSitewide @options={{options}} @css={{css}} @searchProps={{searchProps}} data-test="sitewide" />
      </template>
    );
    const root = el('[data-test="sitewide"]');
    assert.dom(root).hasClass('euiSelectableTemplateSitewide');
    assert.strictEqual(getComputedStyle(root).outlineStyle, 'dotted', '@css composed last');
    assert.dom('input.euiSelectableTemplateSitewide__search').hasAttribute('name', 'site');
  });

  test('EuiImage: attributes go on the img (and the full screen img), wrapperProps on the figure', async function (assert) {
    const wrapperProps = { className: 'myFigure', 'data-test-subj': 'figure', title: 'A figure', tabindex: -1 };
    await render(
      <template>
        <EuiImage
          @url={{URL}}
          @alt="Pixel"
          @allowFullScreen={{true}}
          @wrapperProps={{wrapperProps}}
          class="myImage"
          data-test-subj="img"
          loading="lazy"
          style="padding: 3px"
        />
      </template>
    );
    const figure = el('figure.euiImageWrapper');
    const img = el('img.euiImage', figure);
    assert.dom(img).hasClass('myImage').hasAttribute('data-test-subj', 'img').hasAttribute('loading', 'lazy');
    assert.strictEqual(getComputedStyle(img).paddingTop, '3px', 'style on the img');
    assert.dom(figure).doesNotHaveClass('myImage').doesNotHaveAttribute('loading');
    assert.dom(figure).hasClass('myFigure').hasAttribute('data-test-subj', 'figure');
    assert.dom(figure).hasAttribute('title', 'A figure', 'other wrapperProps keys are attributes').hasAttribute('tabindex', '-1');

    await click('[data-test-subj="activateFullScreenButton"]');
    assert
      .dom('[data-test-subj="fullScreenOverlayMask"] img.euiImage', document.body)
      .hasClass('myImage')
      .hasAttribute('loading', 'lazy', 'the full screen image too (upstream commonImgProps)');
  });

  test('EuiTreeView <:icon> renders each icon node yourself', async function (assert) {
    const items: EuiTreeViewNode[] = [
      {
        id: 'src',
        label: 'src',
        icon: 'folderClosed',
        iconWhenExpanded: 'folderOpen',
        isExpanded: true,
        children: [
          { id: 'index', label: 'index.ts', icon: 'document' },
          { id: 'plain', label: 'plain.txt' }
        ]
      }
    ];
    await render(
      <template>
        <EuiTreeView @items={{items}} aria-label="Files">
          <:icon as |node isExpanded|>
            <span class="custom-icon" data-node={{node.id}}>{{if isExpanded "open" "closed"}}</span>
          </:icon>
        </EuiTreeView>
      </template>
    );
    assert.dom('#src .euiTreeView__iconWrapper .custom-icon').hasAttribute('data-node', 'src').hasText('open');
    assert.dom('#index .euiTreeView__iconWrapper .custom-icon').hasAttribute('data-node', 'index').hasText('closed', 'nested levels use the block too');
    assert.dom('#plain .euiTreeView__iconWrapper').doesNotExist('nodes without an icon get no wrapper');
    assert.dom('.euiTreeView__iconWrapper .euiIcon').doesNotExist();

    await click('#src');
    assert.dom('#src .custom-icon').hasText('closed', 'follows the expanded state');
  });

  test('EuiTreeView without <:icon> keeps the icon types', async function (assert) {
    const items: EuiTreeViewNode[] = [{ id: 'a', label: 'A', icon: 'document' }];
    await render(<template><EuiTreeView @items={{items}} aria-label="Files" /></template>);
    assert.dom('#a .euiTreeView__iconWrapper [data-icon-type="document"]').exists();
  });

  test('EuiCard betaBadgeProps.anchorProps go on the badge wrapper', async function (assert) {
    const props = {
      label: 'Beta',
      anchorProps: { className: 'myAnchor', css: { outlineStyle: 'dotted' }, 'data-test-subj': 'anchor' }
    };
    await render(<template><EuiCard @title="Card" @betaBadgeProps={{props}} /></template>);
    const anchor = el('.euiCard__betaBadgeAnchor');
    assert.dom(anchor).hasClass('myAnchor').hasAttribute('data-test-subj', 'anchor');
    assert.strictEqual(getComputedStyle(anchor).outlineStyle, 'dotted', 'css after the card anchor styles');
    assert.strictEqual(getComputedStyle(anchor).position, 'absolute', 'the card anchor styles stay');
    assert.dom('.euiBetaBadge', anchor).hasText('Beta');
  });

  test('EuiTabbedContent sets the other keys of a tab as its attributes (upstream rest spread)', async function (assert) {
    const tabs = [
      { id: 'a', name: 'A', 'data-test-subj': 'tabA', 'aria-label': 'First tab', title: 'Tab A', onFocus: () => {} },
      { id: 'b', name: 'B', className: 'myTab' }
    ];
    await render(<template><EuiTabbedContent @tabs={{tabs}} /></template>);
    assert.dom('#a').hasAttribute('data-test-subj', 'tabA').hasAria('label', 'First tab').hasAttribute('title', 'Tab A');
    assert.dom('#a').doesNotHaveAttribute('name').doesNotHaveAttribute('onfocus');
    assert.dom('#b').hasClass('myTab').doesNotHaveAttribute('data-test-subj');
  });

  test('EuiSuperDatePicker date popover tabs: upstream test subjects and labels', async function (assert) {
    const noop = () => {};
    await render(<template><EuiSuperDatePicker @onTimeChange={{noop}} /></template>);
    await click('.euiDatePopoverButton--start');
    await waitUntil(() => document.querySelector('.euiDatePopoverContent'));
    assert.dom('[data-test-subj="superDatePickerAbsoluteTab"]', document.body).hasAria('label', 'Start date: Absolute').hasText('Absolute');
    assert.dom('[data-test-subj="superDatePickerRelativeTab"]', document.body).hasAria('label', 'Start date: Relative');
    assert.dom('[data-test-subj="superDatePickerNowTab"]', document.body).hasAria('label', 'Start date: Now');
  });
});
