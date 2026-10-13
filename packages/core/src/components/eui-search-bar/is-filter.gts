import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import { resolveToggleDisplay } from '../../-private/search-bar.ts';
import { Query } from '../../utils/eui/search-bar/query.ts';
import EuiFilterButton from '../eui-filter-button.gts';

import type { IsFilterConfigType } from '../../-private/search-bar.ts';

/**
 * @private An `is:flag` toggle of `EuiSearchBar` (upstream `IsFilter`):
 * adds `is:<field>` to the query, or removes the clause when it is there.
 */
export interface IsFilterSignature {
  Args: {
    config: IsFilterConfigType;
    query: Query;
    onChange: (query: Query) => void;
  };
}

export default class IsFilter extends Component<IsFilterSignature> {
  get clause() {
    return this.args.query.getIsClause(this.args.config.field);
  }

  get display() {
    const { name, negatedName } = this.args.config;
    return resolveToggleDisplay(this.clause, name, negatedName, Query.isMust);
  }

  onClick = (): void => {
    const { field } = this.args.config;
    const checked = this.clause != null;
    this.args.onChange(
      checked
        ? this.args.query.removeIsClause(field)
        : this.args.query.addMustIsClause(field)
    );
  };

  <template>
    <EuiFilterButton
      @isSelected={{this.display.hasActiveFilters}}
      @hasActiveFilters={{this.display.hasActiveFilters}}
      @isToggle={{true}}
      aria-pressed={{if this.display.hasActiveFilters "true" "false"}}
      {{on "click" this.onClick}}
    >{{this.display.name}}</EuiFilterButton>
  </template>
}
