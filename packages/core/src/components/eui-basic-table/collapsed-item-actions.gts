import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import {
  callWithItemIfFunction,
  isCustomItemAction
} from '../../-private/basic-table.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiContextMenuItem from '../eui-context-menu-item.gts';
import EuiContextMenuPanel from '../eui-context-menu-panel.gts';
import EuiPopover from '../eui-popover.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type {
  Action,
  CustomItemAction,
  DefaultItemAction,
  ItemIdResolved
} from '../../-private/basic-table.ts';
import type EuiI18n from '../../services/eui-i18n';

/**
 * @private The "All actions" menu of an `EuiBasicTable` row with more than
 * two actions (upstream `CollapsedItemActions`).
 */
export interface CollapsedItemActionsSignature<T extends object> {
  Args: {
    actions: Array<Action<T>>;
    item: T;
    itemId: ItemIdResolved;
    actionsDisabled: boolean;
    displayedRowIndex: number;
  };
}

interface Control<T extends object> {
  custom?: CustomItemAction<T>;
  action?: DefaultItemAction<T>;
  enabled: boolean;
  icon?: string;
  name?: string;
  description?: string;
  href?: string;
  testSubj?: string;
  color?: string;
}

export default class CollapsedItemActions<T extends object> extends Component<
  CollapsedItemActionsSignature<T>
> {
  @service declare euiI18n: EuiI18n;

  @tracked popoverOpen = false;

  get allActionsTooltip(): string {
    return this.euiI18n.lookupToken(
      'euiCollapsedItemActions.allActionsTooltip',
      'All actions'
    );
  }

  get buttonLabel(): string {
    return this.args.actionsDisabled
      ? this.disabledLabel
      : this.euiI18n.lookupToken(
          'euiCollapsedItemActions.allActions',
          'All actions, row {index}',
          { index: this.args.displayedRowIndex + 1 }
        );
  }

  get disabledLabel(): string {
    return this.euiI18n.lookupToken(
      'euiCollapsedItemActions.allActionsDisabled',
      'Individual item actions are disabled when rows are being selected.'
    );
  }

  get controls(): Control<T>[] {
    const { actions, item } = this.args;
    const call = callWithItemIfFunction(item);
    return actions.reduce<Control<T>[]>((controls, action) => {
      const available = action.available?.(item) ?? true;
      if (!available) return controls;
      const enabled = action.enabled == null || action.enabled(item);
      if (isCustomItemAction<T>(action)) {
        controls.push({ custom: action, enabled });
      } else {
        controls.push({
          action,
          enabled,
          icon: action.icon ? call(action.icon) : undefined,
          name: call(action.name),
          description: call(action.description),
          href: call(action.href),
          testSubj: call(action['data-test-subj']),
          color: action.color ? call(action.color) : undefined
        });
      }
      return controls;
    }, []);
  }

  @action
  toggle(): void {
    this.popoverOpen = !this.popoverOpen;
  }

  @action
  closePopover(): void {
    this.popoverOpen = false;
  }

  @action
  onItemClick(control: Control<T>, event: MouseEvent): void {
    control.action?.onClick?.(this.args.item, event);
    // Allow consumer events to prevent the popover from closing if necessary
    if (!event.cancelBubble) this.closePopover();
  }

  <template>
    <EuiPopover
      class="euiBasicTable__collapsedActions"
      id="{{@itemId}}-actions"
      @isOpen={{this.popoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="leftCenter"
    >
      <:button>
        <EuiToolTip
          @content={{if @actionsDisabled this.disabledLabel this.allActionsTooltip}}
          @disableScreenReaderOutput={{true}}
        >
          <EuiButtonIcon
            class="euiBasicTable__collapsedActions"
            aria-label={{this.buttonLabel}}
            @iconType="ellipsis"
            @color="text"
            @isDisabled={{@actionsDisabled}}
            data-test-subj="euiCollapsedItemActionsButton"
            {{on "click" this.toggle}}
          />
        </EuiToolTip>
      </:button>
      <:content>
        <EuiContextMenuPanel class="euiBasicTable__collapsedActions">
          {{#each this.controls as |control|}}
            {{#if control.custom}}
              {{! a <div>, so the custom control is not nested in a button }}
              <div class="euiBasicTable__collapsedCustomAction">
                {{! template-lint-disable no-invalid-interactive }}
                <span {{on "click" this.closePopover}}>
                  <control.custom.component @item={{@item}} @enabled={{control.enabled}} />
                </span>
              </div>
            {{else}}
              <EuiContextMenuItem
                class="euiBasicTable__collapsedAction"
                @disabled={{isDisabled control.enabled @actionsDisabled}}
                @href={{control.href}}
                @target={{control.action.target}}
                @icon={{control.icon}}
                @color={{control.color}}
                @toolTipContent={{if (same control.name control.description) undefined control.description}}
                data-test-subj={{control.testSubj}}
                {{on "click" (fn this.onItemClick control)}}
              >{{control.name}}</EuiContextMenuItem>
            {{/if}}
          {{/each}}
        </EuiContextMenuPanel>
      </:content>
    </EuiPopover>
  </template>
}

function isDisabled(enabled: boolean, actionsDisabled: boolean): boolean {
  return !enabled && !actionsDisabled;
}

function same(a: unknown, b: unknown): boolean {
  return a === b;
}
