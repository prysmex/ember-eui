import Component from '@glimmer/component';

import { isCustomItemAction } from '../../-private/basic-table.ts';
import DefaultItemAction from './default-item-action.gts';

import type {
  Action,
  CustomItemAction,
  DefaultItemAction as DefaultAction,
  ItemIdResolved
} from '../../-private/basic-table.ts';

/**
 * @private The inline row actions of `EuiBasicTable` (upstream
 * `ExpandedItemActions`).
 */
export interface ExpandedItemActionsSignature<T extends object> {
  Args: {
    actions: Array<Action<T>>;
    itemId: ItemIdResolved;
    item: T;
    actionsDisabled: boolean;
  };
}

interface Tool<T extends object> {
  custom?: CustomItemAction<T>;
  action?: DefaultAction<T>;
  enabled: boolean;
  className?: string;
}

export default class ExpandedItemActions<T extends object> extends Component<
  ExpandedItemActionsSignature<T>
> {
  get tools(): Tool<T>[] {
    const { actions, item, actionsDisabled } = this.args;
    return actions.reduce<Tool<T>[]>((tools, action) => {
      const available = action.available ? action.available(item) : true;
      if (!available) return tools;
      const enabled = action.enabled == null || action.enabled(item);
      const className = action.showOnHover
        ? 'euiBasicTableAction-showOnHover'
        : undefined;
      if (isCustomItemAction<T>(action)) {
        tools.push({ custom: action, enabled: enabled && !actionsDisabled, className });
      } else {
        tools.push({ action, enabled: enabled && !actionsDisabled, className });
      }
      return tools;
    }, []);
  }

  <template>
    {{#each this.tools as |tool|}}
      {{#if tool.custom}}
        <div class={{tool.className}}>
          <tool.custom.component @item={{@item}} @enabled={{tool.enabled}} />
        </div>
      {{else if tool.action}}
        <DefaultItemAction
          class={{tool.className}}
          @action={{tool.action}}
          @enabled={{tool.enabled}}
          @item={{@item}}
        />
      {{/if}}
    {{/each}}
  </template>
}
