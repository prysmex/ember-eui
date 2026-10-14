import { tracked } from '@glimmer/tracking';
import { render, settled, clearRender } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import { get } from '@ember/helper';
import EuiText from '#src/components/eui-text.gts';
import EuiTextColor from '#src/components/eui-text-color.gts';
import EuiTextAlign from '#src/components/eui-text-align.gts';
import EuiTitle from '#src/components/eui-title.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiTextColorValue } from '#src/components/eui-text-color.gts';
import type { EuiTextAlignment } from '#src/components/eui-text-align.gts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function style(root: Element, selector: string) {
  const element = root.querySelector(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return getComputedStyle(element);
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function px(value: string) {
  return parseFloat(value);
}

module('Integration | Component | Borealis text family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiText sizes follow the latest scale; default is s and relative tracks its parent', async function (assert) {
    await render(
      <template>
        <EuiText data-default><p>Default</p></EuiText>
        <EuiText @size="xs" data-size="xs"><p>xs</p></EuiText>
        <EuiText @size="s" data-size="s"><p>s</p></EuiText>
        <EuiText @size="m" data-size="m"><p>m</p></EuiText>
        <div style="font-size: 10px"><EuiText
            @size="relative"
            data-relative-small
          ><p>r</p></EuiText></div>
        <div style="font-size: 20px"><EuiText
            @size="relative"
            data-relative-large
          ><p>r</p></EuiText></div>
      </template>
    );
    const xs = style(this.element, '[data-size="xs"]');
    const s = style(this.element, '[data-size="s"]');
    const m = style(this.element, '[data-size="m"]');
    const fallback = style(this.element, '[data-default]');
    assert.strictEqual(fallback.fontSize, s.fontSize, 'default size is s');
    assert.strictEqual(fallback.lineHeight, s.lineHeight);
    assert.true(px(xs.fontSize) < px(s.fontSize), 'xs < s');
    assert.true(px(s.fontSize) < px(m.fontSize), 's < m');
    assert.strictEqual(s.fontWeight, String(light.font.weight.regular));
    assert.true(
      s.fontFamily.includes('Inter'),
      'scoped reset supplies the Borealis family without a global reset'
    );
    const small = style(this.element, '[data-relative-small]');
    const large = style(this.element, '[data-relative-large]');
    assert.strictEqual(
      px(large.fontSize) / px(small.fontSize),
      2,
      'relative size is em based'
    );
  });

  test('EuiText styles plain HTML content natively, with scoped resets', async function (assert) {
    await render(
      <template>
        <div style="color: rgb(1, 2, 3)">
          <EuiText @size="m" data-text>
            <h1>H1</h1>
            <h2>H2</h2>
            <h3>H3</h3>
            <h4>H4</h4>
            <h5>H5</h5>
            <h6>H6</h6>
            <p data-p>Paragraph with <a href="#x">a link</a>,
              <a href="#y" class="custom">classed link</a>,
              <strong>bold</strong>,
              <code>code</code>
              and
              <kbd>K</kbd></p>
            <ul data-ul><li>One<ol data-nested-ol><li>a</li></ol></li></ul>
            <ol data-ol><li>First</li></ol>
            <blockquote data-quote>Quote</blockquote>
            <pre data-pre>pre</pre>
            <p data-last>Last</p>
          </EuiText>
        </div>
        <EuiText @grow={{false}} style="width: 2000px" data-constrained>
          <p>Constrained</p>
        </EuiText>
      </template>
    );
    const root = style(this.element, '[data-text]');
    assert.strictEqual(root.color, 'rgb(1, 2, 3)', 'root inherits color');

    const headingSizes = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].map((tag) => {
      const heading = style(this.element, `[data-text] ${tag}`);
      assert.strictEqual(
        heading.fontWeight,
        String(light.font.weight.bold),
        `${tag} title weight`
      );
      assert.strictEqual(heading.color, 'rgb(1, 2, 3)', `${tag} inherits`);
      return px(heading.fontSize);
    });
    headingSizes.slice(1).forEach((size, index) => {
      assert.true(
        size < headingSizes[index]!,
        `h${index + 2} is smaller than h${index + 1}`
      );
    });
    assert.strictEqual(
      style(this.element, '[data-text] h1').marginTop,
      '0px',
      'reset removes browser heading margins'
    );

    const paragraph = style(this.element, '[data-p]');
    assert.strictEqual(paragraph.marginTop, '0px');
    assert.strictEqual(
      paragraph.marginBottom,
      root.lineHeight,
      'paragraph spacing equals line height'
    );
    assert.strictEqual(
      style(this.element, '[data-last]').marginBottom,
      '0px',
      'last child has no trailing margin'
    );
    const link = style(this.element, '[data-p] a[href="#x"]');
    assert.strictEqual(
      link.color,
      rgb(light.colors.textParagraph),
      'Borealis prose links use paragraph color'
    );
    assert.strictEqual(link.textDecorationStyle, 'dotted');
    assert.strictEqual(link.fontWeight, String(light.font.weight.medium));
    assert.notStrictEqual(
      style(this.element, '[data-p] a.custom').textDecorationStyle,
      'dotted',
      'prose link styles skip classed links, as upstream'
    );
    assert.strictEqual(
      style(this.element, '[data-p] strong').fontWeight,
      String(light.font.weight.bold)
    );
    assert.true(
      style(this.element, '[data-p] code').fontFamily.includes('Roboto Mono')
    );
    const kbdStyle = style(this.element, '[data-p] kbd');
    assert.strictEqual(kbdStyle.borderTopStyle, 'solid');
    assert.strictEqual(kbdStyle.borderTopColor, rgb(light.colors.textParagraph));

    assert.strictEqual(style(this.element, '[data-ul]').listStyleType, 'disc');
    assert.strictEqual(style(this.element, '[data-ol]').listStyleType, 'decimal');
    assert.strictEqual(
      style(this.element, '[data-nested-ol]').listStyleType,
      'lower-roman'
    );
    assert.strictEqual(
      style(this.element, '[data-ul]').paddingInlineStart,
      '0px',
      'browser list padding is reset'
    );
    assert.strictEqual(
      style(this.element, '[data-ul]').marginLeft,
      root.lineHeight,
      'lists indent by the line height'
    );

    const quote = style(this.element, '[data-quote]');
    assert.strictEqual(quote.color, rgb(light.colors.textSubdued));
    assert.strictEqual(quote.borderInlineStartStyle, 'solid');
    assert.strictEqual(quote.marginInlineStart, '0px');

    const preStyle = style(this.element, '[data-pre]');
    assert.strictEqual(preStyle.whiteSpace, 'pre-wrap');
    assert.notStrictEqual(preStyle.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(preStyle.borderTopStyle, 'none', 'no border outside contrast');

    const constrained = this.element.querySelector<HTMLElement>(
      '[data-constrained]'
    )!;
    assert.true(
      constrained.getBoundingClientRect().width < 2000,
      'grow=false caps the readable width'
    );
    assert.notStrictEqual(getComputedStyle(constrained).maxWidth, 'none');
  });

  test('EuiText composes color and alignment on a single element, as upstream does', async function (assert) {
    await render(
      <template>
        <div dir="ltr">
          <EuiText
            @color="danger"
            @textAlign="center"
            id="summary"
            data-both
            style="padding: 3px"
          >Alert</EuiText>
          <EuiText @color="#663399" data-custom>Custom</EuiText>
          <EuiText data-plain>Plain</EuiText>
        </div>
      </template>
    );
    const both = this.element.querySelector<HTMLElement>('[data-both]')!;
    assert.strictEqual(both.tagName, 'DIV');
    assert.strictEqual(both.children.length, 0, 'no nested wrappers');
    assert.strictEqual(both.textContent?.trim(), 'Alert');
    assert.dom(both).hasClass('euiText').hasAttribute('id', 'summary');
    assert.strictEqual(
      getComputedStyle(both).color,
      rgb(light.colors.textDanger),
      'color overrides the inherited text color'
    );
    assert.strictEqual(getComputedStyle(both).textAlign, 'center');
    assert.strictEqual(
      getComputedStyle(both).paddingTop,
      '3px',
      'caller style attribute is untouched'
    );
    assert.strictEqual(
      style(this.element, '[data-custom]').color,
      'rgb(102, 51, 153)'
    );
    assert
      .dom('[data-custom]')
      .hasAttribute('style', /color: rgb\(102, 51, 153\)/, 'custom color is inline, as upstream');
    assert.dom('[data-plain]').hasClass('euiText');
    assert
      .dom('.euiText--small, .euiTextColor--danger, .euiTextAlign--center')
      .doesNotExist('no legacy modifier classes');
  });

  test('EuiTextColor renders every latest named color, tags and custom colors', async function (assert) {
    const named = [
      ['default', 'textParagraph'],
      ['subdued', 'textSubdued'],
      ['success', 'textSuccess'],
      ['accent', 'textAccent'],
      ['accentSecondary', 'textAccentSecondary'],
      ['danger', 'textDanger'],
      ['warning', 'textWarning'],
      ['ghost', 'textGhost'],
      ['primary', 'textPrimary']
    ] as const;
    await render(
      <template>
        {{#each named as |pair|}}
          <EuiTextColor
            @color={{get pair 0}}
            data-color={{get pair 0}}
          >{{get pair 0}}</EuiTextColor>
        {{/each}}
        <EuiTextColor data-implicit>implicit</EuiTextColor>
        <div style="color: rgb(9, 8, 7)"><EuiTextColor
            @color="inherit"
            data-inherit
          >inherit</EuiTextColor></div>
        <EuiTextColor @color="rgb(10, 20, 30)" data-rgb>rgb</EuiTextColor>
        <EuiTextColor @tagName="div" data-div>div</EuiTextColor>
        <EuiTextColor @tagName="p" data-p>p</EuiTextColor>
        <EuiTextColor
          @color="ghost"
          style="color: red"
          data-ghost-important
        >ghost</EuiTextColor>
        <EuiTextColor
          @color="subdued"
          aria-label="Muted note"
          title="note"
          data-attrs
        >attrs</EuiTextColor>
      </template>
    );
    for (const [name, token] of named) {
      assert.strictEqual(
        style(this.element, `[data-color="${name}"]`).color,
        rgb(light.colors[token]),
        `${name} uses ${token}`
      );
    }
    assert.strictEqual(
      style(this.element, '[data-implicit]').color,
      rgb(light.colors.textParagraph),
      'defaults to default'
    );
    assert.strictEqual(style(this.element, '[data-inherit]').color, 'rgb(9, 8, 7)');
    assert.strictEqual(style(this.element, '[data-rgb]').color, 'rgb(10, 20, 30)');
    assert.dom('[data-implicit]').hasTagName('span');
    assert.dom('[data-div]').hasTagName('div');
    assert.dom('[data-p]').hasTagName('p');
    assert.strictEqual(style(this.element, '[data-p]').marginTop, '0px');
    assert.strictEqual(style(this.element, '[data-p]').marginBottom, '0px');
    assert.strictEqual(
      style(this.element, '[data-ghost-important]').color,
      rgb(light.colors.textGhost),
      'ghost keeps upstream !important precedence'
    );
    assert
      .dom('[data-attrs]')
      .hasAttribute('aria-label', 'Muted note')
      .hasAttribute('title', 'note')
      .hasClass('euiTextColor');
  });

  test('EuiTextAlign aligns logically and flips in RTL', async function (assert) {
    const alignments = ['left', 'center', 'right'] as const;
    await render(
      <template>
        {{#each alignments as |align|}}
          <div dir="ltr" style="width: 300px"><EuiTextAlign
              @textAlign={{align}}
              data-ltr={{align}}
            ><span>x</span></EuiTextAlign></div>
          <div dir="rtl" style="width: 300px"><EuiTextAlign
              @textAlign={{align}}
              data-rtl={{align}}
            ><span>x</span></EuiTextAlign></div>
        {{/each}}
        <EuiTextAlign data-default>d</EuiTextAlign>
        <EuiTextAlign @tagName="span" data-span>s</EuiTextAlign>
        <EuiTextAlign @tagName="p" data-p role="note">p</EuiTextAlign>
      </template>
    );
    const offset = (selector: string) => {
      const box = this.element.querySelector(selector)!;
      const inner = box.querySelector('span')!.getBoundingClientRect();
      const outer = box.getBoundingClientRect();
      return {
        start: Math.round(inner.left - outer.left),
        end: Math.round(outer.right - inner.right)
      };
    };
    assert.strictEqual(offset('[data-ltr="left"]').start, 0, 'ltr left');
    assert.strictEqual(offset('[data-ltr="right"]').end, 0, 'ltr right');
    assert.strictEqual(offset('[data-rtl="left"]').end, 0, 'rtl left = start');
    assert.strictEqual(offset('[data-rtl="right"]').start, 0, 'rtl right = end');
    const center = offset('[data-ltr="center"]');
    assert.true(Math.abs(center.start - center.end) <= 1, 'centered');
    assert.strictEqual(style(this.element, '[data-default]').textAlign, 'start');
    assert.dom('[data-default]').hasTagName('div').hasClass('euiTextAlign');
    assert.dom('[data-span]').hasTagName('span');
    assert.dom('[data-p]').hasTagName('p').hasAttribute('role', 'note');
    assert.strictEqual(style(this.element, '[data-p]').marginBottom, '0px');
  });

  test('EuiTitle sizes, tags, transform, spacing and native semantics', async function (assert) {
    const sizes = ['l', 'm', 's', 'xs', 'xxs', 'xxxs'] as const;
    await render(
      <template>
        {{#each sizes as |size|}}
          <EuiTitle @size={{size}} data-title={{size}}>{{size}}</EuiTitle>
        {{/each}}
        <section aria-labelledby="settings-title">
          <EuiTitle
            @tagName="h3"
            @size="s"
            @textTransform="uppercase"
            id="settings-title"
            data-h3
          >Settings</EuiTitle>
        </section>
        <EuiTitle @tagName="p" data-ptag>Paragraph</EuiTitle>
        <fieldset><EuiTitle @tagName="legend" data-legend>Legend</EuiTitle></fieldset>
        <div data-adjacent>
          <EuiTitle @size="xs" data-first>First</EuiTitle>
          <EuiTitle @size="xs" data-second>Second</EuiTitle>
        </div>
      </template>
    );
    const fontSizes = sizes.map((size) => {
      const title = style(this.element, `[data-title="${size}"]`);
      assert.strictEqual(title.fontWeight, String(light.font.weight.bold));
      assert.strictEqual(title.color, rgb(light.colors.textHeading));
      assert.strictEqual(title.letterSpacing, '-0.2px');
      assert.strictEqual(title.marginTop, '0px', `${size} reset margin`);
      assert.true(title.fontFamily.includes('Inter'), `${size} family`);
      return px(title.fontSize);
    });
    fontSizes.slice(1).forEach((size, index) => {
      assert.true(size < fontSizes[index]!, `${sizes[index + 1]} is smaller`);
    });
    assert.dom('[data-title="m"]').hasTagName('h2', 'defaults to h2');
    assert.dom('[data-h3]').hasTagName('h3').hasClass('euiTitle');
    assert.strictEqual(style(this.element, '[data-h3]').textTransform, 'uppercase');
    assert.strictEqual(
      document
        .querySelector('section')!
        .getAttribute('aria-labelledby'),
      this.element.querySelector('[data-h3]')!.id,
      'id forwards for labelling'
    );
    assert.dom('[data-ptag]').hasTagName('p');
    assert.strictEqual(style(this.element, '[data-ptag]').marginBottom, '0px');
    assert.dom('[data-legend]').hasTagName('legend');
    assert.strictEqual(style(this.element, '[data-legend]').paddingLeft, '0px');
    assert.strictEqual(
      style(this.element, '[data-second]').marginBlockStart,
      light.size.l,
      'adjacent titles are spaced by size.l'
    );
    assert.strictEqual(style(this.element, '[data-first]').marginBlockStart, '0px');
    assert
      .dom('.euiTitle--medium, .euiTitle--uppercase')
      .doesNotExist('no legacy modifier classes');
  });

  test('arguments update reactively without replacing elements', async function (assert) {
    class State {
      @tracked size: 'xs' | 'm' = 'xs';
      @tracked color: EuiTextColorValue = 'subdued';
      @tracked align: EuiTextAlignment = 'left';
      @tracked titleSize: 'xxs' | 'l' = 'xxs';
      @tracked transform: 'uppercase' | undefined = undefined;
      @tracked grow = true;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 2000px">
          <EuiText
            @size={{state.size}}
            @color={{state.color}}
            @textAlign={{state.align}}
            @grow={{state.grow}}
            data-text
          >Body</EuiText>
          <EuiTextColor @color={{state.color}} data-color>c</EuiTextColor>
          <EuiTextAlign @textAlign={{state.align}} data-align>a</EuiTextAlign>
          <EuiTitle
            @size={{state.titleSize}}
            @textTransform={{state.transform}}
            data-title
          >T</EuiTitle>
        </div>
      </template>
    );
    const nodes = ['text', 'color', 'align', 'title'].map(
      (name) => this.element.querySelector(`[data-${name}]`)!
    );
    const before = {
      size: px(style(this.element, '[data-text]').fontSize),
      title: px(style(this.element, '[data-title]').fontSize),
      width: this.element.querySelector('[data-text]')!.getBoundingClientRect()
        .width
    };
    assert.strictEqual(
      style(this.element, '[data-text]').color,
      rgb(light.colors.textSubdued)
    );

    state.size = 'm';
    state.color = 'success';
    state.align = 'right';
    state.titleSize = 'l';
    state.transform = 'uppercase';
    state.grow = false;
    await settled();

    nodes.forEach((node, index) =>
      assert.strictEqual(
        this.element.querySelector(
          `[data-${['text', 'color', 'align', 'title'][index]}]`
        ),
        node,
        'element preserved'
      )
    );
    assert.true(px(style(this.element, '[data-text]').fontSize) > before.size);
    assert.true(px(style(this.element, '[data-title]').fontSize) > before.title);
    assert.true(
      this.element.querySelector('[data-text]')!.getBoundingClientRect().width <
        before.width,
      'grow=false constrains width'
    );
    for (const name of ['text', 'color']) {
      assert.strictEqual(
        style(this.element, `[data-${name}]`).color,
        rgb(light.colors.textSuccess),
        `${name} color`
      );
    }
    assert.strictEqual(style(this.element, '[data-text]').textAlign, 'end');
    assert.strictEqual(style(this.element, '[data-align]').textAlign, 'end');
    assert.strictEqual(style(this.element, '[data-title]').textTransform, 'uppercase');

    state.color = '#00ff00';
    state.transform = undefined;
    await settled();
    assert.strictEqual(style(this.element, '[data-color]').color, 'rgb(0, 255, 0)');
    assert.strictEqual(style(this.element, '[data-title]').textTransform, 'none');
  });

  test('light/dark modes follow the nearest provider; siblings stay isolated', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiTitle data-parent-title>Parent</EuiTitle>
          <EuiTextColor @color="subdued" data-parent-color>c</EuiTextColor>
          <EuiText data-parent-text><a href="#l">link</a>
            <blockquote>q</blockquote></EuiText>
          <EuiEmotionProvider>
            <EuiTitle data-nested-title>Nested inherits</EuiTitle>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiTitle data-fixed-light>Fixed light</EuiTitle>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiTitle data-sibling-title>Sibling</EuiTitle>
          <EuiTextColor @color="subdued" data-sibling-color>c</EuiTextColor>
        </EuiEmotionProvider>
      </template>
    );
    const titleNode = this.element.querySelector('[data-parent-title]');
    assert.strictEqual(
      style(this.element, '[data-parent-title]').color,
      rgb(light.colors.textHeading)
    );

    state.mode = 'dark';
    await settled();

    assert.strictEqual(
      this.element.querySelector('[data-parent-title]'),
      titleNode,
      'mode change keeps the element'
    );
    assert.strictEqual(
      style(this.element, '[data-parent-title]').color,
      rgb(dark.colors.textHeading)
    );
    assert.strictEqual(
      style(this.element, '[data-parent-color]').color,
      rgb(dark.colors.textSubdued)
    );
    assert.strictEqual(
      style(this.element, '[data-parent-text] a').color,
      rgb(dark.colors.textParagraph)
    );
    assert.strictEqual(
      style(this.element, '[data-parent-text] blockquote').color,
      rgb(dark.colors.textSubdued)
    );
    assert.strictEqual(
      style(this.element, '[data-nested-title]').color,
      rgb(dark.colors.textHeading),
      'nested provider inherits dark'
    );
    assert.strictEqual(
      style(this.element, '[data-fixed-light]').color,
      rgb(light.colors.textHeading),
      'fixed light child is isolated'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling-title]').color,
      rgb(light.colors.textHeading),
      'outer sibling is isolated'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling-color]').color,
      rgb(light.colors.textSubdued)
    );
  });

  test('native token overrides and contrast modes reach the text factories', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const nestedOverrides: EuiBorealisOverrides = {
      colors: { LIGHT: { textHeading: '#00aa00' } }
    };
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <EuiTitle data-title>Title</EuiTitle>
          <EuiTextColor @color="danger" data-color>c</EuiTextColor>
          <EuiText data-text><pre>code</pre></EuiText>
          <EuiEmotionProvider @borealisOverrides={{nestedOverrides}}>
            <EuiTitle data-nested>Nested override</EuiTitle>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiTitle data-outside>Outside</EuiTitle>
      </template>
    );
    assert.strictEqual(
      style(this.element, '[data-text] pre').borderTopStyle,
      'none'
    );

    state.overrides = {
      colors: { LIGHT: { textHeading: '#123456', textDanger: '#654321' } }
    };
    state.contrast = 'preferred';
    await settled();

    assert.strictEqual(style(this.element, '[data-title]').color, 'rgb(18, 52, 86)');
    assert.strictEqual(style(this.element, '[data-color]').color, 'rgb(101, 67, 33)');
    assert.strictEqual(
      style(this.element, '[data-nested]').color,
      'rgb(0, 170, 0)',
      'nearest override wins'
    );
    assert.strictEqual(
      style(this.element, '[data-outside]').color,
      rgb(light.colors.textHeading),
      'overrides stay scoped'
    );
    assert.strictEqual(
      style(this.element, '[data-text] pre').borderTopStyle,
      'solid',
      'preferred contrast borders code blocks'
    );

    await clearRender();
    assert.dom('.euiTitle, .euiText, .euiTextColor').doesNotExist('teardown');
  });

  test('provider wrapper gives inherited text its own mode color; opt-out renders no element', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    await render(
      <template>
        <div style="color: rgb(1, 2, 3)">
          <EuiEmotionProvider @colorMode={{state.mode}} data-wrapper>
            <EuiText data-dark-text><p>Body</p><h3>Heading</h3></EuiText>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="dark" @wrapper={{false}}>
            <EuiText data-unwrapped>Inherits page</EuiText>
          </EuiEmotionProvider>
        </div>
      </template>
    );
    assert.dom('[data-wrapper]').hasTagName('span').hasClass('euiThemeProvider');
    assert.strictEqual(
      style(this.element, '[data-dark-text]').color,
      rgb(dark.colors.textParagraph),
      'EuiText inherits the dark paragraph color'
    );
    assert.strictEqual(
      style(this.element, '[data-dark-text] h3').color,
      rgb(dark.colors.textParagraph),
      'prose headings inherit too, as upstream'
    );
    assert.strictEqual(
      style(this.element, '[data-unwrapped]').color,
      'rgb(1, 2, 3)',
      'wrapper=false leaves inheritance to the page'
    );
    assert.strictEqual(
      this.element.querySelector('[data-unwrapped]')!.parentElement!.tagName,
      'DIV',
      'no wrapper element when opted out'
    );
    const wrapper = this.element.querySelector('[data-wrapper]');
    state.mode = 'light';
    await settled();
    assert.strictEqual(
      this.element.querySelector('[data-wrapper]'),
      wrapper,
      'mode change keeps the wrapper'
    );
    assert.strictEqual(
      style(this.element, '[data-dark-text]').color,
      rgb(light.colors.textParagraph)
    );
  });
});
