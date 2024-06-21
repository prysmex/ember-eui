import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { scheduleOnce } from '@ember/runloop';

import findBy from 'ember-composable-helpers/helpers/find-by';
import { eq } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import EuiTab from './eui-tab.gts';
import EuiTabs from './eui-tabs.gts';

import type { CommonArgs } from './common.ts';
import type { EuiTabsSignature } from './eui-tabs';
import type { ComponentLike } from '@glint/template';

export interface EuiTabbedContentTab {
  id: string;
  name: string;
  content?: ComponentLike;
  disabled?: boolean;
}

export type EuiTabbedContentArgs = CommonArgs & {
  /**
   * When tabbing into the tabs, set the focus on `initial` for the first tab,
   * or `selected` for the currently selected tab. Best use case is for inside of
   * overlay content like popovers or flyouts.
   */
  autoFocus?: 'initial' | 'selected';
  /**
   * Choose `default` or alternative `condensed` display styles
   */
  display?: EuiTabsSignature['Args']['display'];
  /**
   * Evenly stretches each tab to fill the horizontal space
   */
  expand?: boolean;
  /**
   * Use this prop to set the initially selected tab while letting the tabbed content component
   * control selection state internally
   */
  initialSelectedTab?: EuiTabbedContentTab;
  onTabClick?: (selectedTab: EuiTabbedContentTab) => void;
  /**
   * Use this prop if you want to control selection state within the owner component
   */
  selectedTab?: EuiTabbedContentTab;
  size?: EuiTabsSignature['Args']['size'];
  /**
   * Each tab needs id and content properties, so we can associate it with its panel for accessibility.
   * The name property (a node) is also required to display to the user.
   */
  tabs: EuiTabbedContentTab[];
};

export interface EuiTabbedContentSignature {
  Element: HTMLDivElement;
  Args: EuiTabbedContentArgs;
  Blocks: {
    default: [EuiTabbedContentTab];
    selectedTabContent: [EuiTabbedContentTab];
  };
}

export default class EuiTabbedContentComponent extends Component<EuiTabbedContentSignature> {
  @tracked selectedTabId;
  @tracked inFocus: boolean = false;
  tabsRef?: Element;

  get autoFocus() {
    return this.args.autoFocus || 'initial';
  }

  constructor(owner: unknown, args: EuiTabbedContentArgs) {
    super(owner, args);

    const { initialSelectedTab, selectedTab, tabs } = this.args;

    // Only track selection state if it's not controlled externally.
    if (!selectedTab) {
      this.selectedTabId =
        (initialSelectedTab && initialSelectedTab.id) || tabs[0]?.id;
    }
  }

  get selectedTab() {
    const { selectedTab: externalSelectedTab, tabs } = this.args;

    return (
      externalSelectedTab ||
      tabs.find((tab: EuiTabbedContentTab) => tab.id === this.selectedTabId)
    );
  }

  setTabsRef = (element: Element) => {
    this.tabsRef = element;
    // Current short-term solution for event listener (see https://github.com/elastic/eui/pull/2717)
    //@ts-expect-error
    this.tabsRef.addEventListener('focusout', this.removeFocus);
  };

  willDestroy(): void {
    super.willDestroy();

    if (this.tabsRef) {
      //@ts-expect-error
      this.tabsRef.removeEventListener('focusout', this.removeFocus);
    }
  }

  removeFocus = (blurEvent: FocusEvent) => {
    // only set inFocus to false if the wrapping div doesn't contain the now-focusing element
    const currentTarget = blurEvent.currentTarget! as HTMLElement;
    const relatedTarget = blurEvent.relatedTarget! as HTMLElement;

    if (currentTarget.contains(relatedTarget) === false) {
      this.inFocus = true;
    }
  };

  onTabClick = (selectedTab: EuiTabbedContentTab) => {
    const { onTabClick, selectedTab: externalSelectedTab } = this.args;

    if (onTabClick) {
      onTabClick(selectedTab);
    }

    // Only track selection state if it's not controlled externally.
    if (!externalSelectedTab) {
      this.selectedTabId = selectedTab.id;

      const focusTab = () => {
        this.focusTab();
      };

      scheduleOnce('afterRender', this, focusTab);
    }
  };

  focusTab = () => {
    if (this.tabsRef) {
      const targetTab: HTMLDivElement | null = this.tabsRef.querySelector(
        `#${this.selectedTabId}`
      );

      targetTab!.focus();
    }
  };

  initializeFocus = () => {
    if (!this.inFocus && this.autoFocus === 'selected') {
      // Must wait for setState to finish before calling `.focus()`
      // as the focus call triggers a blur on the first tab
      this.inFocus = true;

      const focusTab = () => {
        this.focusTab();
      };

      scheduleOnce('afterRender', this, focusTab);
    }
  };

  <template>
    {{#let (randomId) as |rootId|}}
      <div class={{@className}} ...attributes>
        <EuiTabs
          @expand={{@expand}}
          @display={{@display}}
          @size={{@size}}
          {{on "focus" this.initializeFocus}}
          {{didInsert this.setTabsRef}}
        >
          {{#each @tabs as |tab|}}
            <EuiTab
              @id={{tab.id}}
              aria-controls={{rootId}}
              @isSelected={{eq tab.id this.selectedTab.id}}
              @disabled={{tab.disabled}}
              {{on "click" (fn this.onTabClick tab)}}
            >
              {{tab.name}}
            </EuiTab>
          {{/each}}
        </EuiTabs>
        {{#let (findBy "id" this.selectedTab.id @tabs) as |currentTab|}}
          <div role="tabpanel" id={{rootId}} aria-labelledby={{currentTab.id}}>
            {{#if (has-block "selectedTabContent")}}
              {{yield currentTab to="selectedTabContent"}}
            {{else}}
              {{currentTab.content}}
            {{/if}}
          </div>
        {{/let}}
      </div>
    {{/let}}
  </template>
}
