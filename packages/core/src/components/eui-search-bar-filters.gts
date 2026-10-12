import Component from '@glimmer/component';

import EuiFilterGroup from './eui-filter-group.gts';
import FieldValueSelectionFilter from './eui-search-bar/field-value-selection-filter.gts';
import FieldValueToggleFilter from './eui-search-bar/field-value-toggle-filter.gts';
import FieldValueToggleGroupFilter from './eui-search-bar/field-value-toggle-group-filter.gts';
import IsFilter from './eui-search-bar/is-filter.gts';

import type {
  CustomComponentFilterConfigType,
  FieldValueSelectionFilterConfigType,
  FieldValueToggleFilterConfigType,
  FieldValueToggleGroupFilterConfigType,
  IsFilterConfigType,
  SearchFilterConfig
} from '../-private/search-bar.ts';
import type { Query } from '../utils/eui/search-bar/query.ts';

export type {
  CustomComponentProps,
  FieldValueOptionType,
  SearchFilterConfig
} from '../-private/search-bar.ts';

/**
 * The filter buttons of an `EuiSearchBar` in an `EuiFilterGroup`, built
 * from filter configs: `is` (flag toggle), `field_value_toggle`,
 * `field_value_toggle_group`, `field_value_selection` (popover list) and
 * `custom_component`. Each filter edits `@query` and calls `@onChange`
 * with the new `Query`.
 */
export interface EuiSearchBarFiltersSignature {
  Element: HTMLDivElement;
  Args: {
    /** The current query (a `Query`, exported by `components/eui-search-bar`). */
    query: Query;
    /** Called with the updated query when a filter changes. */
    onChange: (query: Query) => void;
    /** The filter configs. */
    filters?: SearchFilterConfig[];
    /** Shorter filter group. */
    compressed?: boolean;
  };
}

export default class EuiSearchBarFilters extends Component<EuiSearchBarFiltersSignature> {
  get filters(): SearchFilterConfig[] {
    return (this.args.filters ?? []).filter((config) => {
      if (!KNOWN_TYPES.has(config.type)) {
        throw new Error(`Unknown search filter type [${config.type}]`);
      }
      return !config.available || config.available();
    });
  }

  <template>
    <EuiFilterGroup @compressed={{@compressed}} ...attributes>
      {{#each this.filters as |config|}}
        {{#if (isType config "is")}}
          <IsFilter
            @config={{asIs config}}
            @query={{@query}}
            @onChange={{@onChange}}
          />
        {{else if (isType config "field_value_selection")}}
          <FieldValueSelectionFilter
            @config={{asSelection config}}
            @query={{@query}}
            @onChange={{@onChange}}
          />
        {{else if (isType config "field_value_toggle")}}
          <FieldValueToggleFilter
            @config={{asToggle config}}
            @query={{@query}}
            @onChange={{@onChange}}
          />
        {{else if (isType config "field_value_toggle_group")}}
          <FieldValueToggleGroupFilter
            @config={{asToggleGroup config}}
            @query={{@query}}
            @onChange={{@onChange}}
          />
        {{else}}
          {{#let (asCustom config) as |custom|}}
            <custom.component @query={{@query}} @onChange={{@onChange}} />
          {{/let}}
        {{/if}}
      {{/each}}
    </EuiFilterGroup>
  </template>
}

const KNOWN_TYPES = new Set<string>([
  'is',
  'field_value_selection',
  'field_value_toggle',
  'field_value_toggle_group',
  'custom_component'
]);

function isType(config: SearchFilterConfig, type: string): boolean {
  return config.type === type;
}

const asIs = (config: SearchFilterConfig) => config as IsFilterConfigType;
const asSelection = (config: SearchFilterConfig) =>
  config as FieldValueSelectionFilterConfigType;
const asToggle = (config: SearchFilterConfig) =>
  config as FieldValueToggleFilterConfigType;
const asToggleGroup = (config: SearchFilterConfig) =>
  config as FieldValueToggleGroupFilterConfigType;
const asCustom = (config: SearchFilterConfig) =>
  config as CustomComponentFilterConfigType;
