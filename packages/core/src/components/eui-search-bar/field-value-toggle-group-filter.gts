import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { Query } from '../../utils/eui/search-bar/query.ts';
import EuiFilterButton from '../eui-filter-button.gts';

import type {
  FieldValueToggleGroupFilterConfigType,
  FieldValueToggleGroupFilterItemType
} from '../../-private/search-bar.ts';

/**
 * @private Joined `field:value` toggles of `EuiSearchBar`, at most one on
 * (upstream `FieldValueToggleGroupFilter`).
 */
export interface FieldValueToggleGroupFilterSignature {
  Args: {
    config: FieldValueToggleGroupFilterConfigType;
    query: Query;
    onChange: (query: Query) => void;
  };
}

interface ToggleItem {
  item: FieldValueToggleGroupFilterItemType;
  active: boolean;
  name: string;
  isLast: boolean;
}

export default class FieldValueToggleGroupFilter extends Component<FieldValueToggleGroupFilterSignature> {
  get items(): ToggleItem[] {
    const { config, query } = this.args;
    return config.items.map((item, index) => {
      const clause = query.getSimpleFieldClause(config.field, item.value);
      let active = false;
      let name = item.name;
      if (clause) {
        active = true;
        if (!Query.isMust(clause)) {
          name = item.negatedName ? item.negatedName : `Not ${item.name}`;
        }
      }
      return { item, active, name, isLast: index === config.items.length - 1 };
    });
  }

  onClick = ({ item, active }: ToggleItem): void => {
    const { field } = this.args.config;
    const { value, operator } = item;
    this.args.onChange(
      active
        ? this.args.query.removeSimpleFieldClauses(field)
        : this.args.query
            .removeSimpleFieldClauses(field)
            .addSimpleFieldValue(field, value, true, operator)
    );
  };

  <template>
    {{#each this.items as |toggle|}}
      <EuiFilterButton
        @isSelected={{toggle.active}}
        @hasActiveFilters={{toggle.active}}
        @withNext={{if toggle.isLast false true}}
        @isToggle={{true}}
        aria-pressed={{if toggle.active "true" "false"}}
        {{on "click" (fn this.onClick toggle)}}
      >{{toggle.name}}</EuiFilterButton>
    {{/each}}
  </template>
}
