import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import Component from '@glimmer/component';
import { render, waitUntil } from '@ember/test-helpers';

import EuiAccordion from '#src/components/eui-accordion.gts';
import EuiAvatar from '#src/components/eui-avatar.gts';
import EuiBadge from '#src/components/eui-badge.gts';
import EuiBeacon from '#src/components/eui-beacon.gts';
import EuiBetaBadge from '#src/components/eui-beta-badge.gts';
import EuiBreadcrumbs from '#src/components/eui-breadcrumbs.gts';
import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';
import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiEmptyPrompt from '#src/components/eui-empty-prompt.gts';
import EuiFieldNumber from '#src/components/eui-field-number.gts';
import EuiFlexGroup from '#src/components/eui-flex-group.gts';
import EuiFlexItem from '#src/components/eui-flex-item.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';
import EuiFormLabel from '#src/components/eui-form-label.gts';
import EuiHorizontalRule from '#src/components/eui-horizontal-rule.gts';
import EuiLink from '#src/components/eui-link.gts';
import EuiLoadingSpinner from '#src/components/eui-loading-spinner.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiNotificationBadge from '#src/components/eui-notification-badge.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiPopoverFooter from '#src/components/eui-popover-footer.gts';
import EuiPopoverTitle from '#src/components/eui-popover-title.gts';
import EuiRadio from '#src/components/eui-radio.gts';
import EuiText from '#src/components/eui-text.gts';
import EuiTitle from '#src/components/eui-title.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import { getEuiThemeContext } from '#src/utils/emotion/consume.ts';
import { euiClass } from '#src/utils/eui/styles.ts';

import type { EuiCss } from '#src/utils/eui/styles.ts';
import type { TOC } from '@ember/component/template-only';

/*
 * `@css` is composed last into the component's own Emotion class (like
 * upstream's `css` prop), so a caller's declarations win over the
 * component's conflicting ones whatever order the rules reach the style
 * sheet in. Each case renders the caller's styles as a standalone rule
 * before the component (caller first) and after it (caller last), with a
 * fresh value each time so the rules are new, and checks the component
 * without `@css` resolves to something else (the declarations conflict).
 */

/** Inserts the caller's styles as a rule of their own, where it renders. */
class CallerRule extends Component<{ Args: { css: EuiCss } }> {
  get className(): string {
    return euiClass(getEuiThemeContext(this), this.args.css);
  }

  <template><i class="callerRule {{this.className}}"></i></template>
}

interface ProbeSignature {
  Args: { css?: EuiCss };
}

type Probe = TOC<ProbeSignature>;

interface Case {
  name: string;
  Probe: Probe;
  /** The element the styles land on. */
  target: () => HTMLElement | null;
  /** Computed style property to compare. */
  property: string;
  /** The caller's styles for render `n` (1: caller first, 2: caller last). */
  css: (n: number) => EuiCss;
  /** The computed value `css(n)` resolves to. */
  expected: (n: number) => string;
}

const noop = () => {};
const BREADCRUMBS = [{ text: 'Home' }, { text: 'Page' }];

const $ = (selector: string) =>
  document.querySelector<HTMLElement>(selector);
const probe = () => $('[data-probe]');
const px = (base: number) => (n: number) => `${base + n}px`;
const rgbColor = (n: number) => `rgb(${n}, 2, 3)`;

/** Components that compose `@css` into their root, styled with one property. */
const CASES: Case[] = [
  {
    name: 'EuiText',
    Probe: <template><EuiText @css={{@css}} data-probe>text</EuiText></template>,
    target: probe,
    property: 'fontSize',
    css: (n) => ({ fontSize: px(30)(n) }),
    expected: px(30)
  },
  {
    name: 'EuiTitle',
    Probe: <template><EuiTitle @css={{@css}} data-probe>title</EuiTitle></template>,
    target: probe,
    property: 'fontSize',
    css: (n) => ({ fontSize: px(40)(n) }),
    expected: px(40)
  },
  {
    name: 'EuiButton',
    Probe: <template><EuiButton @css={{@css}} data-probe>button</EuiButton></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(10)(n) }),
    expected: px(10)
  },
  {
    name: 'EuiButton @contentCss',
    Probe: <template><EuiButton @contentCss={{@css}} data-probe>button</EuiButton></template>,
    target: () => $('[data-probe] .euiButton__content'),
    property: 'justifyContent',
    css: (n) => ({ justifyContent: n === 1 ? 'flex-start' : 'flex-end' }),
    expected: (n) => (n === 1 ? 'flex-start' : 'flex-end')
  },
  {
    name: 'EuiButtonEmpty',
    Probe: <template><EuiButtonEmpty @css={{@css}} data-probe>button</EuiButtonEmpty></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(10)(n) }),
    expected: px(10)
  },
  {
    name: 'EuiButtonEmpty @contentCss',
    Probe: <template><EuiButtonEmpty @contentCss={{@css}} data-probe>button</EuiButtonEmpty></template>,
    target: () => $('[data-probe] .euiButtonEmpty__content'),
    property: 'justifyContent',
    css: (n) => ({ justifyContent: n === 1 ? 'flex-start' : 'flex-end' }),
    expected: (n) => (n === 1 ? 'flex-start' : 'flex-end')
  },
  {
    name: 'EuiBadge',
    Probe: <template><EuiBadge @css={{@css}} data-probe>badge</EuiBadge></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(10)(n) }),
    expected: px(10)
  },
  {
    name: 'EuiBetaBadge',
    Probe: <template><EuiBetaBadge @label="Beta" @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(10)(n) }),
    expected: px(10)
  },
  {
    name: 'EuiNotificationBadge',
    Probe: <template><EuiNotificationBadge @css={{@css}} data-probe>3</EuiNotificationBadge></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(10)(n) }),
    expected: px(10)
  },
  {
    name: 'EuiFlexGroup',
    Probe: <template><EuiFlexGroup @css={{@css}} data-probe><EuiFlexItem>a</EuiFlexItem></EuiFlexGroup></template>,
    target: probe,
    property: 'columnGap',
    css: (n) => ({ gap: px(2)(n) }),
    expected: px(2)
  },
  {
    name: 'EuiFlexItem',
    Probe: <template><EuiFlexGroup><EuiFlexItem @css={{@css}} data-probe>a</EuiFlexItem></EuiFlexGroup></template>,
    target: probe,
    property: 'flexGrow',
    css: (n) => ({ flexGrow: n + 4 }),
    expected: (n) => String(n + 4)
  },
  {
    name: 'EuiFieldNumber',
    Probe: <template><EuiFieldNumber @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'maxWidth',
    css: (n) => ({ maxInlineSize: px(100)(n) }),
    expected: px(100)
  },
  {
    name: 'EuiCheckbox',
    Probe: <template><EuiCheckbox @label="check" @css={{@css}} data-probe /></template>,
    target: () => probe()?.closest<HTMLElement>('.euiCheckbox') ?? null,
    property: 'display',
    css: (n) => ({ display: n === 1 ? 'inline-flex' : 'grid' }),
    expected: (n) => (n === 1 ? 'inline-flex' : 'grid')
  },
  {
    name: 'EuiRadio',
    Probe: <template><EuiRadio @label="radio" @css={{@css}} data-probe /></template>,
    target: () => probe()?.closest<HTMLElement>('.euiRadio') ?? null,
    property: 'display',
    css: (n) => ({ display: n === 1 ? 'inline-flex' : 'grid' }),
    expected: (n) => (n === 1 ? 'inline-flex' : 'grid')
  },
  {
    name: 'EuiAvatar',
    Probe: <template><EuiAvatar @name="Ann" @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'borderTopLeftRadius',
    css: (n) => ({ borderRadius: px(1)(n) }),
    expected: px(1)
  },
  {
    name: 'EuiBeacon',
    Probe: <template><EuiBeacon @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'height',
    css: (n) => ({ blockSize: px(20)(n) }),
    expected: px(20)
  },
  {
    name: 'EuiLoadingSpinner',
    Probe: <template><EuiLoadingSpinner @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'width',
    css: (n) => ({ inlineSize: px(30)(n) }),
    expected: px(30)
  },
  {
    name: 'EuiPopover',
    Probe: <template>
      <EuiPopover @css={{@css}} @closePopover={{noop}} data-probe>
        <:button><button type="button">anchor</button></:button>
        <:content>content</:content>
      </EuiPopover>
    </template>,
    target: probe,
    property: 'display',
    css: (n) => ({ display: n === 1 ? 'flex' : 'grid' }),
    expected: (n) => (n === 1 ? 'flex' : 'grid')
  },
  {
    name: 'EuiPopover @panelCss',
    Probe: <template>
      <EuiPopover @panelCss={{@css}} @isOpen={{true}} @closePopover={{noop}} @ownFocus={{false}}>
        <:button><button type="button">anchor</button></:button>
        <:content>content</:content>
      </EuiPopover>
    </template>,
    target: () => $('[data-popover-panel]'),
    property: 'paddingTop',
    css: (n) => ({ padding: px(20)(n) }),
    expected: px(20)
  },
  {
    name: 'EuiPopoverTitle',
    Probe: <template><EuiPopoverTitle @css={{@css}} data-probe>title</EuiPopoverTitle></template>,
    target: probe,
    property: 'paddingTop',
    css: (n) => ({ padding: px(20)(n) }),
    expected: px(20)
  },
  {
    name: 'EuiPopoverFooter',
    Probe: <template><EuiPopoverFooter @css={{@css}} data-probe>footer</EuiPopoverFooter></template>,
    target: probe,
    property: 'paddingTop',
    css: (n) => ({ padding: px(20)(n) }),
    expected: px(20)
  },
  {
    name: 'EuiFlyout',
    Probe: <template><EuiFlyout @onClose={{noop}} @css={{@css}} data-probe>flyout</EuiFlyout></template>,
    target: probe,
    property: 'color',
    css: (n) => ({ color: rgbColor(n) }),
    expected: rgbColor
  },
  {
    name: 'EuiModal',
    Probe: <template><EuiModal @onClose={{noop}} @css={{@css}} data-probe>modal</EuiModal></template>,
    target: probe,
    property: 'color',
    css: (n) => ({ color: rgbColor(n) }),
    expected: rgbColor
  },
  {
    name: 'EuiToolTip @anchorCss',
    Probe: <template>
      <EuiToolTip @content="tip" @anchorCss={{@css}}>
        <:anchor><button type="button">anchor</button></:anchor>
      </EuiToolTip>
    </template>,
    target: () => $('.euiToolTipAnchor'),
    property: 'display',
    css: (n) => ({ display: n === 1 ? 'flex' : 'grid' }),
    expected: (n) => (n === 1 ? 'flex' : 'grid')
  },
  {
    name: 'EuiFormLabel',
    Probe: <template><EuiFormLabel @css={{@css}} data-probe>label</EuiFormLabel></template>,
    target: probe,
    property: 'fontSize',
    css: (n) => ({ fontSize: px(30)(n) }),
    expected: px(30)
  },
  {
    name: 'EuiFormControlLayout',
    Probe: <template>
      <EuiFormControlLayout @css={{@css}} data-probe><input aria-label="field" /></EuiFormControlLayout>
    </template>,
    target: probe,
    property: 'maxWidth',
    css: (n) => ({ maxInlineSize: px(200)(n) }),
    expected: px(200)
  },
  {
    name: 'EuiFormControlLayout @iconCss',
    Probe: <template>
      <EuiFormControlLayout @icon="search" @iconCss={{@css}} data-probe><input aria-label="field" /></EuiFormControlLayout>
    </template>,
    target: () => $('[data-probe] .euiFormControlLayoutCustomIcon .euiIcon'),
    property: 'verticalAlign',
    css: (n) => ({ verticalAlign: n === 1 ? 'top' : 'bottom' }),
    expected: (n) => (n === 1 ? 'top' : 'bottom')
  },
  {
    name: 'EuiHorizontalRule',
    Probe: <template><EuiHorizontalRule @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'marginTop',
    css: (n) => ({ marginBlock: px(40)(n) }),
    expected: px(40)
  },
  {
    name: 'EuiLink',
    Probe: <template><EuiLink @href="#x" @css={{@css}} data-probe>link</EuiLink></template>,
    target: probe,
    property: 'color',
    css: (n) => ({ color: rgbColor(n) }),
    expected: rgbColor
  },
  {
    name: 'EuiBreadcrumbs',
    Probe: <template><EuiBreadcrumbs @breadcrumbs={{BREADCRUMBS}} @css={{@css}} data-probe /></template>,
    target: probe,
    property: 'display',
    css: (n) => ({ display: n === 1 ? 'flex' : 'grid' }),
    expected: (n) => (n === 1 ? 'flex' : 'grid')
  },
  {
    name: 'EuiAccordion',
    Probe: <template>
      <EuiAccordion @id="acc" @buttonContent="toggle" @borders="all" @css={{@css}} data-probe>
        <:content>content</:content>
      </EuiAccordion>
    </template>,
    target: probe,
    property: 'borderTopStyle',
    css: (n) => ({ borderStyle: n === 1 ? 'dashed' : 'dotted' }),
    expected: (n) => (n === 1 ? 'dashed' : 'dotted')
  }
];

function computed(element: HTMLElement | null, property: string): string {
  if (!element) throw new Error('Missing styled element');
  return getComputedStyle(element).getPropertyValue(
    property.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`)
  );
}

module('Integration | Component | Borealis @css argument', function (hooks) {
  setupRenderingTest(hooks);

  for (const c of CASES) {
    test(`${c.name}: caller styles win over the component's own, whatever the rule order`, async function (assert) {
      const Probe = c.Probe;
      const first = c.css(1);
      const last = c.css(2);

      await render(
        <template>
          <CallerRule @css={{first}} />
          <Probe @css={{first}} />
        </template>
      );
      await waitUntil(() => c.target());
      assert.strictEqual(computed(c.target(), c.property), c.expected(1), 'caller rule inserted first');

      await render(
        <template>
          <Probe @css={{last}} />
          <CallerRule @css={{last}} />
        </template>
      );
      await waitUntil(() => c.target());
      assert.strictEqual(computed(c.target(), c.property), c.expected(2), 'caller rule inserted last');

      await render(<template><Probe /></template>);
      await waitUntil(() => c.target());
      const own = computed(c.target(), c.property);
      assert.notStrictEqual(own, c.expected(1), `the component's own ${c.property} differs`);
      assert.notStrictEqual(own, c.expected(2));
    });
  }

  test('EuiToolTip @css: composed into the tooltip popover class', async function (assert) {
    const css = { borderRadius: '13px' };
    await render(
      <template>
        <CallerRule @css={{css}} />
        <EuiToolTip @content="tip" @isShown={{true}} @css={{css}}>
          <:anchor><button type="button">anchor</button></:anchor>
        </EuiToolTip>
      </template>
    );
    await waitUntil(() => $('.euiToolTipPopover'));
    assert.strictEqual(getComputedStyle($('.euiToolTipPopover')!).borderTopLeftRadius, '13px');

    await render(
      <template>
        <EuiToolTip @content="tip" @isShown={{true}}>
          <:anchor><button type="button">anchor</button></:anchor>
        </EuiToolTip>
      </template>
    );
    await waitUntil(() => $('.euiToolTipPopover'));
    assert.notStrictEqual(getComputedStyle($('.euiToolTipPopover')!).borderTopLeftRadius, '13px', 'own radius differs');
  });

  test('EuiFormControlLayout @iconColor colors the icon', async function (assert) {
    await render(
      <template>
        <EuiFormControlLayout @icon="search" @iconColor="rgb(1, 2, 3)" data-probe>
          <input aria-label="field" />
        </EuiFormControlLayout>
      </template>
    );
    const icon = $('[data-probe] .euiFormControlLayoutCustomIcon .euiIcon')!;
    assert.strictEqual(getComputedStyle(icon).color, 'rgb(1, 2, 3)');
  });

  test('EuiCallOut and EuiEmptyPrompt render a real EuiPanel with their styles as its @css', async function (assert) {
    await render(
      <template>
        <EuiCallOut @title="Callout" @color="warning" data-callout />
        <EuiEmptyPrompt @color="plain" data-prompt />
      </template>
    );
    const callout = $('[data-callout]')!;
    assert.dom(callout).hasAttribute('data-eui-panel').hasClass('euiPanelBorealis').hasClass('euiCallOut');
    assert.strictEqual(callout.className.split(' ').filter((c) => c.startsWith('eui-spike-')).length, 1, 'one Emotion class');
    const prompt = $('[data-prompt]')!;
    assert.dom(prompt).hasAttribute('data-eui-panel').hasClass('euiPanelBorealis').hasClass('euiEmptyPrompt');
    assert.strictEqual(prompt.className.split(' ').filter((c) => c.startsWith('eui-spike-')).length, 1, 'one Emotion class');
  });
});
