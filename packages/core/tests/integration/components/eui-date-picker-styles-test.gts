import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import moment from 'moment';
import { focus, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import DatetimePicker from '#src/components/eui-super-date-picker/date-popover/datetime-picker.gts';
import {
  euiButtonColor,
  euiButtonFillColor
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

type Mode = 'light' | 'dark';
type Colors = { color: string; backgroundColor: string };

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** Any CSS color as the browser's computed `rgb()`. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function channels(color: string): [number, number, number] {
  const [r, g, b] = rgb(color)
    .match(/[\d.]+/g)!
    .map(Number) as [number, number, number];
  return [r, g, b];
}

/** WCAG contrast ratio of two opaque colours. */
function contrast(a: string, b: string) {
  const luminance = (color: string) => {
    const [r, g, b] = channels(color).map((c) => {
      const s = c / 255;
      return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    }) as [number, number, number];
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  const [x, y] = [luminance(a), luminance(b)].sort((m, n) => n - m) as [
    number,
    number
  ];
  return (x + 0.05) / (y + 0.05);
}

/** Measured size in CSS pixels; the ember-qunit container is scaled. */
function size(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round(rect.width / scale),
    height: Math.round(rect.height / scale)
  };
}

/** The declarations of the first stylesheet rule whose selector contains all the parts. */
function ruleStyle(...parts: string[]): CSSStyleDeclaration | undefined {
  const visit = (rules: CSSRuleList): CSSStyleDeclaration | undefined => {
    for (const rule of rules) {
      if (
        rule instanceof CSSStyleRule &&
        parts.every((p) => rule.selectorText.includes(p))
      ) {
        return rule.style;
      }
      if ('cssRules' in rule) {
        const found = visit((rule as CSSGroupingRule).cssRules);
        if (found) return found;
      }
    }
    return undefined;
  };
  for (const sheet of document.styleSheets) {
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      continue;
    }
    const found = visit(rules);
    if (found) return found;
  }
  return undefined;
}

/** The generated (Emotion) classes of an element: not upstream's nor ours. */
const classesOf = (element: Element) =>
  [...element.classList].filter(
    (c) => !c.startsWith('react-datepicker') && !c.startsWith('euiDatePicker')
  );

const minDate = '2026-11-05';
const noop = () => {};

module('Integration | Component | eui-date-picker | styles', function (hooks) {
  setupRenderingTest(hooks);

  for (const mode of ['light', 'dark'] as Mode[]) {
    const context = resolveBorealisTheme(mode);
    const theme = context.euiTheme;
    const fill = euiButtonFillColor(context, 'primary') as Colors;
    const disabled = euiButtonColor(context, 'disabled') as Colors;
    const hover = euiButtonColor(context, 'primary') as Colors;

    test(`${mode}: day size, selected, today, disabled, outside days and the grid layout`, async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{mode}}>
            <EuiDatePicker
              @inline={{true}}
              @value="2026-11-24"
              @minDate={{minDate}}
              @locale="en-US"
              @firstDayOfWeek={{0}}
            />
          </EuiEmotionProvider>
        </template>
      );
      const panel = getComputedStyle(
        el('.euiFormControlLayout')
      ).backgroundColor;
      assert.strictEqual(
        panel,
        rgb(theme.colors.emptyShade),
        'the inline frame is the panel colour'
      );

      assert.strictEqual(
        getComputedStyle(el('.react-datepicker__week')).display,
        'flex',
        'rows lay out as upstream'
      );
      assert.strictEqual(
        getComputedStyle(el('.react-datepicker__day-names')).display,
        'flex'
      );
      assert.deepEqual(size(el('.react-datepicker__day-name')), {
        width: 32,
        height: 32
      });

      const plain = el('td[data-date="2026-11-10"]');
      assert.deepEqual(size(plain), { width: 32, height: 32 });
      assert.strictEqual(getComputedStyle(plain).borderRadius, '8px');
      assert.strictEqual(
        getComputedStyle(plain).color,
        rgb(theme.colors.textHeading)
      );
      const button = el('td[data-date="2026-11-10"] > button');
      assert.deepEqual(
        size(button),
        { width: 32, height: 32 },
        'the button fills the day'
      );
      assert.strictEqual(
        getComputedStyle(button).backgroundColor,
        'rgba(0, 0, 0, 0)',
        'and takes its look from it'
      );
      assert.strictEqual(
        getComputedStyle(button).color,
        rgb(theme.colors.textHeading)
      );

      const selected = getComputedStyle(el('.react-datepicker__day--selected'));
      assert.strictEqual(
        selected.backgroundColor,
        rgb(fill.backgroundColor),
        'selected: filled primary'
      );
      assert.strictEqual(selected.color, rgb(fill.color));
      assert.true(
        contrast(selected.color, selected.backgroundColor) >= 4.5,
        'selected text is readable'
      );
      assert.true(
        contrast(selected.backgroundColor, panel) >= 3,
        'the selected day stands out from the panel'
      );

      const off = getComputedStyle(el('td[data-date="2026-11-04"]'));
      assert.strictEqual(
        off.backgroundColor,
        rgb(disabled.backgroundColor),
        'disabled: the disabled button colours'
      );
      assert.strictEqual(off.color, rgb(disabled.color));
      assert.strictEqual(off.cursor, 'not-allowed');
      assert.notStrictEqual(
        off.backgroundColor,
        panel,
        'a disabled day is boxed, unlike an enabled one'
      );

      const outside = getComputedStyle(el('td[data-date="2026-12-01"]'));
      assert.strictEqual(outside.color, rgb(theme.colors.textSubdued));
    });

    test(`${mode}: today has a dot as well as its colour, also when selected`, async function (assert) {
      const today = new Date();
      const iso = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{mode}}>
            <div data-p="plain"><EuiDatePicker
                @inline={{true}}
                @locale="en-US"
                @firstDayOfWeek={{0}}
              /></div>
            <div data-p="selected"><EuiDatePicker
                @inline={{true}}
                @value={{iso}}
                @locale="en-US"
                @firstDayOfWeek={{0}}
              /></div>
          </EuiEmotionProvider>
        </template>
      );
      const panel = getComputedStyle(
        el('.euiFormControlLayout')
      ).backgroundColor;
      const todayCell = el('[data-p="plain"] .react-datepicker__day--today');
      const style = getComputedStyle(todayCell);
      assert.strictEqual(
        style.color,
        rgb(theme.colors.primary),
        'primary text'
      );
      assert.strictEqual(style.fontWeight, String(theme.font.weight.bold));
      assert.true(
        contrast(style.color, panel) >= 3,
        `today is visible on the panel (${contrast(style.color, panel).toFixed(2)})`
      );
      const dot = getComputedStyle(todayCell, '::after');
      assert.strictEqual(dot.content, '""');
      assert.strictEqual(dot.width, '4px');
      assert.strictEqual(dot.height, '4px');
      assert.strictEqual(
        dot.backgroundColor,
        style.color,
        'the dot has the text colour'
      );

      const both = el('[data-p="selected"] .react-datepicker__day--today');
      assert.dom(both).hasClass('react-datepicker__day--selected');
      assert.strictEqual(
        getComputedStyle(both, '::after').backgroundColor,
        rgb(fill.color),
        'on the fill, the dot is the fill text colour'
      );
    });

    test(`${mode}: the focused day has EUI's focus ring, outset, visible on the selected day`, async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{mode}}>
            <EuiDatePicker
              @inline={{true}}
              @value="2026-11-24"
              @locale="en-US"
              @firstDayOfWeek={{0}}
            />
          </EuiEmotionProvider>
        </template>
      );
      const panel = getComputedStyle(
        el('.euiFormControlLayout')
      ).backgroundColor;
      const selected = el<HTMLButtonElement>(
        'td[data-date="2026-11-24"] > button'
      );
      await focus(selected);
      await triggerKeyEvent(selected, 'keydown', 'ArrowRight');
      await triggerKeyEvent(document.activeElement!, 'keydown', 'ArrowLeft');
      assert.strictEqual(
        document.activeElement,
        selected,
        'back on the selected day, by keyboard'
      );
      const ring = getComputedStyle(selected);
      assert.notStrictEqual(
        ring.outlineStyle,
        'none',
        `a ring (${ring.outlineStyle})`
      );
      assert.strictEqual(ring.outlineWidth, '2px');
      assert.strictEqual(
        ring.outlineOffset,
        '2px',
        'outset: drawn on the panel, outside the fill'
      );
      assert.strictEqual(
        ring.outlineColor,
        rgb(theme.focus.color),
        'the theme focus colour'
      );
      assert.true(
        contrast(ring.outlineColor, panel) >= 3,
        `the ring contrasts with the panel (${contrast(ring.outlineColor, panel).toFixed(2)})`
      );
    });

    test(`${mode}: hover is a tinted box; a disabled calendar dims its days, the selected keeps its fill`, async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{mode}}>
            <div data-p="on"><EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
                @locale="en-US"
                @firstDayOfWeek={{0}}
              /></div>
            <div data-p="off"><EuiDatePicker
                @inline={{true}}
                @disabled={{true}}
                @value="2026-11-24"
                @locale="en-US"
                @firstDayOfWeek={{0}}
              /></div>
          </EuiEmotionProvider>
        </template>
      );
      const panel = getComputedStyle(
        el('[data-p="on"] .euiFormControlLayout')
      ).backgroundColor;
      const calendar = el('[data-p="on"] .react-datepicker');
      const rule = classesOf(calendar)
        .map((c) => ruleStyle(`.${c}`, '.react-datepicker__day:hover'))
        .find(Boolean);
      assert.ok(rule, 'a hover rule for the days');
      assert.strictEqual(
        rgb(rule!.backgroundColor),
        rgb(hover.backgroundColor),
        'hover: the primary button tint'
      );
      assert.notStrictEqual(
        rgb(rule!.backgroundColor),
        panel,
        'the tint differs from the panel'
      );
      assert.strictEqual(
        rule!.textDecorationLine || rule!.textDecoration.split(' ')[0],
        'underline'
      );

      const dim = getComputedStyle(
        el('[data-p="off"] td[data-date="2026-11-10"]')
      );
      assert.strictEqual(
        dim.color,
        rgb(theme.colors.textDisabled),
        'disabled calendar: dimmed days'
      );
      const kept = getComputedStyle(
        el('[data-p="off"] td[data-date="2026-11-24"]')
      );
      assert.strictEqual(
        kept.backgroundColor,
        rgb(fill.backgroundColor),
        'the selected day keeps its fill'
      );
      assert.strictEqual(
        getComputedStyle(el('[data-p="off"] .react-datepicker')).pointerEvents,
        'none'
      );
    });
  }

  for (const mode of ['light', 'dark'] as Mode[]) {
    test(`${mode}: the inline frame's states do not reach the month and year selects; a disabled calendar's selected day stays readable`, async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{mode}}>
            <div data-p="shadow"><EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
              /></div>
            <div data-p="invalid"><EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
                @isInvalid={{true}}
              /></div>
            <div data-p="disabled"><EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
                @disabled={{true}}
              /></div>
            <div data-p="readOnly"><EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
                @readOnly={{true}}
              /></div>
          </EuiEmotionProvider>
        </template>
      );
      for (const state of ['shadow', 'invalid', 'disabled', 'readOnly']) {
        const outer = getComputedStyle(
          el(`[data-p="${state}"] .euiDatePicker > .euiFormControlLayout`)
        );
        for (const select of document.querySelectorAll(
          `[data-p="${state}"] .react-datepicker__header .euiFormControlLayout`
        )) {
          const style = getComputedStyle(select);
          assert.strictEqual(
            style.boxShadow,
            'none',
            `${state}: no frame shadow on a select`
          );
          assert.strictEqual(
            style.backgroundColor,
            'rgba(0, 0, 0, 0)',
            `${state}: no frame background`
          );
          assert.strictEqual(
            style.outlineStyle,
            'none',
            `${state}: no invalid outline`
          );
        }
        if (state === 'shadow') {
          assert.notStrictEqual(
            outer.boxShadow,
            'none',
            'the frame itself keeps its shadow'
          );
        }
        if (state === 'invalid') {
          assert.strictEqual(
            outer.outlineStyle,
            'solid',
            'the frame itself keeps the invalid outline'
          );
        }
      }
      const selected = el(
        '[data-p="disabled"] td[data-date="2026-11-24"] > button'
      );
      const style = getComputedStyle(selected);
      assert.strictEqual(
        style.getPropertyValue('-webkit-text-fill-color'),
        style.color,
        'the text is painted in its own colour'
      );
      assert.true(
        contrast(
          style.color,
          getComputedStyle(selected.parentElement!).backgroundColor
        ) >= 4.5,
        'readable on the fill'
      );
    });
  }

  test('read-only keeps normal text contrast', async function (assert) {
    const theme = resolveBorealisTheme('light').euiTheme;
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiDatePicker
            @inline={{true}}
            @readOnly={{true}}
            @value="2026-11-24"
            @onClear={{noop}}
            @locale="en-US"
            @firstDayOfWeek={{0}}
          />
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(
      getComputedStyle(el('td[data-date="2026-11-10"]')).color,
      rgb(theme.colors.textHeading)
    );
  });

  test('weekday headers fit their column in every locale; long short names fall back to narrow', async function (assert) {
    const locales = [
      'en-US',
      'fr',
      'de',
      'es-MX',
      'pt-BR',
      'vi',
      'ar',
      'fa',
      'he',
      'hi',
      'zh'
    ];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          {{#each locales as |locale|}}
            <div data-locale={{locale}}>
              <EuiDatePicker
                @inline={{true}}
                @value="2026-11-24"
                @locale={{locale}}
                @firstDayOfWeek={{0}}
              />
            </div>
          {{/each}}
        </EuiEmotionProvider>
      </template>
    );
    for (const locale of locales) {
      for (const th of document.querySelectorAll<HTMLElement>(
        `[data-locale="${locale}"] .react-datepicker__day-name`
      )) {
        const shown = el('[aria-hidden="true"]', th);
        assert.true(
          shown.offsetWidth <= th.clientWidth,
          `${locale}: "${shown.textContent}" fits`
        );
      }
    }
    assert.strictEqual(
      el('[data-locale="ar"] .react-datepicker__day-name [aria-hidden]')
        .textContent,
      'ح',
      'ar: narrow'
    );
    assert.strictEqual(
      el('[data-locale="ar"] .react-datepicker__day-name').getAttribute('abbr'),
      'الأحد',
      'the long name stays'
    );
    assert.strictEqual(
      el('[data-locale="fr"] .react-datepicker__day-name [aria-hidden]')
        .textContent,
      'dim.',
      'fr: short'
    );
  });

  test('the table lays out as the Absolute tab calendar: same day pitch, headers over their days', async function (assert) {
    const selected = moment('2026-11-24T10:00:00');
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div data-p="old"><DatetimePicker
              @selected={{selected}}
              @onChange={{noop}}
            /></div>
          <div data-p="new"><EuiDatePicker
              @inline={{true}}
              @value="2026-11-24"
              @locale="en-US"
              @firstDayOfWeek={{0}}
            /></div>
        </EuiEmotionProvider>
      </template>
    );
    const geometry = (root: string) => {
      const week = el(`[data-p="${root}"] .react-datepicker__week`);
      const days = [
        ...week.querySelectorAll<HTMLElement>('.react-datepicker__day')
      ];
      const origin = week.getBoundingClientRect().left;
      return {
        offsets: days.map((d) =>
          Math.round(d.getBoundingClientRect().left - origin)
        ),
        sizes: days.map((d) => size(d))
      };
    };
    const old = geometry('old');
    const now = geometry('new');
    assert.deepEqual(now.sizes, old.sizes, 'same day size');
    const pitch = (offsets: number[]) =>
      offsets.slice(1).map((x, i) => x - offsets[i]!);
    assert.deepEqual(
      pitch(now.offsets),
      pitch(old.offsets),
      'same distance between days'
    );

    const headers = [
      ...document.querySelectorAll<HTMLElement>(
        '[data-p="new"] .react-datepicker__day-name'
      )
    ];
    const firstWeek = [
      ...document.querySelectorAll<HTMLElement>(
        '[data-p="new"] .react-datepicker__week:first-child td'
      )
    ];
    const center = (e: HTMLElement) => {
      const r = e.getBoundingClientRect();
      return Math.round(r.left + r.width / 2);
    };
    assert.deepEqual(
      headers.map(center),
      firstWeek.map(center),
      'each header is centred over its day'
    );
  });
});
