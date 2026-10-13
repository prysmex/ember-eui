import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { render, settled, clearRender, click } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import EuiFlexGroup from '#src/components/eui-flex-group.gts';
import EuiFlexItem from '#src/components/eui-flex-item.gts';
import EuiFlexGrid from '#src/components/eui-flex-grid.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiFlexGroupAlignItems,
  EuiFlexGroupDirection,
  EuiFlexGroupGutterSize,
  EuiFlexGroupJustifyContent
} from '#src/components/eui-flex-group.gts';
import type { EuiFlexItemGrow } from '#src/components/eui-flex-item.gts';
import type {
  EuiFlexGridDirection,
  EuiFlexGridGutterSize
} from '#src/components/eui-flex-grid.gts';

const light = resolveBorealisTheme('light').euiTheme;
/** Borealis `m` breakpoint; upstream collapses below it (max-width: m - 1). */
const BREAKPOINT = light.breakpoint.m as number;

const GROUP_GUTTERS: Record<EuiFlexGroupGutterSize, string> = {
  none: '0px',
  xs: light.size.xs,
  s: light.size.s,
  m: light.size.base,
  l: light.size.l,
  xl: light.size.xxl
};
const GRID_GUTTERS: Record<EuiFlexGridGutterSize, string> = {
  none: '0px',
  s: light.size.s,
  m: light.size.base,
  l: light.size.l,
  xl: light.size.xl
};

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: ParentNode, selector: string) {
  return getComputedStyle(el(root, selector));
}

/** ember-qunit may scale #ember-testing; measure in layout pixels. */
function scale(element: Element) {
  const container = element.closest<HTMLElement>('#ember-testing');
  if (!container || !container.offsetWidth) return 1;
  return container.getBoundingClientRect().width / container.offsetWidth;
}

function box(root: ParentNode, selector: string) {
  const element = el(root, selector);
  const rect = element.getBoundingClientRect();
  const factor = scale(element);
  return {
    left: rect.left / factor,
    right: rect.right / factor,
    top: rect.top / factor,
    bottom: rect.bottom / factor,
    width: rect.width / factor,
    height: rect.height / factor
  };
}

function px(value: string) {
  return parseFloat(value);
}

function close(
  assert: Assert,
  actual: number,
  expected: number,
  message: string,
  tolerance = 0.6
) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${message} (expected ${expected}, got ${actual})`
  );
}

/**
 * Copies the rendered markup and every stylesheet rule (including Emotion's
 * inserted rules) into an iframe of the given width, so media queries are
 * evaluated against a real narrow viewport.
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const css = Array.from(document.styleSheets)
    .map((sheet) => {
      try {
        return Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('\n');
      } catch {
        return '';
      }
    })
    .join('\n');
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${css}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    doc,
    matches: (query: string) => win.matchMedia(query).matches,
    rect: (selector: string) => el(doc, selector).getBoundingClientRect(),
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

module('Integration | Component | Borealis flex family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiFlexGroup gutters are native gaps from the theme; default is m', async function (assert) {
    await render(
      <template>
        {{#each-in GROUP_GUTTERS as |gutter|}}
          <EuiFlexGroup
            @gutterSize={{gutter}}
            @responsive={{false}}
            style="width: 600px"
            data-gutter={{gutter}}
          >
            <EuiFlexItem data-a>a</EuiFlexItem>
            <EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
          <EuiFlexGroup
            @gutterSize={{gutter}}
            @direction="column"
            data-column-gutter={{gutter}}
          >
            <EuiFlexItem data-a>a</EuiFlexItem>
            <EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
        {{/each-in}}
        <EuiFlexGroup @responsive={{false}} data-default>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );

    for (const [gutter, size] of Object.entries(GROUP_GUTTERS)) {
      const row = `[data-gutter="${gutter}"]`;
      const measured = box(this.element, `${row} [data-b]`).left -
        box(this.element, `${row} [data-a]`).right;
      close(assert, measured, px(size), `${gutter}: horizontal gap`);
      const a = box(this.element, `${row} [data-a]`);
      const b = box(this.element, `${row} [data-b]`);
      close(assert, a.width, b.width, `${gutter}: items share space equally`);
      close(
        assert,
        a.width + b.width + measured,
        600,
        `${gutter}: items and gap fill the group (no negative margins)`
      );
      const column = `[data-column-gutter="${gutter}"]`;
      close(
        assert,
        box(this.element, `${column} [data-b]`).top -
          box(this.element, `${column} [data-a]`).bottom,
        px(size),
        `${gutter}: vertical gap in a column`
      );
    }
    assert.strictEqual(px(light.size.base), 16, 'm is 16px in Borealis');
    assert.strictEqual(px(light.size.xxl), 40, 'xl is 40px in Borealis');
    close(
      assert,
      box(this.element, '[data-default] [data-b]').left -
        box(this.element, '[data-default] [data-a]').right,
      px(light.size.base),
      'default gutter is upstream m (16px)'
    );
    const group = style(this.element, '[data-default]');
    assert.strictEqual(group.display, 'flex');
    assert.strictEqual(group.flexGrow, '1', 'groups grow inside parents');
    assert.strictEqual(group.alignItems, 'stretch');
    assert.strictEqual(group.flexWrap, 'nowrap');
    assert.strictEqual(group.marginLeft, '0px', 'no legacy negative margins');
    assert.strictEqual(style(this.element, '[data-default] [data-a]').marginLeft, '0px');
    assert.strictEqual(style(this.element, '[data-default] [data-a]').padding, '0px');
  });

  test('alignItems and justifyContent position items as upstream', async function (assert) {
    const aligns: EuiFlexGroupAlignItems[] = [
      'stretch',
      'flexStart',
      'flexEnd',
      'center',
      'baseline'
    ];
    const justifies: EuiFlexGroupJustifyContent[] = [
      'flexStart',
      'flexEnd',
      'center',
      'spaceBetween',
      'spaceAround',
      'spaceEvenly'
    ];
    await render(
      <template>
        {{#each aligns as |align|}}
          <EuiFlexGroup
            @alignItems={{align}}
            @gutterSize="none"
            @responsive={{false}}
            style="height: 100px; width: 400px"
            data-align={{align}}
          >
            <EuiFlexItem data-a style="font-size: 10px">a</EuiFlexItem>
            <EuiFlexItem data-b style="font-size: 30px">b</EuiFlexItem>
          </EuiFlexGroup>
        {{/each}}
        {{#each justifies as |justify|}}
          <EuiFlexGroup
            @justifyContent={{justify}}
            @gutterSize="none"
            @responsive={{false}}
            style="width: 600px"
            data-justify={{justify}}
          >
            <EuiFlexItem @grow={{false}} data-a style="width: 100px">a</EuiFlexItem>
            <EuiFlexItem @grow={{false}} data-b style="width: 100px">b</EuiFlexItem>
          </EuiFlexGroup>
        {{/each}}
      </template>
    );

    const groupBox = (align: string) => box(this.element, `[data-align="${align}"]`);
    const item = (align: string, which: string) =>
      box(this.element, `[data-align="${align}"] [data-${which}]`);

    close(assert, item('stretch', 'a').height, 100, 'stretch fills the cross axis');
    close(assert, item('flexStart', 'a').top, groupBox('flexStart').top, 'flexStart');
    assert.true(item('flexStart', 'a').height < 100, 'flexStart does not stretch');
    close(assert, item('flexEnd', 'a').bottom, groupBox('flexEnd').bottom, 'flexEnd');
    const centered = item('center', 'a');
    close(
      assert,
      centered.top - groupBox('center').top,
      groupBox('center').bottom - centered.bottom,
      'center'
    );
    assert.strictEqual(
      style(this.element, '[data-align="baseline"]').alignItems,
      'baseline'
    );
    assert.true(
      item('baseline', 'a').top > item('baseline', 'b').top,
      'baseline offsets the smaller text so baselines line up'
    );

    const j = (justify: string, which: string) =>
      box(this.element, `[data-justify="${justify}"] [data-${which}]`);
    const start = (justify: string) =>
      box(this.element, `[data-justify="${justify}"]`).left;
    close(assert, j('flexStart', 'a').left - start('flexStart'), 0, 'flexStart');
    close(assert, j('flexEnd', 'b').right - start('flexEnd'), 600, 'flexEnd');
    close(assert, j('center', 'a').left - start('center'), 200, 'center');
    close(assert, j('spaceBetween', 'a').left - start('spaceBetween'), 0, 'spaceBetween first');
    close(assert, j('spaceBetween', 'b').right - start('spaceBetween'), 600, 'spaceBetween last');
    close(assert, j('spaceAround', 'a').left - start('spaceAround'), 100, 'spaceAround');
    close(assert, j('spaceEvenly', 'a').left - start('spaceEvenly'), 400 / 3, 'spaceEvenly');
  });

  test('direction, wrap and RTL ordering use logical flex flow', async function (assert) {
    const directions: EuiFlexGroupDirection[] = [
      'row',
      'rowReverse',
      'column',
      'columnReverse'
    ];
    await render(
      <template>
        {{#each directions as |direction|}}
          <div dir="ltr">
            <EuiFlexGroup @direction={{direction}} style="width: 400px" data-ltr={{direction}}>
              <EuiFlexItem data-a>a</EuiFlexItem>
              <EuiFlexItem data-b>b</EuiFlexItem>
            </EuiFlexGroup>
          </div>
          <div dir="rtl">
            <EuiFlexGroup @direction={{direction}} style="width: 400px" data-rtl={{direction}}>
              <EuiFlexItem data-a>a</EuiFlexItem>
              <EuiFlexItem data-b>b</EuiFlexItem>
            </EuiFlexGroup>
          </div>
        {{/each}}
        <EuiFlexGroup @wrap={{true}} @responsive={{false}} style="width: 600px" data-wrap>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-a>a</EuiFlexItem>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-b>b</EuiFlexItem>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-c>c</EuiFlexItem>
        </EuiFlexGroup>
        <EuiFlexGroup @responsive={{false}} style="width: 600px" data-nowrap>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-a>a</EuiFlexItem>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-b>b</EuiFlexItem>
          <EuiFlexItem @grow={{false}} style="width: 250px" data-c>c</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    const at = (attr: string, direction: string, which: string) =>
      box(this.element, `[${attr}="${direction}"] [data-${which}]`);

    assert.true(at('data-ltr', 'row', 'a').left < at('data-ltr', 'row', 'b').left, 'ltr row');
    assert.true(at('data-ltr', 'rowReverse', 'a').left > at('data-ltr', 'rowReverse', 'b').left, 'ltr rowReverse');
    assert.true(at('data-rtl', 'row', 'a').left > at('data-rtl', 'row', 'b').left, 'rtl row starts on the right');
    assert.true(at('data-rtl', 'rowReverse', 'a').left < at('data-rtl', 'rowReverse', 'b').left, 'rtl rowReverse starts on the left');
    for (const attr of ['data-ltr', 'data-rtl']) {
      assert.true(at(attr, 'column', 'a').top < at(attr, 'column', 'b').top, `${attr} column`);
      assert.true(at(attr, 'columnReverse', 'a').top > at(attr, 'columnReverse', 'b').top, `${attr} columnReverse`);
      close(assert, at(attr, 'column', 'a').width, 400, `${attr} column items stretch`);
    }
    assert.strictEqual(style(this.element, '[data-ltr="rowReverse"]').flexDirection, 'row-reverse');
    assert.strictEqual(style(this.element, '[data-ltr="columnReverse"]').flexDirection, 'column-reverse');

    assert.strictEqual(style(this.element, '[data-wrap]').flexWrap, 'wrap');
    const a = box(this.element, '[data-wrap] [data-a]');
    const c = box(this.element, '[data-wrap] [data-c]');
    close(assert, c.left, a.left, 'third item wraps to the start of a new line');
    close(assert, c.top - a.bottom, px(light.size.base), 'row gap equals the gutter');
    close(assert, a.width, 250, 'wrapped items keep their width');
    assert.strictEqual(style(this.element, '[data-nowrap]').flexWrap, 'nowrap');
    const nc = box(this.element, '[data-nowrap] [data-c]');
    const na = box(this.element, '[data-nowrap] [data-a]');
    close(assert, nc.top, na.top, 'without wrap items stay on one line');
    assert.true(na.width < 250, 'and shrink to fit');
  });

  test('EuiFlexItem grow values 1–10, false/0 and invalid values', async function (assert) {
    const grows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as const;
    // Upstream warns and falls back to `true` for out-of-range values.
    const invalid = 11 as unknown as EuiFlexItemGrow;
    await render(
      <template>
        {{#each grows as |grow|}}
          <EuiFlexGroup @gutterSize="none" @responsive={{false}} style="width: 1100px" data-grow={{grow}}>
            <EuiFlexItem @grow={{grow}} data-n>n</EuiFlexItem>
            <EuiFlexItem @grow={{1}} data-one>1</EuiFlexItem>
          </EuiFlexGroup>
        {{/each}}
        <EuiFlexGroup @gutterSize="none" @responsive={{false}} style="width: 600px" data-mixed>
          <EuiFlexItem data-default>d</EuiFlexItem>
          <EuiFlexItem @grow={{true}} data-true>t</EuiFlexItem>
          <EuiFlexItem @grow={{false}} data-false><span style="display:inline-block;width:50px">f</span></EuiFlexItem>
          <EuiFlexItem @grow={{0}} data-zero><span style="display:inline-block;width:70px">z</span></EuiFlexItem>
        </EuiFlexGroup>
        <EuiFlexGroup @gutterSize="none" @responsive={{false}} style="width: 600px" data-invalid>
          <EuiFlexItem @grow={{invalid}} data-bad>x</EuiFlexItem>
          <EuiFlexItem data-ok>y</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    for (const grow of grows) {
      const n = box(this.element, `[data-grow="${grow}"] [data-n]`);
      const one = box(this.element, `[data-grow="${grow}"] [data-one]`);
      close(assert, n.width, (1100 * grow) / (grow + 1), `grow ${grow} takes ${grow} shares`, 1);
      close(assert, n.width / one.width, grow, `grow ${grow} ratio`, 0.05);
      const item = style(this.element, `[data-grow="${grow}"] [data-n]`);
      assert.strictEqual(item.flexGrow, String(grow), `flex-grow ${grow}`);
      assert.strictEqual(item.flexBasis, '0%', `grow ${grow} basis`);
    }
    const def = style(this.element, '[data-default]');
    assert.strictEqual(def.flexGrow, '1', 'default grows');
    assert.strictEqual(def.flexBasis, '0%');
    assert.strictEqual(def.display, 'flex');
    assert.strictEqual(def.flexDirection, 'column', 'items lay out their content in a column');
    close(assert, box(this.element, '[data-false]').width, 50, 'false keeps content width');
    close(assert, box(this.element, '[data-zero]').width, 70, '0 behaves like false');
    assert.strictEqual(style(this.element, '[data-false]').flexGrow, '0');
    assert.strictEqual(style(this.element, '[data-false]').flexBasis, 'auto');
    close(
      assert,
      box(this.element, '[data-default]').width,
      box(this.element, '[data-true]').width,
      'default equals true'
    );
    close(assert, box(this.element, '[data-default]').width, (600 - 120) / 2, 'grow items share the rest');
    assert.strictEqual(style(this.element, '[data-bad]').flexGrow, '1', 'invalid grow falls back to true');
    close(assert, box(this.element, '[data-bad]').width, 300, 'invalid grow behaves like true');
  });

  test('responsive groups and grids collapse below the theme m breakpoint', async function (assert) {
    await render(
      <template>
        <EuiFlexGroup data-responsive>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
        <EuiFlexGroup @responsive={{false}} data-fixed>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
        <EuiFlexGroup @direction="column" data-column>
          <EuiFlexItem data-a>a</EuiFlexItem>
        </EuiFlexGroup>
        <EuiFlexGrid @columns={{3}} data-grid>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
          <EuiFlexItem data-c>c</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGrid @columns={{3}} @responsive={{false}} data-fixed-grid>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGrid>
      </template>
    );
    assert.strictEqual(BREAKPOINT, 768, 'Borealis m breakpoint');

    // The real test window is wider than the breakpoint: no collapse.
    const query = `(max-width: ${BREAKPOINT - 1}px)`;
    assert.false(window.matchMedia(query).matches, 'test window is wide');
    assert.strictEqual(style(this.element, '[data-responsive]').flexWrap, 'nowrap');
    close(
      assert,
      box(this.element, '[data-responsive] [data-a]').top,
      box(this.element, '[data-responsive] [data-b]').top,
      'wide: items share a row'
    );

    const html = (this.element as HTMLElement).innerHTML;
    const narrow = inViewport(BREAKPOINT - 1, html);
    const wide = inViewport(BREAKPOINT, html);
    try {
      assert.true(narrow.matches(query), 'iframe at m - 1 matches the media query');
      assert.false(wide.matches(query), 'iframe at m does not');

      assert.strictEqual(narrow.style('[data-responsive]').flexWrap, 'wrap');
      const a = narrow.rect('[data-responsive] [data-a]');
      const b = narrow.rect('[data-responsive] [data-b]');
      close(assert, a.width, BREAKPOINT - 1, 'narrow: items are full width');
      close(assert, b.top - a.bottom, px(light.size.base), 'narrow: stacked with the gutter as row gap');
      assert.strictEqual(narrow.style('[data-responsive] [data-a]').flexBasis, '100%');

      assert.strictEqual(wide.style('[data-responsive]').flexWrap, 'nowrap');
      close(assert, wide.rect('[data-responsive] [data-a]').top, wide.rect('[data-responsive] [data-b]').top, 'm: still a row');

      assert.strictEqual(narrow.style('[data-fixed]').flexWrap, 'nowrap', 'responsive=false never wraps');
      close(assert, narrow.rect('[data-fixed] [data-a]').top, narrow.rect('[data-fixed] [data-b]').top, 'responsive=false keeps the row');
      assert.strictEqual(narrow.style('[data-column]').flexWrap, 'nowrap', 'column groups skip the responsive styles');
      assert.notStrictEqual(narrow.style('[data-column] [data-a]').flexBasis, '100%');

      const ga = narrow.rect('[data-grid] [data-a]');
      const gb = narrow.rect('[data-grid] [data-b]');
      close(assert, ga.left, gb.left, 'narrow grid stacks into one column');
      assert.true(gb.top > ga.bottom);
      const wa = wide.rect('[data-grid] [data-a]');
      const wb = wide.rect('[data-grid] [data-b]');
      close(assert, wa.top, wb.top, 'm: grid keeps its columns');
      const fa = narrow.rect('[data-fixed-grid] [data-a]');
      const fb = narrow.rect('[data-fixed-grid] [data-b]');
      close(assert, fa.top, fb.top, 'responsive=false grid keeps columns');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('a breakpoint token override collapses responsive groups in the scoped provider only', async function (assert) {
    // A JS object (not `(hash)`); see text-handoff.
    const overrides: EuiBorealisOverrides = {
      breakpoint: { m: 100000 }
    } as EuiBorealisOverrides;
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{overrides}}>
          <EuiFlexGroup data-scoped>
            <EuiFlexItem data-a>a</EuiFlexItem>
            <EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
        </EuiEmotionProvider>
        <EuiFlexGroup data-outside>
          <EuiFlexItem data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    assert.true(window.matchMedia('(max-width: 99999px)').matches);
    assert.strictEqual(style(this.element, '[data-scoped]').flexWrap, 'wrap');
    assert.true(
      box(this.element, '[data-scoped] [data-b]').top >
        box(this.element, '[data-scoped] [data-a]').bottom,
      'scoped group stacks'
    );
    assert.strictEqual(style(this.element, '[data-outside]').flexWrap, 'nowrap');
    close(
      assert,
      box(this.element, '[data-outside] [data-a]').top,
      box(this.element, '[data-outside] [data-b]').top,
      'outside sibling keeps the default breakpoint'
    );
  });

  test('EuiFlexGrid columns, gutters, alignment and direction', async function (assert) {
    const columns = [1, 2, 3, 4];
    const directions: EuiFlexGridDirection[] = ['row', 'column'];
    await render(
      <template>
        {{#each columns as |count|}}
          <EuiFlexGrid @columns={{count}} @gutterSize="none" style="width: 800px" data-columns={{count}}>
            <EuiFlexItem data-i="1">1</EuiFlexItem><EuiFlexItem data-i="2">2</EuiFlexItem>
            <EuiFlexItem data-i="3">3</EuiFlexItem><EuiFlexItem data-i="4">4</EuiFlexItem>
            <EuiFlexItem data-i="5">5</EuiFlexItem>
          </EuiFlexGrid>
        {{/each}}
        {{#each-in GRID_GUTTERS as |gutter|}}
          <EuiFlexGrid @columns={{2}} @gutterSize={{gutter}} style="width: 600px" data-gutter={{gutter}}>
            <EuiFlexItem data-i="1">1</EuiFlexItem><EuiFlexItem data-i="2">2</EuiFlexItem>
            <EuiFlexItem data-i="3">3</EuiFlexItem>
          </EuiFlexGrid>
        {{/each-in}}
        {{#each directions as |direction|}}
          <EuiFlexGrid @columns={{2}} @direction={{direction}} data-direction={{direction}}>
            <EuiFlexItem data-i="1">1</EuiFlexItem><EuiFlexItem data-i="2">2</EuiFlexItem>
            <EuiFlexItem data-i="3">3</EuiFlexItem><EuiFlexItem data-i="4">4</EuiFlexItem>
            <EuiFlexItem data-i="5">5</EuiFlexItem>
          </EuiFlexGrid>
        {{/each}}
        <EuiFlexGrid data-default style="width: 600px">
          <EuiFlexItem data-i="1">1</EuiFlexItem><EuiFlexItem data-i="2">2</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGrid @columns={{2}} @alignItems="start" data-align-start>
          <EuiFlexItem data-i="1">1</EuiFlexItem>
          <EuiFlexItem data-i="2" style="height: 80px">2</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGrid @columns={{2}} data-align-stretch>
          <EuiFlexItem data-i="1">1</EuiFlexItem>
          <EuiFlexItem data-i="2" style="height: 80px">2</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGrid @columns={{0}} @gutterSize="s" style="width: 600px" data-wrap>
          <EuiFlexItem data-i="1"><span style="display:inline-block;width:250px">1</span></EuiFlexItem>
          <EuiFlexItem data-i="2"><span style="display:inline-block;width:250px">2</span></EuiFlexItem>
          <EuiFlexItem data-i="3"><span style="display:inline-block;width:250px">3</span></EuiFlexItem>
        </EuiFlexGrid>
        <div dir="rtl">
          <EuiFlexGrid @columns={{2}} data-rtl>
            <EuiFlexItem data-i="1">1</EuiFlexItem><EuiFlexItem data-i="2">2</EuiFlexItem>
          </EuiFlexGrid>
        </div>
      </template>
    );
    const at = (root: string, i: number) => box(this.element, `${root} [data-i="${i}"]`);

    for (const count of columns) {
      const root = `[data-columns="${count}"]`;
      assert.strictEqual(style(this.element, root).display, 'grid');
      const lefts = new Set([1, 2, 3, 4, 5].map((i) => Math.round(at(root, i).left)));
      assert.strictEqual(lefts.size, count, `${count} columns`);
      close(assert, at(root, 1).width, 800 / count, `${count} equal columns`);
    }
    for (const [gutter, size] of Object.entries(GRID_GUTTERS)) {
      const root = `[data-gutter="${gutter}"]`;
      close(assert, at(root, 2).left - at(root, 1).right, px(size), `grid ${gutter} column gap`);
      close(assert, at(root, 3).top - at(root, 1).bottom, px(size), `grid ${gutter} row gap`);
    }
    assert.strictEqual(px(light.size.xl), 32, 'grid xl is 32px (size.xl)');

    // row: 1 2 / 3 4 / 5. column: 1 4 / 2 5 / 3 (rows = ceil(5 / 2)).
    const row = '[data-direction="row"]';
    close(assert, at(row, 2).top, at(row, 1).top, 'row fills across');
    assert.true(at(row, 3).top > at(row, 1).top);
    const col = '[data-direction="column"]';
    close(assert, at(col, 2).left, at(col, 1).left, 'column fills down');
    close(assert, at(col, 3).left, at(col, 1).left);
    close(assert, at(col, 4).top, at(col, 1).top, 'fourth item starts the second column');
    assert.true(at(col, 4).left > at(col, 1).left);
    assert.strictEqual(style(this.element, col).gridAutoFlow, 'column');
    assert.strictEqual(
      el(this.element, col).style.gridTemplateRows,
      'repeat(3, 1fr)',
      'column direction sets rows like upstream'
    );
    assert.strictEqual(el(this.element, row).style.gridTemplateRows, '', 'row direction leaves rows alone');

    const def = '[data-default]';
    close(assert, at(def, 1).width, 600, 'default is one column (upstream)');
    assert.true(at(def, 2).top > at(def, 1).bottom);
    close(assert, at(def, 2).top - at(def, 1).bottom, 24, 'default grid gutter is l');

    assert.true(at('[data-align-start]', 1).height < 80, 'start does not stretch');
    close(assert, at('[data-align-stretch]', 1).height, 80, 'stretch fills the row');

    const wrap = '[data-wrap]';
    close(assert, at(wrap, 1).width, 250, 'columns=0 keeps item width');
    close(assert, at(wrap, 2).left - at(wrap, 1).right, px(light.size.s), 'columns=0 uses the gutter');
    close(assert, at(wrap, 3).left, at(wrap, 1).left, 'columns=0 wraps');

    assert.true(at('[data-rtl]', 1).left > at('[data-rtl]', 2).left, 'RTL grid fills from the right');
  });

  test('column grids track their item count; args update without replacing elements', async function (assert) {
    class State {
      @tracked items = [1, 2, 3];
      @tracked columns = 2;
      @tracked direction: EuiFlexGridDirection = 'column';
      @tracked gutter: EuiFlexGroupGutterSize = 's';
      @tracked groupDirection: EuiFlexGroupDirection = 'row';
      @tracked wrap = false;
      @tracked grow: EuiFlexItemGrow = 1;
      @tracked align: EuiFlexGroupAlignItems = 'stretch';
    }
    const state = new State();
    await render(
      <template>
        <EuiFlexGrid @columns={{state.columns}} @direction={{state.direction}} data-grid>
          {{#each state.items as |item|}}
            <EuiFlexItem data-i={{item}}>{{item}}</EuiFlexItem>
          {{/each}}
        </EuiFlexGrid>
        <EuiFlexGroup
          @gutterSize={{state.gutter}}
          @direction={{state.groupDirection}}
          @wrap={{state.wrap}}
          @alignItems={{state.align}}
          @responsive={{false}}
          style="width: 600px"
          data-group
        >
          <EuiFlexItem @grow={{state.grow}} data-a>a</EuiFlexItem>
          <EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    const grid = el(this.element, '[data-grid]');
    const group = el(this.element, '[data-group]');
    const item = el(this.element, '[data-group] [data-a]');
    assert.strictEqual(grid.style.gridTemplateRows, 'repeat(2, 1fr)');

    state.items = [1, 2, 3, 4, 5, 6, 7];
    await settled();
    await new Promise((resolve) => setTimeout(resolve, 0));
    assert.strictEqual(grid.style.gridTemplateRows, 'repeat(4, 1fr)', 'rows follow added items');

    state.columns = 4;
    await settled();
    assert.strictEqual(grid.style.gridTemplateRows, 'repeat(2, 1fr)', 'rows follow columns');

    state.direction = 'row';
    await settled();
    assert.strictEqual(grid.style.gridTemplateRows, '', 'row direction removes rows');
    assert.strictEqual(style(this.element, '[data-grid]').gridAutoFlow, 'row');

    close(
      assert,
      box(this.element, '[data-group] [data-b]').left - box(this.element, '[data-group] [data-a]').right,
      8,
      'initial gutter s'
    );
    state.gutter = 'xl';
    state.grow = 3;
    state.align = 'center';
    await settled();
    close(
      assert,
      box(this.element, '[data-group] [data-b]').left - box(this.element, '[data-group] [data-a]').right,
      40,
      'gutter updates'
    );
    close(assert, box(this.element, '[data-group] [data-a]').width, ((600 - 40) * 3) / 4, 'grow updates', 1);
    assert.strictEqual(style(this.element, '[data-group]').alignItems, 'center');

    state.groupDirection = 'column';
    state.wrap = true;
    state.grow = false;
    await settled();
    assert.strictEqual(style(this.element, '[data-group]').flexDirection, 'column');
    assert.strictEqual(style(this.element, '[data-group]').flexWrap, 'wrap');
    assert.strictEqual(style(this.element, '[data-group] [data-a]').flexGrow, '0');

    assert.strictEqual(el(this.element, '[data-grid]'), grid, 'grid element kept');
    assert.strictEqual(el(this.element, '[data-group]'), group, 'group element kept');
    assert.strictEqual(el(this.element, '[data-group] [data-a]'), item, 'item element kept');

    await clearRender();
    assert.dom('.euiFlexGroup, .euiFlexItem, .euiFlexGrid').doesNotExist('teardown');
  });

  test('nested groups keep their own gutters and fill their items', async function (assert) {
    await render(
      <template>
        <EuiFlexGroup @gutterSize="xl" @responsive={{false}} style="width: 800px" data-outer>
          <EuiFlexItem data-outer-a>
            <EuiFlexGroup @gutterSize="xs" @responsive={{false}} data-inner>
              <EuiFlexItem data-inner-a>a</EuiFlexItem>
              <EuiFlexItem data-inner-b>b</EuiFlexItem>
            </EuiFlexGroup>
          </EuiFlexItem>
          <EuiFlexItem data-outer-b>
            <EuiFlexGrid @columns={{2}} @gutterSize="m" data-inner-grid>
              <EuiFlexItem data-g1>1</EuiFlexItem>
              <EuiFlexItem data-g2>2</EuiFlexItem>
            </EuiFlexGrid>
          </EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    const outerA = box(this.element, '[data-outer-a]');
    const outerB = box(this.element, '[data-outer-b]');
    close(assert, outerB.left - outerA.right, 40, 'outer xl gutter');
    close(assert, outerA.width, (800 - 40) / 2, 'outer items share space');
    close(assert, box(this.element, '[data-inner]').width, outerA.width, 'nested group fills its item');
    close(
      assert,
      box(this.element, '[data-inner-b]').left - box(this.element, '[data-inner-a]').right,
      4,
      'inner xs gutter is independent'
    );
    close(
      assert,
      box(this.element, '[data-g2]').left - box(this.element, '[data-g1]').right,
      16,
      'nested grid m gutter'
    );
    close(assert, box(this.element, '[data-inner-grid]').width, outerB.width, 'nested grid fills its item');
  });

  test('light/dark providers, sibling isolation and size token overrides on gutters', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const nested: EuiBorealisOverrides = { size: { xs: '6px' } };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiFlexGroup @responsive={{false}} data-m>
            <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
          <EuiFlexGroup @gutterSize="l" @responsive={{false}} data-l>
            <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
          <EuiFlexGrid @columns={{2}} @gutterSize="xl" data-grid>
            <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGrid>
          <EuiEmotionProvider @borealisOverrides={{nested}}>
            <EuiFlexGroup @gutterSize="xs" @responsive={{false}} data-nested>
              <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
            </EuiFlexGroup>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="dark">
          <EuiFlexGroup @responsive={{false}} data-dark>
            <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
          </EuiFlexGroup>
        </EuiEmotionProvider>
        <EuiFlexGroup @responsive={{false}} data-outside>
          <EuiFlexItem data-a>a</EuiFlexItem><EuiFlexItem data-b>b</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    const gap = (root: string) =>
      box(this.element, `${root} [data-b]`).left - box(this.element, `${root} [data-a]`).right;

    close(assert, gap('[data-m]'), 16, 'light m');
    close(assert, gap('[data-dark]'), 16, 'dark provider resolves the same layout tokens');
    close(assert, gap('[data-nested]'), 6, 'nested size override');

    const element = el(this.element, '[data-m]');
    state.mode = 'dark';
    const sizeOverrides = { size: { base: '20px', l: '30px', xl: '36px' } };
    state.overrides = sizeOverrides;
    await settled();
    const expected = resolveBorealisTheme('dark', sizeOverrides).euiTheme;
    assert.strictEqual(expected.size.base, '20px');
    // Computed sizes do not re-derive from an overridden base in
    // theme-common 10.1, so each size is overridden explicitly.
    close(assert, gap('[data-m]'), px(expected.size.base), 'm follows the base override');
    close(assert, gap('[data-l]'), px(expected.size.l), 'l follows its override');
    assert.strictEqual(expected.size.l, '30px');
    close(assert, gap('[data-grid]'), px(expected.size.xl), 'grid xl follows the override');
    close(assert, gap('[data-nested]'), 6, 'nearest provider still wins');
    close(assert, gap('[data-outside]'), 16, 'outside sibling keeps defaults');
    close(assert, gap('[data-dark]'), 16, 'sibling dark provider is unaffected');
    assert.strictEqual(el(this.element, '[data-m]'), element, 'mode/override changes keep the element');

    state.overrides = {};
    await settled();
    close(assert, gap('[data-m]'), 16, 'removing overrides restores defaults');
  });

  test('tags, attributes, events and blocks; list roots are reset', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <p>
          Text
          <EuiFlexGroup @tagName="span" @responsive={{false}} @alignItems="center" class="custom-group" aria-label="inline group" data-span>
            <EuiFlexItem @tagName="span" @grow={{false}} data-span-item>icon</EuiFlexItem>
            <EuiFlexItem @tagName="span" @grow={{false}}>label</EuiFlexItem>
          </EuiFlexGroup>
        </p>
        <EuiFlexGrid @tagName="ul" @columns={{2}} aria-labelledby="legend" class="custom-grid" data-list>
          <EuiFlexItem @tagName="li" data-li>one</EuiFlexItem>
          <EuiFlexItem @tagName="li">two</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGroup data-group role="list">
          <EuiFlexItem @tagName="section" role="listitem" data-section {{on "click" onClick}}>
            <button type="button" data-button>Inside</button>
          </EuiFlexItem>
          <EuiFlexItem @tagName="p" data-p>para</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );
    assert.dom('[data-span]').hasTagName('span').hasClass('euiFlexGroup').hasClass('custom-group').hasAria('label', 'inline group');
    assert.strictEqual(style(this.element, '[data-span]').display, 'flex');
    assert.dom('[data-span-item]').hasTagName('span').hasClass('euiFlexItem').hasText('icon');

    assert.dom('[data-list]').hasTagName('ul').hasClass('euiFlexGrid').hasClass('custom-grid').hasAttribute('aria-labelledby', 'legend');
    const list = style(this.element, '[data-list]');
    assert.strictEqual(list.display, 'grid');
    assert.strictEqual(list.paddingInlineStart, '0px', 'ul padding reset');
    assert.strictEqual(list.marginTop, '0px', 'ul margin reset');
    assert.strictEqual(list.listStyleType, 'none');
    assert.dom('[data-li]').hasTagName('li').hasClass('euiFlexItem');
    assert.strictEqual(style(this.element, '[data-li]').display, 'flex', 'li items do not render markers');

    assert.dom('[data-section]').hasTagName('section').hasAttribute('role', 'listitem');
    assert.dom('[data-group]').hasAttribute('role', 'list');
    assert.strictEqual(style(this.element, '[data-p]').marginTop, '0px', 'p items reset margins');
    assert.strictEqual(style(this.element, '[data-section]').boxSizing, 'border-box');
    await click('[data-button]');
    assert.strictEqual(clicks, 1, 'events bubble through items');
    assert.dom('[data-section] button').hasText('Inside', 'block content rendered');
  });
});
