import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import EuiButtonIcon from './eui-button-icon.gts';
import EuiListGroup from './eui-list-group.gts';
import EuiListGroupItem from './eui-list-group-item.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiIconSignature } from './eui-icon';
import type { EuiListGroupSignature } from './eui-list-group';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

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
    /** Removes the padding around the list. */
    flush?: boolean;
    /** Space between items: `'none'` or `'s'`. Defaults to `'s'`. */
    gutterSize?: EuiListGroupSignature['Args']['gutterSize'];
    /** Limits the list's width: `true` for EUI's default, or a CSS width. */
    maxWidth?: EuiListGroupSignature['Args']['maxWidth'];
    /** Text size of the items: `'xs'`, `'s'`, `'m'` or `'l'`. */
    size?: 'xs' | 's' | 'm' | 'l';
    /** Text color of the items: `'primary'`, `'text'`, `'subdued'`, `'ghost'`. */
    color?: 'primary' | 'text' | 'subdued' | 'ghost' | 'inherit';
  };
}

interface PinButtonSignature {
  Args: {
    item: EuiPinnableListGroupItem;
    title: string;
    onPinClick: (item: EuiPinnableListGroupItem) => void;
  };
}

const PinButton: TemplateOnlyComponent<PinButtonSignature> = <template>
  <EuiButtonIcon
    class="euiListGroupItem__extraAction euiPinnableListGroup__itemExtraAction
      {{if
        @item.pinned
        'euiPinnableListGroup__itemExtraAction-pinned euiListGroupItem__extraAction-alwaysShow'
      }}"
    @iconType="pinFilled"
    @iconSize="s"
    @color="primary"
    title={{@title}}
    aria-label={{@title}}
    {{on "click" (fn @onPinClick @item)}}
  />
</template>;

export default class EuiPinnableListGroup extends Component<EuiPinnableListGroupSignature> {
  @service declare euiI18n: EuiI18n;

  title = (item: EuiPinnableListGroupItem): string => {
    if (item.pinned) {
      return (
        this.args.unpinTitle?.(item) ??
        this.euiI18n.lookupToken('euiPinnableListGroup.pinnedExtraActionLabel', 'Unpin item')
      );
    }

    return (
      this.args.pinTitle?.(item) ??
      this.euiI18n.lookupToken('euiPinnableListGroup.pinExtraActionLabel', 'Pin item')
    );
  };

  isPinnable = (item: EuiPinnableListGroupItem): boolean => item.pinnable !== false;

  <template>
    <EuiListGroup
      class="euiPinnableListGroup"
      @bordered={{@bordered}}
      @flush={{@flush}}
      @gutterSize={{@gutterSize}}
      @maxWidth={{@maxWidth}}
      ...attributes
    >
      {{#each @listItems as |item|}}
        <EuiListGroupItem
          class="euiPinnableListGroup__item"
          @label={{item.label}}
          @href={{item.href}}
          @onClick={{item.onClick}}
          @iconType={{item.iconType}}
          @isActive={{item.isActive}}
          @isDisabled={{item.isDisabled}}
          @size={{@size}}
          @color={{@color}}
          @extraAction={{if
            (this.isPinnable item)
            (component
              PinButton
              item=item
              title=(this.title item)
              onPinClick=@onPinClick
            )
          }}
        />
      {{/each}}
    </EuiListGroup>
  </template>
}
