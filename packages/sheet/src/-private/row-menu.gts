/**
 * The row menu (V02-DESIGN.md 5.5): an `EuiContextMenuPanel` in an
 * `EuiPanel`, at the pointer (or under the cell), in the sheet's layer
 * (portaled, `layer.gts`): below its anchor, above it when there is no
 * room below in the viewport, scrolling when neither side has room. The
 * panel moves focus to the first item and handles ArrowUp/Down and Enter;
 * the sheet handles Escape and clicks outside.
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import EuiContextMenuItem from '@ember-eui/core/components/eui-context-menu-item';
import EuiContextMenuPanel from '@ember-eui/core/components/eui-context-menu-panel';
import EuiPanel from '@ember-eui/core/components/eui-panel';

import SheetLayer, { placeLayer } from './layer.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { LayerAnchor } from './layer.gts';

/** One item of the menu, built by the sheet. */
export interface RowMenuItem {
  id: string;
  label: string;
  icon?: string;
  color?: 'danger';
  disabled?: boolean;
  onSelect: () => void;
}

interface RowMenuSignature {
  Args: {
    sheet: EuiSheet<any>;
    /** The pointer (a point) or the cell, in the viewport, now. */
    anchor: () => LayerAnchor | null;
    items: RowMenuItem[];
    onSelect: (item: RowMenuItem) => void;
  };
}

const GROUPS: Readonly<Record<string, number>> = {
  insertAbove: 0,
  insertBelow: 0,
  duplicate: 1,
  expand: 1,
  openLink: 1,
  copy: 2,
  copyWithNames: 2,
  delete: 4
};

/**
 * Names the menu (the panel's list, `@isMenu`): the panel labels it only by
 * a title, which this menu has none of. A named menu is also what axe's
 * `region` rule takes as a part of its own, not loose page content.
 */
const nameMenu = modifier((element: HTMLElement, [label]: [string]) => {
  element.querySelector('[role=menu]')?.setAttribute('aria-label', label);
});

/** The sheet's items by group; the app's `@rowActions` go together, before Delete. */
function groupOf(id: string): number {
  return GROUPS[id] ?? 3;
}

export default class RowMenu extends Component<RowMenuSignature> {
  /** A line before the item that starts a group (V03 batch 1): insert | duplicate, expand, open | copy, your actions | delete. */
  startsGroup = (index: number): boolean => {
    if (index === 0) return false;
    const items = this.args.items;
    return groupOf(items[index]!.id) !== groupOf(items[index - 1]!.id);
  };

  get label(): string {
    return this.args.sheet.messages.rowMenu();
  }

  select = (item: RowMenuItem): void => {
    if (!item.disabled) this.args.onSelect(item);
  };

  <template>
    <SheetLayer @sheet={{@sheet}}>
      <div
        class="euiSheet__menu"
        data-test-subj="euiSheetRowMenu"
        {{nameMenu this.label}}
        data-eui-sheet-menu
        {{placeLayer
          anchor=@anchor
          wrapper=@sheet.wrapper
          scroller=".euiSheet__menuPanel"
        }}
      >
        <EuiPanel
          @paddingSize="none"
          @hasShadow={{true}}
          class="euiSheet__menuPanel"
        >
          {{! a menu of menuitems: the panel's list is the menu (the
            panel itself is focusable, so not inside it); the panel's
            ArrowUp/Down and Enter, the sheet's Escape }}
          <EuiContextMenuPanel
            @isMenu={{true}}
            @hasFocus={{true}}
            @initialFocusedItemIndex={{0}}
          >
            {{#each @items as |item index|}}
              {{#if (this.startsGroup index)}}
                <hr class="euiSheet__menuSeparator" role="separator" />
              {{/if}}
              <EuiContextMenuItem
                @icon={{item.icon}}
                @color={{item.color}}
                @disabled={{item.disabled}}
                @size="s"
                role="menuitem"
                data-test-subj="euiSheetRowMenu-{{item.id}}"
                {{on "click" (fn this.select item)}}
              >{{item.label}}</EuiContextMenuItem>
            {{/each}}
          </EuiContextMenuPanel>
        </EuiPanel>
      </div>
    </SheetLayer>
  </template>
}
