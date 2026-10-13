---
order: 4
---

# Custom rendering

<EuiText>

You can optionally pass a `<:customQuickSelectRender>` block, which yields the default panels as components and allows you to re-order panels, omit certain panels entirely, or pass in your own fully custom content. Open the quick select menu to see the result.

Ember EUI differences: upstream's `customQuickSelectRender` is a render function; here it is a named block, and each yielded panel is a component without arguments. `refreshInterval` and `customQuickSelectPanels` render nothing when the picker has no `@onRefreshChange` / `@customQuickSelectPanels`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  EuiCode,
  EuiCodeBlock,
  EuiFlexGrid,
  EuiFlexItem,
  EuiLink,
  EuiSpacer,
  EuiSuperDatePicker,
  EuiSwitch,
  EuiTitle,
} from '@ember-eui/core/components';

const noop = () => {};

const CustomPanel = <template>
  <EuiLink {{on "click" (fn @applyTime (hash start="now-30d" end="now+7d"))}}>
    Entire dataset timerange
  </EuiLink>
</template>;

const customQuickSelectPanels = [
  { title: 'Custom quick select panel', content: CustomPanel },
];

const recentlyUsedRanges = [
  { start: 'now-30m', end: 'now', label: 'Last 30 minutes' },
  { start: 'now/d', end: 'now/d', label: 'Today' },
];

export default class CustomQuickSelectRenderDemo extends Component {
  @tracked showQuickSelectPanel = true;
  @tracked showCustomPanels = true;
  @tracked showRecentlyUsed = true;
  @tracked showCommonlyUsed = true;
  @tracked showRefreshInterval = true;
  @tracked showCustomContent = false;
  @tracked start = 'now-30m';
  @tracked end = 'now';

  customQuickSelectPanels = customQuickSelectPanels;
  recentlyUsedRanges = recentlyUsedRanges;
  noop = noop;

  @action
  toggle(key) {
    this[key] = !this[key];
  }

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  get snippet() {
    const lines = [
      this.showCustomContent &&
        '    <EuiTitle @size="xxs"><span>Hello world!</span></EuiTitle>',
      this.showCustomPanels && '    <panels.customQuickSelectPanels />',
      this.showCommonlyUsed && '    <panels.commonlyUsedRanges />',
      this.showRecentlyUsed && '    <panels.recentlyUsedRanges />',
      this.showQuickSelectPanel && '    <panels.quickSelect />',
      this.showRefreshInterval && '    <panels.refreshInterval />',
    ].filter(Boolean);

    return `<EuiSuperDatePicker @onTimeChange={{this.onTimeChange}}>
  <:customQuickSelectRender as |panels|>
${lines.join('\n')}
  </:customQuickSelectRender>
</EuiSuperDatePicker>`;
  }

  <template>
    <EuiFlexGrid @columns={{2}} @gutterSize="s">
      <EuiFlexItem>
        <EuiSwitch
          @onChange={{fn this.toggle "showQuickSelectPanel"}}
          @checked={{this.showQuickSelectPanel}}
        >
          <:label>Show <EuiCode>quickSelect</EuiCode> panel</:label>
        </EuiSwitch>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSwitch
          @onChange={{fn this.toggle "showCommonlyUsed"}}
          @checked={{this.showCommonlyUsed}}
        >
          <:label>Show <EuiCode>commonlyUsedRanges</EuiCode> panel</:label>
        </EuiSwitch>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSwitch
          @onChange={{fn this.toggle "showRecentlyUsed"}}
          @checked={{this.showRecentlyUsed}}
        >
          <:label>Show <EuiCode>recentlyUsedRanges</EuiCode> panel</:label>
        </EuiSwitch>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSwitch
          @onChange={{fn this.toggle "showCustomPanels"}}
          @checked={{this.showCustomPanels}}
        >
          <:label>Show <EuiCode>customQuickSelectPanels</EuiCode></:label>
        </EuiSwitch>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSwitch
          @onChange={{fn this.toggle "showRefreshInterval"}}
          @checked={{this.showRefreshInterval}}
        >
          <:label>Show <EuiCode>refreshInterval</EuiCode> panel</:label>
        </EuiSwitch>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSwitch
          @label="Show completely custom content"
          @onChange={{fn this.toggle "showCustomContent"}}
          @checked={{this.showCustomContent}}
        />
      </EuiFlexItem>
    </EuiFlexGrid>
    <EuiSpacer />
    <EuiSuperDatePicker
      @start={{this.start}}
      @end={{this.end}}
      @onTimeChange={{this.onTimeChange}}
      @recentlyUsedRanges={{this.recentlyUsedRanges}}
      @customQuickSelectPanels={{this.customQuickSelectPanels}}
      @isPaused={{false}}
      @refreshInterval={{1000}}
      @onRefreshChange={{this.noop}}
    >
      <:customQuickSelectRender as |panels|>
        {{#if this.showCustomContent}}
          <EuiTitle @size="xxs"><span>Hello world!</span></EuiTitle>
        {{/if}}
        {{#if this.showCustomPanels}}
          <panels.customQuickSelectPanels />
        {{/if}}
        {{#if this.showCommonlyUsed}}
          <panels.commonlyUsedRanges />
        {{/if}}
        {{#if this.showRecentlyUsed}}
          <panels.recentlyUsedRanges />
        {{/if}}
        {{#if this.showQuickSelectPanel}}
          <panels.quickSelect />
        {{/if}}
        {{#if this.showRefreshInterval}}
          <panels.refreshInterval />
        {{/if}}
      </:customQuickSelectRender>
    </EuiSuperDatePicker>
    <EuiSpacer />
    <EuiTitle @size="xs"><strong>Example snippet:</strong></EuiTitle>
    <EuiSpacer @size="s" />
    <EuiCodeBlock @language="hbs">{{this.snippet}}</EuiCodeBlock>
  </template>
}
```
