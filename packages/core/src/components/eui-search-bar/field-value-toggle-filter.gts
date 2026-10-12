import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import { resolveToggleDisplay } from '../../-private/search-bar.ts';
import { Query } from '../../utils/eui/search-bar/query.ts';
import EuiFilterButton from '../eui-filter-button.gts';

import type { FieldValueToggleFilterConfigType } from '../../-private/search-bar.ts';

/**
 * @private A `field:value` toggle of `EuiSearchBar` (upstream
 * `FieldValueToggleFilter`).
 */
export interface FieldValueToggleFilterSignature {
  Args: {
    config: FieldValueToggleFilterConfigType;
    query: Query;
    onChange: (query: Query) => void;
  };
}

export default class FieldValueToggleFilter extends Component<FieldValueToggleFilterSignature> {
  get clause() {
    const { field, value } = this.args.config;
    return this.args.query.getSimpleFieldClause(field, value);
  }

  get display() {
    const { name, negatedName } = this.args.config;
    return resolveToggleDisplay(this.clause, name, negatedName, Query.isMust);
  }

  onClick = (): void => {
    const { field, value, operator } = this.args.config;
    const checked = this.clause != null;
    this.args.onChange(
      checked
        ? this.args.query.removeSimpleFieldValue(field, value)
        : this.args.query.addSimpleFieldValue(field, value, true, operator)
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
