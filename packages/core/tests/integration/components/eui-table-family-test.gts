import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import {
  click,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiTable from '#src/components/eui-table.gts';
import EuiTableBody from '#src/components/eui-table-body.gts';
import EuiTableFooter from '#src/components/eui-table-footer.gts';
import EuiTableFooterCell from '#src/components/eui-table-footer-cell.gts';
import EuiTableHeader from '#src/components/eui-table-header.gts';
import EuiTableHeaderButton from '#src/components/eui-table-header-button.gts';
import EuiTableHeaderCell from '#src/components/eui-table-header-cell.gts';
import EuiTableHeaderCellCheckbox from '#src/components/eui-table-header-cell-checkbox.gts';
import EuiTableHeaderMobile from '#src/components/eui-table-header-mobile.gts';
import EuiTablePagination from '#src/components/eui-table-pagination.gts';
import EuiTableRow from '#src/components/eui-table-row.gts';
import EuiTableRowCell from '#src/components/eui-table-row-cell.gts';
import EuiTableRowCellCheckbox from '#src/components/eui-table-row-cell-checkbox.gts';
import EuiTableSortMobile from '#src/components/eui-table-sort-mobile.gts';
import { minBreakpointQuery } from '#src/-private/table.ts';
import { euiFontSize } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { TableAlignment } from '#src/-private/table.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';
const BREAKPOINT = light.breakpoint.m as number;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** Computed value of a CSS length in the context of `parent` (rem/em aware). */
function length(parent: Element, property: 'fontSize' | 'lineHeight', value: string) {
  const probe = document.createElement('span');
  probe.style[property] = value;
  parent.appendChild(probe);
  const computed = getComputedStyle(probe)[property];
  probe.remove();
  return computed;
}

function el<T extends Element = HTMLElement>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

/** Declarations of the rules targeting `element`'s Emotion class with `suffix` (e.g. `:hover`). */
function ruleValue(element: Element, suffix: string, property: string): string | undefined {
  const classes = Array.from(element.classList).filter((name) => /^eui-spike-/.test(name));
  for (const sheet of Array.from(document.styleSheets)) {
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      continue;
    }
    for (const rule of Array.from(rules)) {
      if (!(rule instanceof CSSStyleRule)) continue;
      if (classes.some((name) =>
          rule.selectorText.split(',').map((part) => part.trim()).includes(`.${name}${suffix}`)
        )) {
        const value = rule.style.getPropertyValue(property);
        if (value) return value;
      }
    }
  }
  return undefined;
}

/** Measured box in CSS pixels (the ember-qunit container is scaled). */
function box(selector: string) {
  const container = el('#ember-testing');
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = el(selector).getBoundingClientRect();
  const round = (value: number) => Math.round((value / scale) * 100) / 100;
  return {
    width: round(rect.width),
    height: round(rect.height),
    left: round(rect.left),
    right: round(rect.right),
    top: round(rect.top),
    bottom: round(rect.bottom)
  };
}

/** The flex-family iframe technique: evaluate media queries at a real width. */
function mediaAt(width: number, query: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:200px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const matches = iframe.contentWindow!.matchMedia(query).matches;
  iframe.remove();
  return matches;
}

const s = euiFontSize(lightContext, 's');
const xs = euiFontSize(lightContext, 'xs');
const m = euiFontSize(lightContext, 'm');

const ALIGNS: TableAlignment[] = ['left', 'center', 'right'];

module('Integration | Component | Borealis table family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiTable: layout, background, typography and cell paddings/borders measured', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <div data-root>
            <EuiTable data-default>
              <EuiTableHeader>
                <EuiTableHeaderCell data-head>Name</EuiTableHeaderCell>
              </EuiTableHeader>
              <EuiTableBody>
                <EuiTableRow>
                  <EuiTableRowCell data-cell>Alice</EuiTableRowCell>
                </EuiTableRow>
              </EuiTableBody>
              <EuiTableFooter>
                <EuiTableFooterCell data-foot>Total</EuiTableFooterCell>
              </EuiTableFooter>
            </EuiTable>
            <EuiTable data-compressed @compressed={{true}} @tableLayout="auto" @hasBackground={{false}}>
              <EuiTableBody>
                <EuiTableRow>
                  <EuiTableRowCell data-ccell>Bob</EuiTableRowCell>
                </EuiTableRow>
              </EuiTableBody>
              <EuiTableFooter>
                <EuiTableFooterCell data-cfoot>Total</EuiTableFooterCell>
              </EuiTableFooter>
            </EuiTable>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = el('[data-root]');
    const table = style('[data-default]');
    assert.strictEqual(table.tableLayout, 'fixed', 'default layout fixed');
    assert.strictEqual(table.borderCollapse, 'collapse');
    assert.strictEqual(table.backgroundColor, rgb(light.colors.backgroundBasePlain), 'hasBackground default');
    assert.strictEqual(table.fontSize, length(root, 'fontSize', s.fontSize), 'uncompressed font size s');
    assert.true(table.fontFeatureSettings.includes('tnum'), 'euiNumberFormat tabular numbers');
    assert.strictEqual(el('[data-default]').getAttribute('tabindex'), '-1');
    assert.dom('[data-default]').hasClass('euiTable');
    assert.strictEqual(el('[data-default]').parentElement!.className.split(' ')[0], 'euiTable__wrapper');
    close(assert, box('[data-default]').width, box('[data-root]').width, 'full width');

    const content = style('[data-cell] .euiTableCellContent');
    assert.strictEqual(content.paddingTop, light.size.s, 'cell content padding s');
    assert.strictEqual(content.paddingLeft, light.size.s);
    assert.strictEqual(content.display, 'flex');
    assert.strictEqual(style('[data-cell]').paddingTop, '0px', 'cell itself has no padding');
    const cell = style('[data-cell]');
    assert.strictEqual(cell.borderTopWidth, '1px', 'border-vertical thin');
    assert.strictEqual(cell.borderBottomColor, rgb(light.border.color));
    assert.strictEqual(cell.borderLeftWidth, '0px', 'no vertical borders');
    assert.strictEqual(cell.color, rgb(light.colors.textParagraph));
    assert.strictEqual(cell.verticalAlign, 'middle', 'default valign');
    close(assert, box('[data-cell]').height, 8 * 2 + parseFloat(length(root, 'lineHeight', m.lineHeight)) + 1, 'row height: padding + line height + half of each collapsed border', 1);

    const head = style('[data-head]');
    assert.strictEqual(head.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(head.color, rgb(light.colors.textHeading));
    assert.strictEqual(head.fontSize, length(root, 'fontSize', xs.fontSize), 'header xs');
    assert.strictEqual(head.verticalAlign, 'middle');

    const foot = style('[data-foot]');
    assert.strictEqual(foot.backgroundColor, rgb(light.components.tableFooterBackground));
    assert.strictEqual(foot.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(style('[data-foot] .euiTableCellContent').whiteSpace, 'nowrap', 'footer truncates');

    const compressed = style('[data-compressed]');
    assert.strictEqual(compressed.tableLayout, 'auto');
    assert.strictEqual(compressed.backgroundColor, TRANSPARENT, 'hasBackground false');
    assert.strictEqual(compressed.fontSize, length(root, 'fontSize', xs.fontSize), 'compressed xs');
    assert.strictEqual(style('[data-ccell] .euiTableCellContent').paddingTop, light.size.xs, 'compressed padding xs');
    assert.strictEqual(style('[data-cfoot]').backgroundColor, TRANSPARENT, 'footer follows hasBackground');
  });

  test('EuiTableRow: selected, clickable (keyboard), hover rules, expanded and reactive args keep the element', async function (assert) {
    class State {
      @tracked isSelected = false;
      @tracked onClick: ((event: Event) => void) | undefined = undefined;
      @tracked isExpandedRow = false;
    }
    const state = new State();
    let clicks = 0;
    const handler = () => clicks++;
    await render(
      <template>
        <EuiTable>
          <EuiTableBody>
            <EuiTableRow data-row @isSelected={{state.isSelected}} @onClick={{state.onClick}}>
              <EuiTableRowCell>a</EuiTableRowCell>
            </EuiTableRow>
            <EuiTableRow data-expanded @isExpandedRow={{state.isExpandedRow}} @hasSelection={{true}}>
              <EuiTableRowCell data-expanded-cell>details</EuiTableRowCell>
            </EuiTableRow>
          </EuiTableBody>
        </EuiTable>
      </template>
    );
    const row = el('[data-row]');
    assert.strictEqual(style('[data-row]').backgroundColor, TRANSPARENT);
    assert.strictEqual(rgb(ruleValue(row, ':hover', 'background-color')!), rgb(light.components.tableRowBackgroundHover), 'hover rule');
    assert.dom(row).doesNotHaveAttribute('tabindex');

    state.isSelected = true;
    await settled();
    assert.strictEqual(el('[data-row]'), row, 'same element');
    assert.dom(row).hasClass('euiTableRow-isSelected');
    assert.strictEqual(style('[data-row]').backgroundColor, rgb(light.components.tableRowBackgroundSelected));

    state.isSelected = false;
    state.onClick = handler;
    await settled();
    assert.strictEqual(el('[data-row]'), row, 'clickable keeps the element');
    assert.dom(row).hasClass('euiTableRow-isClickable').hasAttribute('tabindex', '0');
    assert.strictEqual(style('[data-row]').cursor, 'auto', 'pointer only on hover');
    assert.strictEqual(ruleValue(row, ':hover', 'cursor'), 'pointer');
    await focus(row);
    assert.strictEqual(style('[data-row]').backgroundColor, rgb(light.components.tableRowInteractiveBackgroundFocus), 'focus background');
    await click(row);
    await triggerKeyEvent(row, 'keyup', 'Enter');
    await triggerKeyEvent(row, 'keyup', ' ');
    assert.strictEqual(clicks, 3, 'click, Enter and Space');
    const space = new KeyboardEvent('keydown', { key: ' ', cancelable: true, bubbles: true });
    row.dispatchEvent(space);
    assert.true(space.defaultPrevented, 'Space does not scroll');

    state.onClick = undefined;
    await settled();
    assert.dom(row).doesNotHaveAttribute('tabindex');
    await click(row);
    assert.strictEqual(clicks, 3, 'no handler once removed');

    state.isExpandedRow = true;
    await settled();
    assert.strictEqual(style('[data-expanded]').backgroundColor, rgb(light.components.tableRowBackgroundHover), 'expanded background');
    assert.strictEqual(style('[data-expanded-cell]').paddingLeft, light.size.xl, 'checkbox offset');
    assert.notStrictEqual(style('[data-expanded-cell] .euiTableCellContent').animationName, 'none', 'expand animation');
  });

  test('EuiTableRowCell: alignment, truncation, word breaking, text-only, valign, widths, row header and hover actions', async function (assert) {
    class State {
      @tracked align: TableAlignment = 'left';
      @tracked truncate = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiTable style="width: 600px">
          <EuiTableBody>
            <EuiTableRow data-row @hasActions={{true}}>
              <EuiTableRowCell data-cell @align={{state.align}} @truncateText={{state.truncate}} @width={{200}}>supercalifragilisticexpialidocious-and-more-and-more-text</EuiTableRowCell>
              <EuiTableRowCell data-component @textOnly={{false}} @valign="top" @minWidth="50" @maxWidth="40%"><button type="button">Edit</button></EuiTableRowCell>
              <EuiTableRowCell data-head @setScopeRow={{true}} @valign="bottom">Row</EuiTableRowCell>
              <EuiTableRowCell data-actions @hasActions={{true}} @showOnHover={{true}} @valign="baseline">Delete</EuiTableRowCell>
            </EuiTableRow>
          </EuiTableBody>
        </EuiTable>
      </template>
    );
    const cell = el('[data-cell]');
    assert.strictEqual(cell.getAttribute('style'), 'width: 200px');
    assert.strictEqual(style('[data-cell] .euiTableCellContent').justifyContent, 'normal', 'left: no alignment');
    assert.strictEqual(style('[data-cell] .euiTableCellContent').overflowWrap, 'break-word', 'wraps by default (upstream)');
    assert.dom('[data-cell] .euiTableCellContent > span.euiTableCellContent__text').exists('text span');

    for (const align of ALIGNS) {
      state.align = align;
      await settled();
      const content = style('[data-cell] .euiTableCellContent');
      const expected = { left: 'normal', center: 'center', right: 'flex-end' }[align];
      assert.strictEqual(content.justifyContent, expected, `${align} justify`);
      assert.strictEqual(content.textAlign, { left: 'start', center: 'center', right: 'end' }[align], `${align} text-align`);
    }
    state.truncate = true;
    await settled();
    assert.strictEqual(el('[data-cell]'), cell, 'same element');
    const truncated = style('[data-cell] .euiTableCellContent');
    assert.strictEqual(truncated.whiteSpace, 'nowrap');
    assert.strictEqual(truncated.overflow, 'hidden');
    assert.strictEqual(truncated.textOverflow, 'ellipsis');
    assert.strictEqual(style('[data-cell] .euiTableCellContent__text').textOverflow, 'ellipsis');
    const text = el('[data-cell] .euiTableCellContent__text');
    assert.true(text.scrollWidth > text.clientWidth, 'long text is cut');

    assert.dom('[data-component] .euiTableCellContent > button').exists('textOnly=false: no text span');
    assert.strictEqual(style('[data-component]').verticalAlign, 'top');
    assert.strictEqual(el('[data-component]').getAttribute('style'), 'min-width: 50px; max-width: 40%');

    assert.strictEqual(el('[data-head]').tagName, 'TH');
    assert.dom('[data-head]').hasAttribute('scope', 'row');
    assert.strictEqual(style('[data-head]').fontWeight, String(light.font.weight.regular));
    assert.strictEqual(style('[data-head]').textAlign, 'start');
    assert.strictEqual(style('[data-head]').verticalAlign, 'bottom');

    const actions = el('[data-actions]');
    assert.dom(actions).hasClass('euiTableRowCell--hasActions');
    assert.strictEqual(style('[data-actions]').verticalAlign, 'baseline');
    assert.strictEqual(style('[data-actions]').lineHeight, style('[data-actions]').fontSize, 'actions line-height 1');
    assert.strictEqual(style('[data-actions] .euiTableCellContent').columnGap, light.size.xs, 'actions gap');
    assert.strictEqual(style('[data-actions] .euiTableCellContent').rowGap, light.size.xs);
    assert.strictEqual(style('[data-actions] .euiBasicTableAction-showOnHover').opacity, '0', 'hidden until hover');
    await focus('[data-component] button');
    assert.strictEqual(style('[data-actions] .euiBasicTableAction-showOnHover').opacity, '0', 'other cell focus');
    actions.setAttribute('tabindex', '-1');
    actions.focus();
    await settled();
    await waitUntil(() => style('[data-actions] .euiBasicTableAction-showOnHover').opacity === '1', { timeout: 2000 });
    assert.strictEqual(style('[data-actions] .euiBasicTableAction-showOnHover').opacity, '1', 'focus-within shows it');
  });

  test('EuiTableHeaderCell: sortable button, aria-sort, sort icons, description, readOnly and reactive sort', async function (assert) {
    class State {
      @tracked isSorted = false;
      @tracked isSortAscending = true;
    }
    const state = new State();
    const sorts: string[] = [];
    const onSort = () => sorts.push('name');
    await render(
      <template>
        <EuiTable>
          <EuiTableHeader>
            <EuiTableHeaderCell data-name @onSort={{onSort}} @isSorted={{state.isSorted}} @isSortAscending={{state.isSortAscending}} @description="Full name">Name</EuiTableHeaderCell>
            <EuiTableHeaderCell data-plain @align="right" @width="25%">Plain</EuiTableHeaderCell>
            <EuiTableHeaderCell data-readonly @onSort={{onSort}} @readOnly={{true}}>Read only</EuiTableHeaderCell>
            <EuiTableHeaderCell data-empty />
          </EuiTableHeader>
        </EuiTable>
      </template>
    );
    const cell = el('[data-name]');
    assert.dom(cell).hasAttribute('role', 'columnheader').hasAttribute('scope', 'col').hasAria('sort', 'none');
    assert.dom('[data-name] button.euiTableHeaderButton').hasAttribute('type', 'button').hasAttribute('data-test-subj', 'tableHeaderSortButton');
    assert.dom('[data-name] .euiTableSortIcon--sortable').hasAttribute('data-icon-type', 'sortable');
    const button = style('[data-name] button');
    assert.strictEqual(button.width, style('[data-name]').width, 'full width button');
    assert.strictEqual(button.backgroundColor, TRANSPARENT, 'button reset');
    assert.strictEqual(button.borderTopWidth, '0px');
    assert.strictEqual(button.fontWeight, String(light.font.weight.semiBold), 'inherits weight');
    assert.strictEqual(button.color, rgb(light.colors.textHeading));
    assert.strictEqual(ruleValue(el('[data-name] button'), ':hover', 'text-decoration'), 'underline');
    assert.strictEqual(style('[data-name] .euiTableSortIcon--sortable').color, rgb(light.components.tableCellSortableIconColor), 'sortable icon tint');
    assert.strictEqual(style('[data-name] .euiTableCellContent').columnGap, light.size.xs);
    assert.strictEqual(style('[data-name] .euiTableCellContent').rowGap, light.size.xs);
    assert.dom('[data-name] .eui-textTruncate').hasAttribute('title', 'Name; Full name');
    assert.strictEqual(style('[data-name] .eui-textTruncate').textOverflow, 'ellipsis');
    assert.dom('[data-name] .euiScreenReaderOnly').hasText('Full name');
    assert.strictEqual(style('[data-name] .euiScreenReaderOnly').position, 'absolute');

    await click('[data-name] button');
    assert.deepEqual(sorts, ['name']);
    await focus('[data-name] button');
    assert.strictEqual(style('[data-name] button').color, rgb(light.colors.textPrimary), 'focus color');
    assert.strictEqual(style('[data-name] button').textDecorationLine, 'underline');

    state.isSorted = true;
    await settled();
    assert.strictEqual(el('[data-name]'), cell, 'same element');
    assert.dom(cell).hasAria('sort', 'ascending');
    assert.dom('[data-name] button').hasClass('euiTableHeaderButton-isSorted');
    assert.dom('[data-name] .euiTableSortIcon').hasAttribute('data-icon-type', 'sortUp');
    assert.dom('[data-name] .euiTableSortIcon--sortable').doesNotExist();
    state.isSortAscending = false;
    await settled();
    assert.dom(cell).hasAria('sort', 'descending');
    assert.dom('[data-name] .euiTableSortIcon').hasAttribute('data-icon-type', 'sortDown');

    assert.dom('[data-plain]').doesNotHaveAria('sort');
    assert.dom('[data-plain] button').doesNotExist();
    assert.dom('[data-plain] .euiTableSortIcon').doesNotExist();
    assert.strictEqual(style('[data-plain] .euiTableCellContent').justifyContent, 'flex-end');
    assert.strictEqual(el('[data-plain]').getAttribute('style'), 'width: 25%');

    assert.dom('[data-readonly] button').doesNotExist('read-only headers are not buttons');
    assert.dom('[data-readonly]').doesNotHaveAria('sort', 'unsorted read-only columns are not sortable (upstream)');

    assert.strictEqual(el('[data-empty]').tagName, 'TD', 'no content: td');
    assert.dom('[data-empty]').doesNotHaveAttribute('scope');
  });

  test('checkbox cells: widths, borders, alignment and selection events', async function (assert) {
    class State {
      @tracked selected = false;
    }
    const state = new State();
    const toggle = (event: Event) => {
      state.selected = (event.target as HTMLInputElement).checked;
    };
    await render(
      <template>
        <EuiTable>
          <EuiTableHeader>
            <EuiTableHeaderCellCheckbox data-head-checkbox>
              <EuiCheckbox id="all" aria-label="Select all" @checked={{state.selected}} {{on "change" toggle}} />
            </EuiTableHeaderCellCheckbox>
            <EuiTableHeaderCell>Name</EuiTableHeaderCell>
          </EuiTableHeader>
          <EuiTableBody>
            <EuiTableRow data-row @isSelectable={{true}} @isSelected={{state.selected}}>
              <EuiTableRowCellCheckbox data-row-checkbox>
                <EuiCheckbox id="one" aria-label="Select Alice" @checked={{state.selected}} {{on "change" toggle}} />
              </EuiTableRowCellCheckbox>
              <EuiTableRowCell>Alice</EuiTableRowCell>
            </EuiTableRow>
          </EuiTableBody>
        </EuiTable>
      </template>
    );
    const head = style('[data-head-checkbox]');
    assert.strictEqual(head.width, light.size.xl, 'checkbox column width');
    assert.strictEqual(head.textAlign, 'start');
    assert.strictEqual(head.verticalAlign, 'middle');
    assert.dom('[data-head-checkbox]').hasAttribute('scope', 'col');
    const row = style('[data-row-checkbox]');
    assert.strictEqual(row.width, light.size.xl);
    assert.strictEqual(row.borderTopWidth, '1px');
    assert.strictEqual(row.borderBottomColor, rgb(light.border.color));
    assert.strictEqual(style('[data-row-checkbox] .euiTableCellContent').paddingLeft, light.size.s, 'table padding applies');

    await click('#one');
    assert.true(state.selected);
    assert.dom('[data-row]').hasClass('euiTableRow-isSelected');
    assert.strictEqual(style('[data-row]').backgroundColor, rgb(light.components.tableRowBackgroundSelected));
    assert.true(el<HTMLInputElement>('#all').checked, 'select all follows');
    await click('#all');
    assert.false(state.selected);
    assert.dom('[data-row]').doesNotHaveClass('euiTableRow-isSelected');
  });

  test('responsive cards at the theme m breakpoint (window and iframe), mobile options and reactive switch', async function (assert) {
    const query = minBreakpointQuery(lightContext, 'm')!;
    assert.strictEqual(query, `(min-width: ${BREAKPOINT}px)`);
    assert.false(mediaAt(BREAKPOINT - 1, query), 'iframe at m - 1: cards');
    assert.true(mediaAt(BREAKPOINT, query), 'iframe at m: table');
    assert.strictEqual(minBreakpointQuery(lightContext, true), undefined);

    const width = window.innerWidth;
    class State {
      @tracked overrides: EuiBorealisOverrides = { breakpoint: { m: width + 1 } } as EuiBorealisOverrides;
      @tracked compressed = true;
    }
    const state = new State();
    const name = { header: 'Name', enlarge: true, width: '100%' };
    const hidden = { show: false };
    const only = { only: true, header: 'Only' };
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}}>
          <div data-root>
            <EuiTableHeaderMobile data-header-mobile>
              <EuiTableSortMobile />
            </EuiTableHeaderMobile>
            <EuiTable data-table @compressed={{state.compressed}}>
              <EuiTableHeader>
                <EuiTableHeaderCell data-head>Name</EuiTableHeaderCell>
              </EuiTableHeader>
              <EuiTableBody>
                <EuiTableRow data-row @hasSelection={{true}} @hasActions={{true}} @isSelected={{true}}>
                  <EuiTableRowCellCheckbox data-checkbox><input type="checkbox" aria-label="Select" /></EuiTableRowCellCheckbox>
                  <EuiTableRowCell data-name @mobileOptions={{name}} @align="right" @width="30%">Alice</EuiTableRowCell>
                  <EuiTableRowCell data-hidden @mobileOptions={{hidden}}>Secret</EuiTableRowCell>
                  <EuiTableRowCell data-only @mobileOptions={{only}}>Mobile</EuiTableRowCell>
                  <EuiTableRowCell data-block>
                    <:default>Desktop</:default>
                    <:mobile>Phone</:mobile>
                  </EuiTableRowCell>
                  <EuiTableRowCell data-actions @hasActions={{true}} @showOnHover={{true}} @width="100">Act</EuiTableRowCell>
                </EuiTableRow>
              </EuiTableBody>
            </EuiTable>
          </div>
        </EuiEmotionProvider>
        <EuiTable data-outside>
          <EuiTableBody><EuiTableRow data-outside-row><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
        </EuiTable>
      </template>
    );
    const table = el('[data-table]');
    const root = el('[data-root]');
    assert.strictEqual(style('[data-table] thead').display, 'none', 'cards: no header row');
    assert.strictEqual(style('[data-table]').fontSize, length(root, 'fontSize', s.fontSize), 'compressed is ignored in cards');
    const row = style('[data-row]');
    assert.strictEqual(row.display, 'flex');
    assert.strictEqual(row.flexWrap, 'wrap');
    assert.strictEqual(row.borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(row.marginBottom, light.size.s);
    assert.strictEqual(row.paddingLeft, `${32 + 4}px`, 'left column for the checkbox');
    assert.strictEqual(row.paddingRight, light.size.xxl, 'right column for actions');
    assert.strictEqual(row.backgroundColor, rgb(light.components.tableRowBackgroundSelected));
    assert.notStrictEqual(row.boxShadow, 'none', 'card shadow');
    assert.strictEqual(style('[data-row]', '::before').borderRightWidth, '1px', 'right column border');

    assert.strictEqual(style('[data-checkbox]').position, 'absolute');
    assert.strictEqual(style('[data-checkbox]').top, light.size.s);
    assert.strictEqual(style('[data-checkbox]').left, '4px');

    assert.dom('[data-name] .euiTableRowCell__mobileHeader').hasText('Name');
    const header = style('[data-name] .euiTableRowCell__mobileHeader');
    assert.strictEqual(header.color, rgb(light.colors.textSubdued));
    assert.strictEqual(header.whiteSpace, 'nowrap');
    assert.strictEqual(style('[data-name]').fontSize, length(root, 'fontSize', m.fontSize), 'enlarge');
    assert.strictEqual(style('[data-name] .euiTableCellContent').justifyContent, 'normal', 'cards default to left');
    assert.strictEqual(el('[data-name]').getAttribute('style'), 'width: 100%', 'mobile width');
    assert.strictEqual(style('[data-block]').minWidth, '50%');
    assert.dom('[data-hidden]').doesNotExist('show: false');
    assert.dom('[data-only]').exists('only: true');
    assert.dom('[data-block]').hasText('Phone', '<:mobile> block');
    assert.strictEqual(style('[data-actions]').position, 'absolute', 'actions in the right column');
    assert.strictEqual(style('[data-actions]').width, light.size.xxl);
    assert.dom('[data-actions]').doesNotHaveAttribute('style', 'no width in cards');
    assert.strictEqual(style('[data-actions] .euiBasicTableAction-showOnHover').opacity, '1', 'hover actions always show');
    assert.strictEqual(style('[data-actions] .euiTableCellContent').flexDirection, 'column');
    assert.dom('[data-header-mobile]').exists('mobile header shows in cards');
    assert.strictEqual(style('[data-header-mobile]').display, 'flex');
    assert.strictEqual(style('[data-header-mobile]').paddingTop, light.size.s);
    assert.strictEqual(style('[data-header-mobile] .euiTableSortMobile').marginLeft !== '0px', true, 'sort pushed to the end');
    assert.strictEqual(style('[data-outside] tbody tr').display, 'table-row', 'sibling outside the provider keeps the table');

    state.overrides = { breakpoint: { m: width } } as EuiBorealisOverrides;
    await settled();
    assert.strictEqual(el('[data-table]'), table, 'same table element');
    assert.strictEqual(style('[data-table] thead').display, 'table-header-group', 'at m: table');
    assert.strictEqual(style('[data-row]').display, 'table-row');
    assert.strictEqual(style('[data-table]').fontSize, length(root, 'fontSize', xs.fontSize), 'compressed applies again');
    assert.dom('[data-name] .euiTableRowCell__mobileHeader').doesNotExist();
    assert.dom('[data-hidden]').exists();
    assert.dom('[data-only]').doesNotExist();
    assert.dom('[data-block]').hasText('Desktop');
    assert.strictEqual(style('[data-name] .euiTableCellContent').justifyContent, 'flex-end');
    assert.strictEqual(el('[data-name]').getAttribute('style'), 'width: 30%');
    assert.strictEqual(el('[data-actions]').getAttribute('style'), 'width: 100px');
    assert.dom('[data-header-mobile]').doesNotExist('mobile header hidden on desktop');
    assert.strictEqual(style('[data-checkbox]').position, 'static');
  });

  test('responsive arguments: @responsive, @responsiveBreakpoint booleans and names, hasBackground cards border', async function (assert) {
    class State {
      @tracked breakpoint: boolean | 'xl' | 'xs' | undefined = true;
      @tracked responsive = true;
    }
    const state = new State();
    await render(
      <template>
        <EuiTable data-table @responsiveBreakpoint={{state.breakpoint}} @responsive={{state.responsive}} @hasBackground={{false}}>
          <EuiTableBody><EuiTableRow data-row><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
        </EuiTable>
      </template>
    );
    assert.strictEqual(style('[data-row]').display, 'flex', 'true: always cards');
    assert.strictEqual(style('[data-row]').backgroundColor, TRANSPARENT, 'no background');
    assert.strictEqual(style('[data-row]', '::after').borderTopWidth, '1px', 'pseudo border instead of the shadow');
    state.breakpoint = 'xl';
    await settled();
    assert.strictEqual(style('[data-row]').display, window.innerWidth < 1200 ? 'flex' : 'table-row', 'named breakpoint xl');
    state.breakpoint = 'xs';
    await settled();
    assert.strictEqual(style('[data-row]').display, 'table-row', 'xs: never below');
    state.breakpoint = undefined;
    state.responsive = false;
    await settled();
    assert.strictEqual(style('[data-row]').display, 'table-row', '@responsive false');
    state.breakpoint = true;
    await settled();
    assert.strictEqual(style('[data-row]').display, 'flex', '@responsiveBreakpoint wins over @responsive');
  });

  test('EuiTablePagination: upstream defaults, items per page popover, all rows and page change', async function (assert) {
    class State {
      @tracked page = 0;
      @tracked size: number | undefined = undefined;
      @tracked options: number[] | undefined = undefined;
      @tracked show = true;
    }
    const state = new State();
    const pages: number[] = [];
    const sizes: number[] = [];
    const onChangePage = (page: number) => {
      pages.push(page);
      state.page = page;
    };
    const onChangeItemsPerPage = (size: number) => {
      sizes.push(size);
      state.size = size;
    };
    await render(
      <template>
        <EuiTablePagination
          data-pagination
          @activePage={{state.page}}
          @pageCount={{4}}
          @itemsPerPage={{state.size}}
          @itemsPerPageOptions={{state.options}}
          @showPerPageOptions={{state.show}}
          @onChangePage={{onChangePage}}
          @onChangeItemsPerPage={{onChangeItemsPerPage}}
        />
      </template>
    );
    const root = el('[data-pagination]');
    assert.strictEqual(getComputedStyle(root).justifyContent, 'space-between');
    assert.strictEqual(getComputedStyle(root).flexWrap, 'wrap');
    assert.strictEqual(getComputedStyle(root).rowGap, light.size.s, 'gutter s');
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 10', 'upstream default 10');
    await click('[data-test-subj="tablePaginationPopoverButton"]');
    await waitUntil(() => document.querySelector('[data-test-subj="tablePaginationRowOptions"]'));
    const options = Array.from(document.querySelectorAll('[data-test-subj^="tablePagination-"][data-test-subj$="-rows"]'));
    assert.deepEqual(options.map((o) => o.textContent!.trim()), ['10 rows', '25 rows', '50 rows'], 'upstream options');
    assert.dom('[data-test-subj="tablePagination-10-rows"]', document.body).hasAttribute('aria-current', 'true');
    assert.dom('[data-test-subj="tablePagination-25-rows"]', document.body).doesNotHaveAttribute('aria-current');
    await click(document.querySelector('[data-test-subj="tablePagination-25-rows"]')!);
    assert.deepEqual(sizes, [25]);
    assert.dom('[data-test-subj="tablePaginationRowOptions"]', document.body).doesNotExist('closes after choosing');
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Rows per page: 25');

    await click('[data-test-subj="pagination-button-2"]');
    assert.deepEqual(pages, [2]);
    assert.dom('[aria-current="page"]').hasText('3');
    await click('[aria-label="Next page"]');
    assert.deepEqual(pages, [2, 3]);
    assert.dom('[aria-label="Next page"]').isDisabled();

    state.options = [10, 0];
    state.size = 0;
    await settled();
    assert.strictEqual(el('[data-pagination]'), root, 'same element');
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').hasText('Showing all rows');
    assert.dom('.euiPagination').doesNotExist('no pages when showing all rows');
    await click('[data-test-subj="tablePaginationPopoverButton"]');
    await waitUntil(() => document.querySelector('[data-test-subj="tablePagination-0-rows"]'));
    assert.dom('[data-test-subj="tablePagination-0-rows"]', document.body).hasText('Show all rows').hasAttribute('aria-current', 'true');
    await click(document.querySelector('[data-test-subj="tablePagination-10-rows"]')!);
    assert.deepEqual(sizes, [25, 10]);

    state.show = false;
    await settled();
    assert.dom('[data-test-subj="tablePaginationPopoverButton"]').doesNotExist('showPerPageOptions false');
    assert.dom('.euiPagination').exists();
  });

  test('mobile sort popover and header button', async function (assert) {
    const sorted: string[] = [];
    const items = [
      { name: 'Name', isSorted: true, isSortAscending: true, onSort: () => sorted.push('name') },
      { name: 'Date', onSort: () => sorted.push('date') }
    ];
    await render(
      <template>
        <EuiTableHeaderMobile @responsiveBreakpoint={{true}}>
          <EuiTableSortMobile @items={{items}} />
        </EuiTableHeaderMobile>
        <EuiTableHeaderButton data-header-button @iconType="arrowDown">Columns with a long name that truncates</EuiTableHeaderButton>
      </template>
    );
    assert.dom('.euiTableSortMobile button').hasText('Sorting');
    await click('.euiTableSortMobile button');
    await waitUntil(() => document.querySelector('.euiTableSortMobileItem'));
    assert.dom('.euiTableSortMobileItem', document.body).exists({ count: 2 });
    assert.dom('.euiTableSortMobileItem-isSorted', document.body).hasText('Name').hasAria('label', 'Sort Name descending');
    assert.dom('.euiTableSortMobileItem:not(.euiTableSortMobileItem-isSorted)', document.body).hasAria('label', 'Sort Date ascending');
    assert.dom('.euiTableSortMobileItem-isSorted [data-icon-type="sortUp"]', document.body).exists();
    await click(document.querySelectorAll('.euiTableSortMobileItem')[1]!);
    assert.deepEqual(sorted, ['date']);

    const button = style('[data-header-button]');
    assert.strictEqual(button.backgroundColor, TRANSPARENT, 'button reset');
    assert.strictEqual(button.display, 'inline-flex');
    assert.strictEqual(button.columnGap, light.size.xs);
    assert.dom('[data-header-button] span').hasAttribute('title', 'Columns with a long name that truncates');
    assert.dom('[data-header-button] .euiTableHeaderButton__icon').hasAttribute('data-icon-type', 'arrowDown');
    assert.strictEqual(ruleValue(el('[data-header-button]'), ':hover', 'text-decoration'), 'underline');
  });

  test('light/dark nearest provider, sibling isolation and JS-object overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    // JS objects, not `(hash)` (see text-handoff).
    const own: EuiBorealisOverrides = {
      size: { s: '10px' },
      colors: {
        LIGHT: { backgroundBasePlain: '#123456' },
        DARK: { backgroundBasePlain: '#abcdef' }
      }
    } as EuiBorealisOverrides;
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiTable data-parent>
            <EuiTableBody><EuiTableRow @isSelected={{true}} data-parent-row><EuiTableRowCell data-parent-cell>p</EuiTableRowCell></EuiTableRow></EuiTableBody>
            <EuiTableFooter><EuiTableFooterCell data-parent-foot>f</EuiTableFooterCell></EuiTableFooter>
          </EuiTable>
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiTable data-child>
              <EuiTableBody><EuiTableRow><EuiTableRowCell data-child-cell>c</EuiTableRowCell></EuiTableRow></EuiTableBody>
            </EuiTable>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiTable data-sibling>
            <EuiTableBody><EuiTableRow><EuiTableRowCell data-sibling-cell>s</EuiTableRowCell></EuiTableRow></EuiTableBody>
          </EuiTable>
        </EuiEmotionProvider>
      </template>
    );
    const parent = el('[data-parent]');
    assert.strictEqual(style('[data-parent]').backgroundColor, rgb(light.colors.backgroundBasePlain));
    assert.strictEqual(style('[data-child]').backgroundColor, rgb('#123456'), 'override background');
    assert.strictEqual(style('[data-child-cell] .euiTableCellContent').paddingTop, '10px', 'override size.s');
    assert.strictEqual(style('[data-parent-cell] .euiTableCellContent').paddingTop, light.size.s, 'parent unaffected');

    state.mode = 'dark';
    await settled();
    assert.strictEqual(el('[data-parent]'), parent, 'same element');
    assert.strictEqual(style('[data-parent]').backgroundColor, rgb(dark.colors.backgroundBasePlain), 'parent follows dark');
    assert.strictEqual(style('[data-parent-row]').backgroundColor, rgb(dark.components.tableRowBackgroundSelected));
    assert.strictEqual(style('[data-parent-cell]').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(style('[data-parent-cell]').borderTopColor, rgb(dark.border.color));
    assert.strictEqual(style('[data-parent-foot]').backgroundColor, rgb(dark.components.tableFooterBackground));
    assert.strictEqual(style('[data-child]').backgroundColor, rgb('#abcdef'), 'nested inherits dark with its own override');
    assert.strictEqual(style('[data-sibling]').backgroundColor, rgb(light.colors.backgroundBasePlain), 'sibling stays light');
    assert.strictEqual(style('[data-sibling-cell]').color, rgb(light.colors.textParagraph));
  });

  test('RTL: logical alignment, checkbox offsets and card columns flip', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiTable data-rtl>
            <EuiTableHeader>
              <EuiTableHeaderCellCheckbox data-head-checkbox />
              <EuiTableHeaderCell>Name</EuiTableHeaderCell>
            </EuiTableHeader>
            <EuiTableBody>
              <EuiTableRow>
                <EuiTableRowCellCheckbox />
                <EuiTableRowCell data-right @align="right">1</EuiTableRowCell>
                <EuiTableRowCell data-head @setScopeRow={{true}}>Row</EuiTableRowCell>
              </EuiTableRow>
            </EuiTableBody>
          </EuiTable>
          <EuiTable data-cards @responsiveBreakpoint={{true}}>
            <EuiTableBody>
              <EuiTableRow data-card @hasSelection={{true}}>
                <EuiTableRowCellCheckbox data-card-checkbox><input type="checkbox" aria-label="s" /></EuiTableRowCellCheckbox>
                <EuiTableRowCell>x</EuiTableRowCell>
              </EuiTableRow>
            </EuiTableBody>
          </EuiTable>
        </div>
      </template>
    );
    assert.strictEqual(style('[data-right] .euiTableCellContent').textAlign, 'end');
    assert.strictEqual(style('[data-head-checkbox]').textAlign, 'start');
    assert.strictEqual(style('[data-head]').textAlign, 'start');
    const right = box('[data-right] .euiTableCellContent__text');
    const cell = box('[data-right]');
    assert.true(right.left - cell.left < cell.right - right.right, 'right (end) alignment is on the left in RTL');
    assert.strictEqual(style('[data-card]').paddingRight, '36px', 'checkbox column on the right');
    assert.strictEqual(style('[data-card]').paddingLeft, light.size.s);
    assert.strictEqual(style('[data-card-checkbox]').right, '4px', 'checkbox inset-inline-start');
  });

  test('high contrast: cards get a real border and cell borders stay thin', async function (assert) {
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiTable data-hc @responsiveBreakpoint={{true}}>
            <EuiTableBody><EuiTableRow data-hc-row><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
          </EuiTable>
          <EuiTable data-hc-plain @responsiveBreakpoint={{true}} @hasBackground={{false}}>
            <EuiTableBody><EuiTableRow data-hc-plain-row><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
          </EuiTable>
          <EuiTable data-hc-desktop @responsiveBreakpoint={{false}}>
            <EuiTableBody><EuiTableRow><EuiTableRowCell data-hc-cell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
          </EuiTable>
        </EuiEmotionProvider>
        <EuiTable data-standard @responsiveBreakpoint={{true}}>
          <EuiTableBody><EuiTableRow data-standard-row><EuiTableRowCell>x</EuiTableRowCell></EuiTableRow></EuiTableBody>
        </EuiTable>
      </template>
    );
    assert.strictEqual(style('[data-hc-row]').borderTopWidth, '1px', 'card border in high contrast');
    assert.strictEqual(style('[data-hc-row]').borderTopStyle, 'solid');
    assert.strictEqual(style('[data-hc-plain-row]').borderTopWidth, '1px', 'plain card border');
    assert.strictEqual(style('[data-hc-plain-row]').borderTopColor, rgb(hc.border.color));
    assert.strictEqual(style('[data-standard-row]').borderTopWidth, '0px', 'standard card: shadow only');
    assert.notStrictEqual(style('[data-standard-row]').boxShadow, 'none');
    assert.strictEqual(style('[data-hc-cell]').borderTopColor, rgb(hc.border.color));
  });
});

function close(assert: Assert, actual: number, expected: number, message: string, tolerance = 0.6) {
  assert.true(Math.abs(actual - expected) <= tolerance, `${message} (${actual} ≈ ${expected})`);
}
