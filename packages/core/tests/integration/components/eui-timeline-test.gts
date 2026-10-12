import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { render, settled } from '@ember/test-helpers';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiTimeline from '#src/components/eui-timeline.gts';
import EuiTimelineItem from '#src/components/eui-timeline-item.gts';
import EuiTimelineItemEvent from '#src/components/eui-timeline-item-event.gts';
import EuiTimelineItemIcon from '#src/components/eui-timeline-item-icon.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiTimelineItemData } from '#src/components/eui-timeline-item.gts';
import type { EuiTimelineGutterSize } from '#src/components/eui-timeline.gts';
import type { EuiTimelineVerticalAlign } from '#src/components/eui-timeline-item.gts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;

function el(selector: string): HTMLElement {
  const element = document.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

function px(value: string) {
  const probe = document.createElement('div');
  probe.style.width = value;
  document.body.appendChild(probe);
  const resolved = getComputedStyle(probe).width;
  probe.remove();
  return resolved;
}

module('Integration | Component | Borealis timeline', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the upstream list, item, avatar and event semantics', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiTimeline aria-label="Deployment history" class="caller">
            <EuiTimelineItem @icon="check" @iconAriaLabel="Completed" data-item>
              Deployed version 3
            </EuiTimelineItem>
            <EuiTimelineItem @icon="clock">Pending approval</EuiTimelineItem>
          </EuiTimeline>
        </EuiEmotionProvider>
      </template>
    );

    assert
      .dom('ol.euiTimeline')
      .hasAttribute('role', 'list')
      .hasAttribute('aria-label', 'Deployment history')
      .hasClass('caller');
    assert.dom('ol.euiTimeline > li.euiTimelineItem').exists({ count: 2 });
    assert.dom('[data-item] .euiTimelineItemEvent').hasText('Deployed version 3');
    assert
      .dom('[data-item] .euiAvatar')
      .hasAttribute('role', 'img')
      .hasAttribute('aria-label', 'Completed');
    assert.dom('[data-item] [data-icon-type="check"]').exists();
    assert
      .dom('li:nth-child(2) .euiAvatar')
      .hasAttribute('aria-label', '', 'an unlabeled icon is decorative to assistive technology');
  });

  test('matches upstream layout, default xl gutter and connecting line', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiTimeline>
            <EuiTimelineItem>First</EuiTimelineItem>
            <EuiTimelineItem>Second</EuiTimelineItem>
          </EuiTimeline>
        </EuiEmotionProvider>
      </template>
    );

    const timeline = css('.euiTimeline');
    assert.strictEqual(timeline.display, 'flex');
    assert.strictEqual(timeline.flexDirection, 'column');
    assert.strictEqual(timeline.gap, px(light.size.xl), 'xl gutter is the upstream default');
    assert.strictEqual(timeline.margin, '0px', 'React list reset is scoped locally');
    assert.strictEqual(timeline.padding, '0px');
    assert.strictEqual(timeline.listStyleType, 'none');

    const line = css('.euiTimelineItemIcon', '::before');
    assert.strictEqual(line.content, '""');
    assert.strictEqual(line.position, 'absolute');
    assert.notStrictEqual(line.borderLeftWidth, '0px');
    assert.true(
      parseFloat(line.height) > el('.euiTimelineItemIcon').getBoundingClientRect().height,
      'the non-final line crosses the gutter'
    );
  });

  test('gutter and vertical alignment react without replacing elements', async function (assert) {
    class State {
      @tracked gutter: EuiTimelineGutterSize = 'm';
      @tracked align: EuiTimelineVerticalAlign = 'center';
    }
    const state = new State();

    await render(
      <template>
        <EuiTimeline @gutterSize={{state.gutter}}>
          <EuiTimelineItem @verticalAlign={{state.align}} data-item>Event</EuiTimelineItem>
        </EuiTimeline>
      </template>
    );

    const timeline = el('.euiTimeline');
    const item = el('[data-item]');
    assert.strictEqual(css('.euiTimeline').gap, px(light.size.base));
    assert.strictEqual(css('.euiTimelineItemEvent').alignSelf, 'center');
    assert.strictEqual(css('.euiTimelineItemIcon').alignItems, 'center');

    state.gutter = 'l';
    state.align = 'top';
    await settled();

    assert.strictEqual(el('.euiTimeline'), timeline, 'timeline element is stable');
    assert.strictEqual(el('[data-item]'), item, 'item element is stable');
    assert.strictEqual(css('.euiTimeline').gap, px(light.size.l));
    assert.strictEqual(css('.euiTimelineItemEvent').alignSelf, 'flex-start');
    assert.strictEqual(css('.euiTimelineItemIcon').alignItems, 'flex-start');
  });

  test('supports custom icon content, direct subcomponents, attributes and @css', async function (assert) {
    await render(
      <template>
        <EuiTimeline @css={{hash width="321px"}} data-timeline>
          <EuiTimelineItem @css={{hash minHeight="41px"}} data-item>
            <:icon><span data-custom-icon>CI</span></:icon>
            <:default>Custom event</:default>
          </EuiTimelineItem>
        </EuiTimeline>
        <EuiTimelineItemIcon @css={{hash marginRight="23px"}} data-direct-icon>
          <span>Direct icon</span>
        </EuiTimelineItemIcon>
        <EuiTimelineItemEvent @css={{hash flexBasis="77px"}} data-direct-event>
          Direct event
        </EuiTimelineItemEvent>
      </template>
    );

    assert.strictEqual(css('[data-timeline]').width, '321px');
    assert.strictEqual(css('[data-item]').minHeight, '41px');
    assert.dom('[data-custom-icon]').hasText('CI');
    assert.dom('[data-item] .euiAvatar').doesNotExist();
    assert.dom('[data-item] .euiTimelineItemEvent').hasText('Custom event');
    assert.strictEqual(css('[data-direct-icon]').marginRight, '23px');
    assert.strictEqual(css('[data-direct-event]').flexBasis, '77px');
  });

  test('renders simple @items before rich block content', async function (assert) {
    const items: EuiTimelineItemData[] = [
      { content: 'Created', icon: 'plus', iconAriaLabel: 'Created' },
      { content: 'Reviewed', icon: 'eye', verticalAlign: 'top' }
    ];

    await render(
      <template>
        <EuiTimeline @items={{items}}>
          <EuiTimelineItem @icon="check">Merged</EuiTimelineItem>
        </EuiTimeline>
      </template>
    );

    assert.dom('.euiTimelineItem').exists({ count: 3 });
    assert.dom('.euiTimelineItem:nth-child(1)').hasText('Created');
    assert.dom('.euiTimelineItem:nth-child(2)').hasText('Reviewed');
    assert.dom('.euiTimelineItem:nth-child(3)').hasText('Merged');
  });

  test('theme overrides, contrast, sibling isolation and RTL use the nearest provider', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <div dir="rtl">
            <EuiTimeline data-scoped>
              <EuiTimelineItem @icon="check">Scoped</EuiTimelineItem>
            </EuiTimeline>
          </div>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="dark">
          <EuiTimeline data-dark>
            <EuiTimelineItem @icon="check">Dark sibling</EuiTimelineItem>
          </EuiTimeline>
        </EuiEmotionProvider>
      </template>
    );

    const scopedIcon = '[data-scoped] .euiTimelineItemIcon';
    assert.strictEqual(css(scopedIcon).marginLeft, px(light.size.base), 'RTL uses inline-end');
    assert.strictEqual(css(scopedIcon).marginRight, '0px');
    const darkLineBefore = css('[data-dark] .euiTimelineItemIcon', '::before').borderLeftColor;

    state.overrides = {
      border: { color: '#123456' },
      size: { base: '20px' }
    };
    await settled();
    assert.strictEqual(css(scopedIcon).marginLeft, '20px', 'size override reaches icon spacing');
    assert.strictEqual(
      css(scopedIcon, '::before').borderRightColor,
      'rgb(18, 52, 86)',
      'border override reaches the RTL timeline connector at inline-start'
    );
    assert.strictEqual(
      css('[data-dark] .euiTimelineItemIcon', '::before').borderLeftColor,
      darkLineBefore,
      'the dark sibling is isolated from overrides'
    );

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    assert.strictEqual(
      css('[data-scoped] .euiAvatar').borderTopStyle,
      'solid',
      'preferred contrast outlines icon content'
    );
  });
});
