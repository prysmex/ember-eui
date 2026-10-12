import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { render, settled, waitUntil } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridRowHeightsOptions,
  EuiDataGridStyle
} from '#src/components/eui-data-grid.gts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

const COLUMNS: EuiDataGridColumn[] = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'email', displayAsText: 'Email' },
  { id: 'age', displayAsText: 'Age', schema: 'numeric' }
];

const DATA = Array.from({ length: 20 }, (_, i) => ({
  name: `Person ${i}`,
  email: `person${i}@example.com`,
  age: String(20 + i)
}));

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function px(value: string) {
  const probe = document.createElement('div');
  probe.style.width = value;
  document.body.appendChild(probe);
  const resolved = getComputedStyle(probe).width;
  probe.remove();
  return resolved;
}

function cell(row: number, col: number): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col}"]`
  );
}

class CellValue extends Component<{ Args: EuiDataGridCellValueElementProps }> {
  get value() {
    const row = DATA[this.args.rowIndex] as Record<string, string> | undefined;
    return row?.[this.args.columnId] ?? '';
  }

  <template>
    <span data-cell-value data-details={{if @isDetails "true"}}>{{this.value}}</span>
  </template>
}

function value(rowIndex: number, columnId: string): string {
  return (DATA[rowIndex] as Record<string, string>)[columnId] ?? '';
}

module('Integration | Component | EuiDataGrid', function (hooks) {
  setupRenderingTest(hooks);

  test('renders upstream grid, header, row and cell semantics', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width:600px">
            <EuiDataGrid
              aria-label="People"
              class="caller"
              data-test-grid
              @columns={{COLUMNS}}
              @rowCount={{5}}
              @toolbarVisibility={{false}}
              @renderCellValue={{CellValue}}
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );

    assert
      .dom('.euiDataGrid')
      .hasClass('caller')
      .hasClass('euiDataGrid--bordersAll')
      .hasClass('euiDataGrid--headerShade')
      .hasClass('euiDataGrid--footerOverline')
      .hasClass('euiDataGrid--rowHoverHighlight')
      .hasClass('euiDataGrid--noControls')
      .hasAttribute('data-test-grid')
      .doesNotHaveAttribute('aria-label', 'aria-label moves to the role=grid element');
    assert.dom('.euiDataGrid').doesNotHaveAttribute('aria-label');
    assert
      .dom('[role=grid]')
      .hasClass('euiDataGrid__content')
      .hasAttribute('aria-label', 'People')
      .hasAttribute('aria-rowcount', '5')
      .hasAttribute('aria-colcount', '3')
      .hasAttribute('data-test-subj', 'euiDataGridBody')
      .hasAttribute('tabindex', '0', 'the grid is tabbable until a cell takes focus');

    assert.dom('.euiDataGridHeader[role=row]').exists();
    assert.dom('[role=columnheader]').exists({ count: 3 });
    assert
      .dom('[role=columnheader][data-gridcell-column-id=name]')
      .hasClass('euiDataGridHeaderCell')
      .hasAttribute('data-gridcell-column-index', '0')
      .hasAttribute('data-gridcell-row-index', '-1')
      .hasAttribute('tabindex', '-1')
      .hasText('Name');
    assert.dom('[data-gridcell-column-id=age].euiDataGridHeaderCell').hasClass('euiDataGridHeaderCell--numeric');

    assert.dom('.euiDataGridRow[role=row]').exists({ count: 5 });
    assert.dom('[role=gridcell]').exists({ count: 15 });
    const first = cell(0, 0);
    assert.dom(first).hasClass('euiDataGridRowCell').hasClass('euiDataGridRowCell--firstColumn');
    assert.dom(first).hasAttribute('aria-rowindex', '1').hasAttribute('aria-colindex', '1');
    assert.dom(first).hasAttribute('data-gridcell-column-id', 'name');
    assert.dom(first).hasAttribute('data-gridcell-row-index', '0');
    assert.dom(first).hasAttribute('tabindex', '-1');
    assert.dom('[data-datagrid-cellcontent]', first).hasClass('euiDataGridRowCell__content--defaultHeight').hasClass('eui-textTruncate');
    assert.dom(first).hasText(value(0, 'name'));
    assert.dom(cell(1, 2)).hasClass('euiDataGridRowCell--numeric').hasClass('euiDataGridRowCell--lastColumn');
    assert.dom(cell(1, 2)).hasText('21');
    assert.dom('.euiDataGridRow[data-grid-visible-row-index="1"]').hasClass('euiDataGridRow--striped', 'odd rows are marked striped');
    assert.dom('.euiDataGridRow[data-grid-visible-row-index="2"]').doesNotHaveClass('euiDataGridRow--striped');
    assert.dom(`#${el('[role=grid]').id} ~ p[hidden]`).hasText('Cell contains interactive content.');
  });

  test('renders cells through the <:cell> block', async function (assert) {
    await render(
      <template>
        <div style="width:500px">
          <EuiDataGrid @columns={{COLUMNS}} @rowCount={{3}} @toolbarVisibility={{false}}>
            <:cell as |c|>
              <b data-block>{{c.columnId}}:{{c.rowIndex}}:{{c.colIndex}}:{{if c.isDetails "details" "cell"}}:{{c.schema}}</b>
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    assert.dom('[data-block]').exists({ count: 9 });
    assert.dom(cell(2, 2)).hasText('age:2:2:cell:numeric');
    assert.dom(cell(0, 1)).hasText('email:0:1:cell:');
  });

  test('matches upstream computed styles for the default grid style', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width:600px">
            <EuiDataGrid @columns={{COLUMNS}} @rowCount={{4}} @toolbarVisibility={{false}} @renderCellValue={{CellValue}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );

    const grid = css('.euiDataGrid');
    assert.strictEqual(grid.display, 'flex');
    assert.strictEqual(grid.flexDirection, 'column');
    const header = css('.euiDataGridHeader');
    assert.strictEqual(header.position, 'sticky');
    assert.strictEqual(header.display, 'flex');
    assert.strictEqual(header.backgroundColor, rgb(light.colors.lightestShade), 'shade header');
    const headerCell = css('.euiDataGridHeaderCell');
    assert.strictEqual(headerCell.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(headerCell.paddingLeft, px(`${parseFloat(light.size.m) / 2}px`), 'm cell padding');
    const content = css('[data-gridcell-visible-row-index="0"] .euiDataGridRowCell__content');
    assert.strictEqual(content.paddingTop, px(`${parseFloat(light.size.m) / 2}px`));
    assert.strictEqual(content.overflow, 'hidden');
    assert.strictEqual(content.whiteSpace, 'nowrap', 'default height truncates');
    const firstCell = css('.euiDataGridRowCell--firstColumn');
    assert.strictEqual(firstCell.position, 'absolute');
    assert.strictEqual(firstCell.borderBottomColor, rgb(light.components.dataGridBorderColor), 'all borders');
    assert.strictEqual(firstCell.borderLeftStyle, 'solid', 'first column has a leading border');
    assert.strictEqual(css('.euiDataGridRow').backgroundColor, rgb(light.components.dataGridRowBackground));
    assert.strictEqual(css('.euiDataGrid__content').fontFeatureSettings, '"tnum"');
    assert.strictEqual(css('.euiDataGridRowCell--numeric').textAlign, 'end', 'logical right alignment');
  });

  test('gridStyle variants react without re-creating cells', async function (assert) {
    class State {
      @tracked gridStyle: EuiDataGridStyle = {};
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width:600px">
            <EuiDataGrid
              @columns={{COLUMNS}}
              @rowCount={{4}}
              @toolbarVisibility={{false}}
              @gridStyle={{state.gridStyle}}
              @renderCellValue={{CellValue}}
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );

    const firstCell = cell(0, 0);
    const fontSizeM = parseFloat(css('.euiDataGridRowCell').fontSize);

    state.gridStyle = {
      border: 'horizontal',
      header: 'underline',
      stripes: true,
      rowHover: 'none',
      fontSize: 's',
      cellPadding: 'l'
    };
    await settled();

    assert.strictEqual(cell(0, 0), firstCell, 'cells are kept');
    assert
      .dom('.euiDataGrid')
      .hasClass('euiDataGrid--bordersHorizontal')
      .hasClass('euiDataGrid--headerUnderline')
      .hasClass('euiDataGrid--stripes')
      .hasClass('euiDataGrid--fontSizeSmall')
      .hasClass('euiDataGrid--paddingLarge')
      .doesNotHaveClass('euiDataGrid--rowHoverHighlight');
    const header = css('.euiDataGridHeader');
    assert.strictEqual(header.backgroundColor, rgb(light.colors.emptyShade));
    assert.strictEqual(header.borderBottomWidth, light.border.width.thick, 'underline header');
    assert.strictEqual(css('.euiDataGridRowCell--firstColumn').borderLeftStyle, 'none', 'horizontal borders only');
    assert.strictEqual(
      css('.euiDataGridRow[data-grid-visible-row-index="1"]').backgroundColor,
      rgb(light.components.dataGridRowStripesBackgroundStriped),
      'striped rows'
    );
    assert.ok(parseFloat(css('.euiDataGridRowCell').fontSize) < fontSizeM, 'small font');
    assert.strictEqual(
      css('[data-gridcell-visible-row-index="0"] .euiDataGridRowCell__content').paddingTop,
      px(light.size.s),
      'l cell padding'
    );

    state.gridStyle = { border: 'none' };
    await settled();
    assert.dom('.euiDataGrid').hasClass('euiDataGrid--bordersNone');
    assert.strictEqual(css('.euiDataGridRowCell--firstColumn').borderBottomStyle, 'none');
  });

  test('row heights: line counts, static heights and per-row overrides', async function (assert) {
    class State {
      @tracked options: EuiDataGridRowHeightsOptions = {};
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width:600px">
            <EuiDataGrid
              @columns={{COLUMNS}}
              @rowCount={{4}}
              @toolbarVisibility={{false}}
              @rowHeightsOptions={{state.options}}
              @renderCellValue={{CellValue}}
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );

    const rowHeight = (index: number) => el(`.euiDataGridRow[data-grid-visible-row-index="${index}"]`).offsetHeight;
    const content = el('[data-gridcell-visible-row-index="0"] .euiDataGridRowCell__content');
    const lineHeight = parseInt(getComputedStyle(content).lineHeight, 10);
    const padding = parseFloat(getComputedStyle(content).paddingTop);
    assert.strictEqual(rowHeight(0), lineHeight + padding * 2, 'single line rows are measured');

    state.options = { defaultHeight: 80, rowHeights: { 2: 120 } };
    await settled();
    assert.strictEqual(rowHeight(0), 80, 'static height');
    assert.strictEqual(rowHeight(2), 120, 'row override');
    assert.strictEqual(
      el('.euiDataGridRow[data-grid-visible-row-index="3"]').offsetTop,
      el('.euiDataGridRow[data-grid-visible-row-index="2"]').offsetTop + 120,
      'rows are positioned by their offsets'
    );
    assert.dom('[data-gridcell-visible-row-index="0"] .euiDataGridRowCell__content').hasClass('euiDataGridRowCell__content--numericalHeight');
    state.options = { defaultHeight: { lineCount: 3 } };
    await settled();
    assert.strictEqual(rowHeight(1), Math.ceil(3 * lineHeight) + padding * 2, 'line count rows');
    assert.dom('[data-gridcell-visible-row-index="1"] .euiDataGridRowCell__content').hasClass('euiDataGridRowCell__content--lineCountHeight').hasClass('euiTextBlockTruncate');
    assert.strictEqual(css('[data-gridcell-visible-row-index="1"] .euiDataGridRowCell__content').webkitLineClamp, '3');

  });

  test('auto row heights are measured from cell content', async function (assert) {
    const options: EuiDataGridRowHeightsOptions = { defaultHeight: 'auto' };
    await render(
      <template>
        <div style="width:600px">
          <EuiDataGrid
            @columns={{COLUMNS}}
            @rowCount={{3}}
            @toolbarVisibility={{false}}
            @rowHeightsOptions={{options}}
          >
            <:cell as |c|>
              {{#if (isTall c.rowIndex c.columnId)}}
                <div style="height:150px" data-tall>tall</div>
              {{else}}
                short
              {{/if}}
            </:cell>
          </EuiDataGrid>
        </div>
      </template>
    );
    await waitUntil(
      () => el('.euiDataGridRow[data-grid-visible-row-index="1"]').offsetHeight > 150
    );
    assert.dom('[data-gridcell-visible-row-index="1"] .euiDataGridRowCell__content').hasClass('euiDataGridRowCell__content--autoHeight');
    assert.ok(el('.euiDataGridRow[data-grid-visible-row-index="0"]').offsetHeight < 60);
    assert.strictEqual(
      el('.euiDataGridRow[data-grid-visible-row-index="2"]').offsetTop,
      el('.euiDataGridRow[data-grid-visible-row-index="1"]').offsetTop +
        el('.euiDataGridRow[data-grid-visible-row-index="1"]').offsetHeight
    );
  });

  test('dark mode and token overrides resolve from the nearest provider', async function (assert) {
    const overrides = { base: 20 } as never;
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <div style="width:500px">
            <EuiDataGrid data-dark @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}} @renderCellValue={{CellValue}} />
          </div>
        </EuiEmotionProvider>
        <EuiEmotionProvider @borealisOverrides={{overrides}}>
          <div style="width:500px">
            <EuiDataGrid data-light @columns={{COLUMNS}} @rowCount={{2}} @toolbarVisibility={{false}} @renderCellValue={{CellValue}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(
      getComputedStyle(el('[data-dark] .euiDataGridHeader')).backgroundColor,
      rgb(dark.colors.lightestShade)
    );
    const overridden = resolveBorealisTheme('light', { base: 20 } as never).euiTheme;
    assert.strictEqual(
      getComputedStyle(el('[data-light] .euiDataGridRowCell__content')).paddingTop,
      px(`${parseFloat(overridden.size.m) / 2}px`),
      'cell padding follows the overridden size scale'
    );
    assert.notStrictEqual(overridden.size.m, light.size.m);
  });
});

function isTall(rowIndex: number, columnId: string): boolean {
  return rowIndex === 1 && columnId === 'email';
}
