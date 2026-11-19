/**
 * The row menu (V02-DESIGN.md 5.5): an `EuiContextMenuPanel` in an
 * `EuiPanel`, positioned in the sheet's wrapper at the pointer (or under
 * the cell), like the editor frame. The panel moves focus to the first
 * item and handles ArrowUp/Down and Enter; the sheet handles Escape and
 * clicks outside.
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import EuiContextMenuItem from '@ember-eui/core/components/eui-context-menu-item';
import EuiContextMenuPanel from '@ember-eui/core/components/eui-context-menu-panel';
import EuiPanel from '@ember-eui/core/components/eui-panel';

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
    top: number;
    left: number;
    items: RowMenuItem[];
    onSelect: (item: RowMenuItem) => void;
  };
}

export default class RowMenu extends Component<RowMenuSignature> {
  get style() {
    return htmlSafe(`top:${this.args.top}px;left:${this.args.left}px;`);
  }

  select = (item: RowMenuItem): void => {
    if (!item.disabled) this.args.onSelect(item);
  };

  <template>
    <div
      class="euiSheet__menu"
      data-test-subj="euiSheetRowMenu"
      data-eui-sheet-menu
      style={{this.style}}
    >
      <EuiPanel @paddingSize="none" @hasShadow={{true}}>
        <EuiContextMenuPanel @hasFocus={{true}} @initialFocusedItemIndex={{0}}>
          {{#each @items as |item|}}
            <EuiContextMenuItem
              @icon={{item.icon}}
              @color={{item.color}}
              @disabled={{item.disabled}}
              @size="s"
              data-test-subj="euiSheetRowMenu-{{item.id}}"
              {{on "click" (fn this.select item)}}
            >{{item.label}}</EuiContextMenuItem>
          {{/each}}
        </EuiContextMenuPanel>
      </EuiPanel>
    </div>
  </template>
}
