import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import cssStyle from '../-private/css-style.ts';
import EuiContextMenuItem from './eui-context-menu-item.gts';
import EuiContextMenuPanel from './eui-context-menu-panel.gts';
import EuiHorizontalRule from './eui-horizontal-rule.gts';

import type { EuiContextMenuItemSignature } from './eui-context-menu-item';
import type Owner from '@ember/owner';

type PanelId = string | number;

/** One entry of a panel: an item, or a separator (`{ isSeparator: true }`). */
export type EuiContextMenuPanelItem =
  | { isSeparator: true; key?: string }
  | {
      isSeparator?: false;
      /** The item's text. */
      name: string;
      /** Icon before the text, any `EuiIcon` type. */
      icon?: EuiContextMenuItemSignature['Args']['icon'];
      /** Id of the panel this item opens (it gets an arrow). */
      panel?: PanelId;
      /** Called when the item is clicked (also when it opens a panel). */
      onClick?: (event: MouseEvent) => void;
      /** Makes the item a link. */
      href?: string;
      /** `target` of the link. */
      target?: string;
      /** Disables the item. */
      disabled?: boolean;
      /** Aligns the icon with the `'center'` or the `'top'` of the text. */
      layoutAlign?: EuiContextMenuItemSignature['Args']['layoutAlign'];
      /** `data-test-subj` of the item, for tests. */
      'data-test-subj'?: string;
    };

export interface EuiContextMenuPanelDescriptor {
  /** Unique id; items open the panel with `panel: id`. */
  id: PanelId;
  /** Title of the panel (a back button on panels opened from another). */
  title?: string;
  /**
   * The panel's items. Without items, the `<:content>` block renders the
   * panel's content instead (e.g. a form).
   */
  items?: EuiContextMenuPanelItem[];
  /** Width of the menu while this panel is shown, e.g. `400` (px). */
  width?: number | string;
  /** Item to focus when the panel opens. */
  initialFocusedItemIndex?: number;
}

/**
 * A menu of panels: items can open another panel (a sub-menu), which
 * slides in with a back button to return. Usually the content of an
 * `EuiPopover`. For a single list of items, `EuiContextMenuPanel` is
 * enough.
 */
export interface EuiContextMenuSignature {
  Element: HTMLDivElement;
  Args: {
    /** Every panel, flat: an item's `panel` is the id of the panel it opens. */
    panels: EuiContextMenuPanelDescriptor[];
    /** Id of the panel shown first. */
    initialPanelId: PanelId;
    /** `'s'` for smaller items and titles. Defaults to `'m'`. */
    size?: 's' | 'm';
  };
  Blocks: {
    /** Content of the panels without `items`; yields the panel. */
    content: [panel: EuiContextMenuPanelDescriptor];
  };
}

type Direction = 'next' | 'previous';

function itemSize(size?: 's' | 'm'): 's' | undefined {
  return size === 's' ? 's' : undefined;
}

function isSeparator(
  item: EuiContextMenuPanelItem
): item is { isSeparator: true; key?: string } {
  return item.isSeparator === true;
}

export default class EuiContextMenu extends Component<EuiContextMenuSignature> {
  @tracked incomingPanelId: PanelId;
  @tracked outgoingPanelId?: PanelId;
  @tracked transitionDirection?: Direction;
  @tracked isOutgoingPanelVisible = false;
  @tracked height?: number;
  @tracked focusedItemIndex?: number;
  @tracked isUsingKeyboardToNavigate = false;

  constructor(owner: Owner, args: EuiContextMenuSignature['Args']) {
    super(owner, args);
    // only the starting point: items then move between panels
    this.incomingPanelId = args.initialPanelId;
  }

  get panelsById(): Map<PanelId, EuiContextMenuPanelDescriptor> {
    return new Map(this.args.panels.map((panel) => [panel.id, panel]));
  }

  /** For each panel opened from an item: the panel holding that item. */
  get previousPanelIds(): Map<PanelId, PanelId> {
    const map = new Map<PanelId, PanelId>();

    for (const panel of this.args.panels) {
      for (const item of panel.items ?? []) {
        if (!isSeparator(item) && item.panel !== undefined) map.set(item.panel, panel.id);
      }
    }

    return map;
  }

  // one-element lists keyed by panel id, so a panel gets a new element
  // (and its slide animation runs again) whenever the shown panel changes
  get incomingPanels(): EuiContextMenuPanelDescriptor[] {
    const panel = this.panelsById.get(this.incomingPanelId);

    return panel ? [panel] : [];
  }

  get outgoingPanels(): EuiContextMenuPanelDescriptor[] {
    const panel =
      this.isOutgoingPanelVisible && this.outgoingPanelId !== undefined
        ? this.panelsById.get(this.outgoingPanelId)
        : undefined;

    return panel ? [panel] : [];
  }

  get width(): number | string | undefined {
    return this.panelsById.get(this.incomingPanelId)?.width;
  }

  get classes(): string {
    return this.args.size === 's' ? 'euiContextMenu euiContextMenu--small' : 'euiContextMenu';
  }

  hasPreviousPanel = (panelId: PanelId): boolean => this.previousPanelIds.has(panelId);

  showPanel(panelId: PanelId, direction: Direction): void {
    this.outgoingPanelId = this.incomingPanelId;
    this.incomingPanelId = panelId;
    this.transitionDirection = direction;
    this.isOutgoingPanelVisible = true;
  }

  @action
  showNextPanel(itemIndex?: number): void {
    if (itemIndex === undefined) return;

    const item = this.panelsById.get(this.incomingPanelId)?.items?.[itemIndex];
    const nextPanelId = item && !isSeparator(item) ? item.panel : undefined;

    if (nextPanelId === undefined) return;

    if (this.isUsingKeyboardToNavigate) {
      this.focusedItemIndex = this.panelsById.get(nextPanelId)?.initialFocusedItemIndex ?? 0;
    }

    this.showPanel(nextPanelId, 'next');
  }

  @action
  showPreviousPanel(): void {
    const previousPanelId = this.previousPanelIds.get(this.incomingPanelId);

    if (previousPanelId === undefined) return;

    // focus the item that opened the panel we are leaving
    const index = (this.panelsById.get(previousPanelId)?.items ?? []).findIndex(
      (item) => !isSeparator(item) && item.panel === this.incomingPanelId
    );

    if (index !== -1) this.focusedItemIndex = index;

    this.showPanel(previousPanelId, 'previous');
  }

  @action
  onItemClick(item: EuiContextMenuPanelItem, index: number, event: MouseEvent): void {
    if (isSeparator(item)) return;

    item.onClick?.(event);

    if (item.panel !== undefined) this.showNextPanel(index);
  }

  @action
  onOutgoingTransitionComplete(): void {
    this.isOutgoingPanelVisible = false;
  }

  @action
  onIncomingHeightChange(height: number): void {
    if (height !== this.height) this.height = height;
  }

  @action
  onUseKeyboardToNavigate(): void {
    if (!this.isUsingKeyboardToNavigate) this.isUsingKeyboardToNavigate = true;
  }

  initialFocusedItemIndex = (panel: EuiContextMenuPanelDescriptor): number | undefined =>
    this.isUsingKeyboardToNavigate ? this.focusedItemIndex : panel.initialFocusedItemIndex;

  <template>
    <div
      class={{this.classes}}
      style={{cssStyle (hash height=this.height width=this.width)}}
      ...attributes
    >
      {{#each this.outgoingPanels key="id" as |panel|}}
        <EuiContextMenuPanel
          class="euiContextMenu__panel"
          @title={{panel.title}}
          @size={{@size}}
          @transitionType="out"
          @transitionDirection={{this.transitionDirection}}
          @onTransitionComplete={{this.onOutgoingTransitionComplete}}
          @hasFocus={{false}}
        >
          {{#if panel.items}}
            {{#each panel.items as |item index|}}
              {{#if item.isSeparator}}
                <EuiHorizontalRule @margin="none" />
              {{else}}
                <EuiContextMenuItem
                  @icon={{item.icon}}
                  @hasPanel={{if item.panel true false}}
                  @href={{item.href}}
                  @target={{item.target}}
                  @disabled={{item.disabled}}
                  @layoutAlign={{item.layoutAlign}}
                  @size={{itemSize @size}}
                  {{on "click" (fn this.onItemClick item index)}}
                >{{item.name}}</EuiContextMenuItem>
              {{/if}}
            {{/each}}
          {{else}}
            {{yield panel to="content"}}
          {{/if}}
        </EuiContextMenuPanel>
      {{/each}}
      {{#each this.incomingPanels key="id" as |panel|}}
        <EuiContextMenuPanel
          class="euiContextMenu__panel"
          @title={{panel.title}}
          @size={{@size}}
          @onClose={{if
            (this.hasPreviousPanel panel.id)
            this.showPreviousPanel
          }}
          @transitionType={{if this.isOutgoingPanelVisible "in"}}
          @transitionDirection={{if
            this.isOutgoingPanelVisible
            this.transitionDirection
          }}
          @hasFocus={{true}}
          @initialFocusedItemIndex={{this.initialFocusedItemIndex panel}}
          @onHeightChange={{this.onIncomingHeightChange}}
          @showNextPanel={{this.showNextPanel}}
          @showPreviousPanel={{this.showPreviousPanel}}
          @onUseKeyboardToNavigate={{this.onUseKeyboardToNavigate}}
        >
          {{#if panel.items}}
            {{#each panel.items as |item index|}}
              {{#if item.isSeparator}}
                <EuiHorizontalRule @margin="none" />
              {{else}}
                <EuiContextMenuItem
                  @icon={{item.icon}}
                  @hasPanel={{if item.panel true false}}
                  @href={{item.href}}
                  @target={{item.target}}
                  @disabled={{item.disabled}}
                  @layoutAlign={{item.layoutAlign}}
                  @size={{itemSize @size}}
                  data-test-subj={{get item "data-test-subj"}}
                  {{on "click" (fn this.onItemClick item index)}}
                >{{item.name}}</EuiContextMenuItem>
              {{/if}}
            {{/each}}
          {{else}}
            {{yield panel to="content"}}
          {{/if}}
        </EuiContextMenuPanel>
      {{/each}}
    </div>
  </template>
}
