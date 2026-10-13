import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiPinnableListGroupItemExtraActionStyles } from '../utils/eui/styles.generated.ts';
import EuiListGroup from './eui-list-group.gts';
import EuiListGroupItem from './eui-list-group-item.gts';
import spreadAttributes from '../-private/eui-spread-attributes.ts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiIconSignature } from './eui-icon';
import type { EuiListGroupSignature } from './eui-list-group';
import type {
  EuiListGroupItemColor,
  EuiListGroupItemExtraActionProps,
  EuiListGroupItemSignature
} from './eui-list-group-item';
import type { CSSInterpolation } from '@emotion/css/create-instance';
import type { ComponentLike } from '@glint/template';

export interface EuiPinnableListGroupItem {
  /** The item's text. */
  label: string;
  /** Makes the item a link. */
  href?: string;
  /** Called when the item is clicked. */
  onClick?: (event: MouseEvent) => void;
  /** Icon before the label, any `EuiIcon` type. */
  iconType?: EuiIconSignature['Args']['type'];
  /** Highlights the item, e.g. the current page. */
  isActive?: boolean;
  /** Disables the item. */
  isDisabled?: boolean;
  /** Shows the pin always, filled: the item is pinned. */
  pinned?: boolean;
  /** Set `false` for items that cannot be pinned. Defaults to `true`. */
  pinnable?: boolean;
  /** Target of the link. */
  target?: string;
  /** Wraps long text instead of truncating it. */
  wrapText?: boolean;
  /** Class for the item. */
  className?: string;
  /** `rel` of the link. */
  rel?: string;
  /** Shows the external link icon; defaults to `true` for `_blank`. */
  external?: boolean;
  /** Custom icon component, see `EuiListGroupItem`'s `@icon`. */
  icon?: EuiListGroupItemSignature['Args']['icon'];
  /** Args of the icon, see `EuiListGroupItem`'s `@iconProps`. */
  iconProps?: EuiListGroupItemSignature['Args']['iconProps'];
  /** Keeps a disabled item focusable with `aria-disabled`. */
  hasAriaDisabled?: boolean;
  /** Color of the item; defaults to the list's `@color`. */
  color?: EuiListGroupItemSignature['Args']['color'];
  /** Shows a tooltip; defaults to the list's `@showToolTips`. */
  showToolTip?: boolean;
  /** Text of the tooltip; defaults to the label. */
  toolTipText?: string;
  /** `EuiToolTip` args for the tooltip. */
  toolTipProps?: EuiListGroupItemSignature['Args']['toolTipProps'];
  /**
   * The item's own extra action; when set, no pin button is added (as
   * upstream).
   */
  extraAction?: ComponentLike | EuiListGroupItemExtraActionProps;
  [key: string]: unknown;
}

/**
 * A list of links (e.g. the pages of an app) where each item can be
 * pinned, usually to a "Pinned" list at the top of a navigation. You keep
 * the `pinned` flags; `@onPinClick` is called with the clicked item.
 */
export interface EuiPinnableListGroupSignature {
  Element: HTMLUListElement;
  Args: {
    /** The items. */
    listItems: EuiPinnableListGroupItem[];
    /** Called with the item whose pin was clicked. */
    onPinClick: (item: EuiPinnableListGroupItem) => void;
    /** Accessible label of the pin button. Defaults to "Pin item". */
    pinTitle?: (item: EuiPinnableListGroupItem) => string;
    /** Accessible label of the unpin button. Defaults to "Unpin item". */
    unpinTitle?: (item: EuiPinnableListGroupItem) => string;
    /** Adds a border around the list. */
    bordered?: boolean;
    /** @deprecated Has no effect: latest EUI lists have no padding. */
    flush?: boolean;
    /** @deprecated Has no effect: latest EUI lists have no item gutters. */
    gutterSize?: EuiListGroupSignature['Args']['gutterSize'];
    /**
     * Limits the list's width: `true` for EUI's default (400px), `false` for
     * none, or a CSS width. Defaults to `true`.
     */
    maxWidth?: EuiListGroupSignature['Args']['maxWidth'];
    /** @deprecated Has no effect: latest EUI list items have one size. */
    size?: 'xs' | 's' | 'm' | 'l';
    /** Color of the items: `'text'`, `'primary'` or `'subdued'`. Defaults to `'text'`. */
    color?: EuiListGroupItemColor;
    /** Wraps long item text instead of truncating it. */
    wrapText?: boolean;
    /** Shows a tooltip with the label on every item. */
    showToolTips?: boolean;
    /** Id of the element labelling the list (its `aria-labelledby`). */
    ariaLabelledby?: string;
  };
}

/** Item keys that are `EuiListGroupItem` args (the rest become attributes). */
const ITEM_ARGS = [
  'label',
  'href',
  'onClick',
  'iconType',
  'icon',
  'iconProps',
  'isActive',
  'isDisabled',
  'hasAriaDisabled',
  'pinned',
  'pinnable',
  'target',
  'rel',
  'external',
  'wrapText',
  'extraAction',
  'color',
  'showToolTip',
  'toolTipText',
  'toolTipProps',
  'size'
] as const;

export default class EuiPinnableListGroup extends Component<EuiPinnableListGroupSignature> {
  @service declare euiI18n: EuiI18n;

  title = (item: EuiPinnableListGroupItem): string => {
    if (item.pinned) {
      return (
        this.args.unpinTitle?.(item) ??
        this.euiI18n.lookupToken(
          'euiPinnableListGroup.pinnedExtraActionLabel',
          'Unpin item'
        )
      );
    }

    return (
      this.args.pinTitle?.(item) ??
      this.euiI18n.lookupToken(
        'euiPinnableListGroup.pinExtraActionLabel',
        'Pin item'
      )
    );
  };

  /** Pin button styles (upstream rotation, pinned color). */
  @cached
  get pinCss(): { pinned: CSSInterpolation; unpinned: CSSInterpolation } {
    const styles = useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiPinnableListGroupItemExtraActionStyles
    );
    const base = styles.euiPinnableListGroup__itemExtraAction;
    return { pinned: [base, styles.pinned], unpinned: base };
  }

  /** Upstream passes items as `listItems`, so the list's `wrapText` reaches them. */
  itemWrapText = (item: EuiPinnableListGroupItem): boolean | undefined => {
    return item.wrapText ?? this.args.wrapText;
  };

  /**
   * Upstream adds the pin action unless the item is not pinnable or brings
   * its own `extraAction`.
   */
  extraAction = (
    item: EuiPinnableListGroupItem
  ): ComponentLike | EuiListGroupItemExtraActionProps | undefined => {
    if (item.extraAction) return item.extraAction;
    if (item.pinnable === false) return undefined;
    const title = this.title(item);
    return {
      iconType: 'pinFill',
      iconSize: 's',
      className: 'euiPinnableListGroup__itemExtraAction',
      css: item.pinned ? this.pinCss.pinned : this.pinCss.unpinned,
      alwaysShow: Boolean(item.pinned),
      'aria-label': title,
      title,
      onClick: () => this.args.onPinClick(item)
    };
  };

  <template>
    <EuiListGroup
      class="euiPinnableListGroup"
      @bordered={{@bordered}}
      @maxWidth={{@maxWidth}}
      @color={{@color}}
      @wrapText={{@wrapText}}
      @showToolTips={{@showToolTips}}
      @ariaLabelledby={{@ariaLabelledby}}
      ...attributes
    >
      {{#each @listItems as |item|}}
        <EuiListGroupItem
          class="euiPinnableListGroup__item {{item.className}}"
          @label={{item.label}}
          @href={{item.href}}
          @target={{item.target}}
          @rel={{item.rel}}
          @external={{item.external}}
          @onClick={{item.onClick}}
          @iconType={{item.iconType}}
          @icon={{item.icon}}
          @iconProps={{item.iconProps}}
          @isActive={{item.isActive}}
          @isDisabled={{item.isDisabled}}
          @hasAriaDisabled={{item.hasAriaDisabled}}
          @wrapText={{this.itemWrapText item}}
          @extraAction={{this.extraAction item}}
          @color={{item.color}}
          @showToolTip={{item.showToolTip}}
          @toolTipText={{item.toolTipText}}
          @toolTipProps={{item.toolTipProps}}
          {{spreadAttributes item ITEM_ARGS}}
        />
      {{/each}}
    </EuiListGroup>
  </template>
}
