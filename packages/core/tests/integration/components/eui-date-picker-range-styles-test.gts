import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, settled, triggerEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDatePicker from '#src/components/eui-date-picker.gts';
import EuiDatePickerRange from '#src/components/eui-date-picker-range.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
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

/** Past the days' background transition. */
const transitioned = () => new Promise((resolve) => setTimeout(resolve, 400));

class Flags {
  @tracked compressed = false;
}

const cell = (root: ParentNode, date: string) =>
  el(`td[data-date="${date}"]`, root);

module(
  'Integration | Component | eui-date-picker-range | styles',
  function (hooks) {
    setupRenderingTest(hooks);

    for (const mode of ['light', 'dark'] as Mode[]) {
      const context = resolveBorealisTheme(mode);
      const theme = context.euiTheme;
      const fill = euiButtonFillColor(context, 'primary') as Colors;
      const danger = euiButtonColor(context, 'danger') as Colors;

      test(`${mode}: the other end of the range is outlined and bold; the selected end keeps its fill`, async function (assert) {
        await render(
          <template>
            <EuiEmotionProvider @colorMode={{mode}}>
              <EuiDatePicker
                @inline={{true}}
                @value="2026-11-10"
                @selectsStart={{true}}
                @startDate="2026-11-10"
                @endDate="2026-11-14"
                @locale="en-US"
              />
            </EuiEmotionProvider>
          </template>
        );
        await transitioned();
        const end = getComputedStyle(cell(document, '2026-11-14'));
        assert.strictEqual(end.outlineStyle, 'solid', 'outlined');
        assert.strictEqual(end.outlineColor, rgb(theme.colors.primary));
        assert.strictEqual(end.fontWeight, String(theme.font.weight.bold));
        const start = getComputedStyle(cell(document, '2026-11-10'));
        assert.strictEqual(
          start.outlineStyle,
          'none',
          'the selected start is filled, not outlined'
        );
        assert.strictEqual(start.backgroundColor, rgb(fill.backgroundColor));
        const between = getComputedStyle(cell(document, '2026-11-12'));
        assert.strictEqual(between.outlineStyle, 'none');
        assert.notStrictEqual(
          between.backgroundColor,
          'rgba(0, 0, 0, 0)',
          'the days between are tinted'
        );
      });

      test(`${mode}: the preview of a pick is filled, also on the days it adds; never the danger colour`, async function (assert) {
        await render(
          <template>
            <EuiEmotionProvider @colorMode={{mode}}>
              <EuiDatePicker
                @inline={{true}}
                @value="2026-11-14"
                @selectsEnd={{true}}
                @startDate="2026-11-10"
                @endDate="2026-11-14"
                @locale="en-US"
              />
            </EuiEmotionProvider>
          </template>
        );
        await triggerEvent(cell(document, '2026-11-18'), 'mouseenter');
        await transitioned();
        for (const date of ['2026-11-11', '2026-11-16', '2026-11-18']) {
          const style = getComputedStyle(cell(document, date));
          assert.strictEqual(
            style.backgroundColor,
            rgb(fill.backgroundColor),
            `${date} filled`
          );
          assert.notStrictEqual(
            style.backgroundColor,
            rgb(danger.backgroundColor)
          );
        }
        assert.strictEqual(
          getComputedStyle(cell(document, '2026-11-19')).backgroundColor,
          'rgba(0, 0, 0, 0)',
          'after the hovered day: nothing'
        );
      });

      test(`${mode}: in an inline range the month and year selects look as in a lone inline picker`, async function (assert) {
        await render(
          <template>
            <EuiEmotionProvider @colorMode={{mode}}>
              <div data-p="lone"><EuiDatePicker
                  @inline={{true}}
                  @value="2026-11-10"
                /></div>
              <div data-p="range"><EuiDatePickerRange @inline={{true}}>
                  <:start as |className|><EuiDatePicker
                      class={{className}}
                      @value="2026-11-10"
                    /></:start>
                  <:end as |className|><EuiDatePicker
                      class={{className}}
                      @value="2026-11-14"
                    /></:end>
                </EuiDatePickerRange></div>
            </EuiEmotionProvider>
          </template>
        );
        const look = (root: string) => {
          const select = el<HTMLSelectElement>(
            `${root} .react-datepicker__header select`
          );
          const wrapper = select.closest(
            '.euiFormControlLayout__childrenWrapper'
          )!;
          return {
            width: select.getBoundingClientRect().width,
            textAlign: getComputedStyle(select).textAlign,
            display: getComputedStyle(wrapper).display
          };
        };
        assert.deepEqual(look('[data-p="range"]'), look('[data-p="lone"]'));
      });

      test(`${mode}: an input in a compressed range keeps no frame of its own (the field's later class does not win)`, async function (assert) {
        const flags = new Flags();
        await render(
          <template>
            <EuiEmotionProvider @colorMode={{mode}}>
              <EuiDatePickerRange @compressed={{flags.compressed}}>
                <:start as |className|><EuiDatePicker
                    class={{className}}
                    aria-label="Start date"
                    @value="2026-11-10"
                  /></:start>
                <:end as |className|><EuiDatePicker
                    class={{className}}
                    aria-label="End date"
                    @value="2026-11-14"
                    @native={{true}}
                  /></:end>
              </EuiDatePickerRange>
            </EuiEmotionProvider>
          </template>
        );
        for (const compressed of [false, true]) {
          flags.compressed = compressed;
          await settled();
          for (const label of ['Start date', 'End date']) {
            const style = getComputedStyle(el(`input[aria-label="${label}"]`));
            assert.strictEqual(
              style.boxShadow,
              'none',
              `${label}, compressed ${compressed}: no shadow`
            );
            assert.strictEqual(
              style.borderTopStyle,
              'none',
              `${label}, compressed ${compressed}: no border`
            );
          }
        }
      });
    }
  }
);
