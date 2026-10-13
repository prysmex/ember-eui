import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { action } from '@ember/object';

import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiContextMenuStyles } from '../utils/eui/styles.generated.ts';
import EuiContextMenuEntry from '../-private/eui-context-menu-entry.gts';
import EuiContextMenuPanel from './eui-context-menu-panel.gts';

import type { EuiContextMenuItemSignature } from './eui-context-menu-item';
import type { EuiHorizontalRuleSignature } from './eui-horizontal-rule';
import type { ComponentLike } from '@glint/template';
import type Owner from '@ember/owner';

type PanelId = string | number;

/** What `@onPanelChange` receives. */
export interface EuiContextMenuPanelChange {
  /** Id of the panel now shown. */
  panelId: PanelId;
  /** `'next'` (opened from an item) or `'previous'` (back). */
  direction?: Direction;
}

/** One entry of a panel: an item, or a separator (`{ isSeparator: true }`). */
export type EuiContextMenuPanelItem =
  | {
      /**
       * A separator line. Takes the `EuiHorizontalRule` args (`margin`,
       * `size`, `css`; `margin` defaults to `'xs'`), `className` and any
       * other key as an attribute.
       */
      isSeparator: true;
      key?: string;
      margin?: EuiHorizontalRuleSignature['Args']['margin'];
      size?: EuiHorizontalRuleSignature['Args']['size'];
      css?: EuiHorizontalRuleSignature['Args']['css'];
      className?: string;
      [attribute: string]: unknown;
    }
  | {
      /**
       * Any custom content between the items: a component rendered as is
       * (upstream's `renderItem` function).
       */
      renderItem: ComponentLike<any>;
      key?: string;
      isSeparator?: false;
    }
  | {
      isSeparator?: false;
      /** The item's text. */
      name: string;
      /**
       * Icon before the text: any `EuiIcon` type, or a component rendered
       * as the icon (e.g. an `EuiIcon` curried with a color and size).
       */
      icon?: EuiContextMenuItemSignature['Args']['icon'];
      /** Id of the panel this item opens (it gets an arrow). */
      panel?: PanelId;
      /** Called when the item is clicked (also when it opens a panel). */
      onClick?: (event: MouseEvent) => void;
      /** Makes the item a link. */
      href?: string;
      /** `target` of the link. */
      target?: string;
      /** `rel` of the link. */
      rel?: string;
      /**
       * Shows the external link icon; defaults to `true` for
       * `target: '_blank'`.
       */
      external?: boolean;
      /** Disables the item. */
      disabled?: boolean;
      /** Keeps a disabled item focusable (`aria-disabled`), e.g. for its tooltip. */
      hasAriaDisabled?: boolean;
      /** Aligns the icon with the `'center'` or the `'top'` of the text. */
      layoutAlign?: EuiContextMenuItemSignature['Args']['layoutAlign'];
      /** Color of the item: `'text'` (default) or e.g. `'danger'`. */
      color?: string;
      /** Tooltip shown on the right of the item. */
      toolTipContent?: string;
      /** Title of the item's tooltip. */
      toolTipTitle?: string;
      /** More `EuiToolTip` args for the tooltip, see `EuiContextMenuItem`. */
      toolTipProps?: EuiContextMenuItemSignature['Args']['toolTipProps'];
      /** `data-test-subj` of the item, for tests. */
      'data-test-subj'?: string;
      /**
       * Other keys (`aria-current`, `id`, `data-*`, …) become attributes of
       * the item, as upstream spreads them.
       */
      [attribute: string]: unknown;
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
    /** @deprecated Has no effect: latest EUI has a single item size. */
    size?: 's' | 'm';
    /**
     * Fixes the menu's height (a number of px or any CSS height) instead of
     * fitting the panel; the items of a panel then scroll. Defaults to the
     * height of the shown panel.
     */
    height?: number | string;
    /**
     * Called when another panel is shown (an item opened it, or the back
     * button or arrow left returned to it) with `{ panelId, direction }`.
     */
    onPanelChange?: (change: EuiContextMenuPanelChange) => void;
  };
  Blocks: {
    /** Content of the panels without `items`; yields the panel. */
    content: [panel: EuiContextMenuPanelDescriptor];
  };
}

type Direction = 'next' | 'previous';

type PlainItem = Exclude<
  EuiContextMenuPanelItem,
  { isSeparator: true } | { renderItem: ComponentLike<any> }
>;

function isItem(item: EuiContextMenuPanelItem): item is PlainItem {
  return item.isSeparator !== true && !('renderItem' in item);
}


export default class EuiContextMenu extends Component<EuiContextMenuSignature> {
  @tracked incomingPanelId: PanelId;
  @tracked outgoingPanelId?: PanelId;
  @tracked transitionDirection?: Direction;
  @tracked isOutgoingPanelVisible = false;
  @tracked height?: number;
  @tracked focusedItemIndex?: number;
  @tracked isUsingKeyboardToNavigate = false;
  /**
   * Whether the user moved to another panel. The first panel does not take
   * the focus (in a popover, the popover focuses its first item once it is
   * positioned); panels reached afterwards do.
   */
  @tracked hasNavigated = false;

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
        if (isItem(item) && item.panel !== undefined) map.set(item.panel, panel.id);
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

  /** A fixed `@height` wins over the height of the shown panel. */
  get menuHeight(): number | string | undefined {
    return this.args.height ?? this.height;
  }

  get width(): number | string | undefined {
    return this.panelsById.get(this.incomingPanelId)?.width;
  }

  /** Upstream: 256px wide (a panel `width` wins), clipped, animated height. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiContextMenuStyles);

    return `euiContextMenu ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiContextMenu,
      this.args.height !== undefined && styles.fixedHeight
    )}`;
  }

  /** Upstream stacks the sliding panels on top of each other. */
  @cached
  get panelClasses(): string {
    const context = getEuiThemeContext(this);

    return `euiContextMenu__panel ${euiClass(context, {
      position: 'absolute',
      label: 'euiContextMenu__panel'
    })}`;
  }

  hasPreviousPanel = (panelId: PanelId): boolean => this.previousPanelIds.has(panelId);

  showPanel(panelId: PanelId, direction: Direction): void {
    this.hasNavigated = true;
    this.outgoingPanelId = this.incomingPanelId;
    this.incomingPanelId = panelId;
    this.transitionDirection = direction;
    this.isOutgoingPanelVisible = true;
    this.args.onPanelChange?.({ panelId, direction });
  }

  @action
  showNextPanel(itemIndex?: number): void {
    if (itemIndex === undefined) return;

    const item = this.panelsById.get(this.incomingPanelId)?.items?.[itemIndex];
    const nextPanelId = item && isItem(item) ? item.panel : undefined;

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
      (item) => isItem(item) && item.panel === this.incomingPanelId
    );

    if (index !== -1) this.focusedItemIndex = index;

    this.showPanel(previousPanelId, 'previous');
  }

  @action
  onItemClick(item: EuiContextMenuPanelItem, index: number, event: MouseEvent): void {
    if (!isItem(item)) return;

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
      style={{cssStyle (hash height=this.menuHeight width=this.width)}}
      ...attributes
    >
      {{#each this.outgoingPanels key="id" as |panel|}}
        <EuiContextMenuPanel
          class={{this.panelClasses}}
          @title={{panel.title}}
          @isMenu={{if panel.items true false}}
          @transitionType="out"
          @transitionDirection={{this.transitionDirection}}
          @onTransitionComplete={{this.onOutgoingTransitionComplete}}
          @hasFocus={{false}}
        >
          {{#if panel.items}}
            {{#each panel.items as |item index|}}
              <EuiContextMenuEntry @item={{item}} @index={{index}} @onItemClick={{this.onItemClick}} />
            {{/each}}
          {{else}}
            {{yield panel to="content"}}
          {{/if}}
        </EuiContextMenuPanel>
      {{/each}}
      {{#each this.incomingPanels key="id" as |panel|}}
        <EuiContextMenuPanel
          class={{this.panelClasses}}
          @title={{panel.title}}
          @isMenu={{if panel.items true false}}
          @onClose={{if
            (this.hasPreviousPanel panel.id)
            this.showPreviousPanel
          }}
          @transitionType={{if this.isOutgoingPanelVisible "in"}}
          @transitionDirection={{if
            this.isOutgoingPanelVisible
            this.transitionDirection
          }}
          @hasFocus={{this.hasNavigated}}
          @initialFocusedItemIndex={{this.initialFocusedItemIndex panel}}
          @onHeightChange={{this.onIncomingHeightChange}}
          @showNextPanel={{this.showNextPanel}}
          @showPreviousPanel={{this.showPreviousPanel}}
          @onUseKeyboardToNavigate={{this.onUseKeyboardToNavigate}}
        >
          {{#if panel.items}}
            {{#each panel.items as |item index|}}
              <EuiContextMenuEntry @item={{item}} @index={{index}} @onItemClick={{this.onItemClick}} />
            {{/each}}
          {{else}}
            {{yield panel to="content"}}
          {{/if}}
        </EuiContextMenuPanel>
      {{/each}}
    </div>
  </template>
}
