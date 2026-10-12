import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiSearchBar__filtersHolder,
  euiSearchBar__searchHolder
} from '../utils/eui/styles.generated.ts';
import { AST } from '../utils/eui/search-bar/ast.ts';
import { Query } from '../utils/eui/search-bar/query.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiSearchBarFilters from './eui-search-bar-filters.gts';
import EuiSearchBox from './eui-search-bar/eui-search-box.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type Owner from '@ember/owner';
import type { SearchFilterConfig } from '../-private/search-bar.ts';
import type { EuiFlexGroupSignature } from './eui-flex-group.gts';
import type {
  EuiSearchBoxHint,
  EuiSearchBoxHintPopoverProps,
  EuiSearchBoxOptions
} from './eui-search-bar/eui-search-box.gts';

export { Query, AST as Ast };
export type {
  CustomComponentProps,
  FieldValueOptionType,
  SearchFilterConfig
} from '../-private/search-bar.ts';
export type {
  EuiSearchBoxOptions,
  EuiSearchBoxHintPopoverProps
} from './eui-search-bar/eui-search-box.gts';

export type QueryType = Query | string;

/** The query schema of `@box.schema`. */
export interface SchemaType {
  strict?: boolean;
  fields?: any;
  flags?: string[];
  /** Controls which phrases will be parsed as field clauses. */
  recognizedFields?: string[];
}

/** What `@onChange` receives: a parsed query, or the parse error. */
export type EuiSearchBarOnChangeArgs =
  | { query: Query; queryText: string; error: null }
  | { query: null; queryText: string; error: null }
  | { query: null; queryText: string; error: Error };

/** The hint below the search field (upstream `hint`). */
export interface EuiSearchBarHint {
  /** Text of the hint; use the `<:hint>` block for markup. */
  content?: string;
  /** Popover options; `isOpen` + `closePopover` control it yourself. */
  popoverProps?: EuiSearchBoxHintPopoverProps;
}

/**
 * A search field parsing an EQL-like query (`text field:value is:flag
 * -excluded (a or b)`) into a `Query`, with optional filter buttons and
 * tools around it.
 */
export interface EuiSearchBarSignature {
  Element: EuiFlexGroupSignature['Element'];
  Args: {
    /**
     * Called with `{ query, queryText, error }` when the query text or
     * its parse error changes.
     */
    onChange?: (args: EuiSearchBarOnChangeArgs) => void | boolean;
    /** The initial query (a `Query` or text). */
    defaultQuery?: QueryType;
    /**
     * Controlled query: when its text differs from the bar's, the bar
     * resets to it.
     */
    query?: QueryType;
    /**
     * The search field: `{ placeholder, incremental, schema, isClearable,
     * isLoading, compressed, fullWidth, 'aria-label', 'data-test-subj', … }`.
     */
    box?: EuiSearchBoxOptions;
    /** The filter configs, rendered in an `EuiFilterGroup`. */
    filters?: SearchFilterConfig[];
    /** Date format used to parse date values (upstream `dateFormat`). */
    dateFormat?: object;
    /** A hint shown below the field while it has focus. */
    hint?: EuiSearchBarHint;
    /** Shorter field and filters. */
    compressed?: boolean;
    /**
     * Shows a tooltip with the parse error of an invalid query. With
     * `false`, surface and announce parse errors yourself. Defaults to
     * `true`.
     */
    showErrorTooltip?: boolean;
    /** @private Whether the caller's `<:toolsLeft>` block exists (when forwarding it). */
    hasToolsLeftBlock?: boolean;
    /** @private Whether the caller's `<:toolsRight>` block exists (when forwarding it). */
    hasToolsRightBlock?: boolean;
    /** @private Whether the caller's `<:hint>` block exists (when forwarding it). */
    hasHintBlock?: boolean;
  };
  Blocks: {
    /** Tools left of the field (in a non-growing flex item). */
    toolsLeft: [];
    /** Tools right of the filters (in a non-growing flex item). */
    toolsRight: [];
    /** The hint's content (instead of `@hint.content`). */
    hint: [];
  };
}

interface State {
  query: Query;
  queryText: string;
  error: null | Error;
}

type NotifyControllingParent = Pick<State, 'queryText' | 'error'> & {
  query: Query | null;
};

function notifyControllingParent(
  oldState: NotifyControllingParent,
  newState: NotifyControllingParent,
  onChange?: EuiSearchBarSignature['Args']['onChange']
): void {
  if (!onChange) {
    return;
  }
  const { query, queryText, error } = newState;

  const isQueryDifferent = oldState.queryText !== queryText;

  const oldError = oldState.error ? oldState.error.message : null;
  const newError = error ? error.message : null;
  const isErrorDifferent = oldError !== newError;

  if (isQueryDifferent || isErrorDifferent) {
    if (error == null) {
      onChange({ query: query!, queryText, error });
    } else {
      onChange({ query: null, queryText, error });
    }
  }
}

export default class EuiSearchBar extends Component<EuiSearchBarSignature> {
  static Query = Query;

  hintId = `__hint${randomId()}`;

  /** Upstream state; `stateVersion` makes reads of it tracked. */
  private _state: State;
  private prevArgsQuery: QueryType | undefined;
  @tracked private stateVersion = 0;
  @tracked isHintVisibleState = false;

  constructor(owner: Owner, args: EuiSearchBarSignature['Args']) {
    super(owner, args);
    const query = this.parseQuery(args.defaultQuery || args.query);
    this._state = { query, queryText: query.text, error: null };
    this.prevArgsQuery = args.query;
  }

  parseQuery(query: QueryType | undefined): Query {
    const { box, dateFormat } = this.args;
    let schema: SchemaType | undefined = undefined;
    if (box?.schema && typeof box.schema === 'object') {
      schema = box.schema as SchemaType;
    }
    const parseOptions = { schema, dateFormat };
    if (!query) {
      return Query.parse('', parseOptions);
    }
    return typeof query === 'string' ? Query.parse(query, parseOptions) : query;
  }

  /**
   * Upstream derives the state from a changed `query` prop while
   * rendering (`getDerivedStateFromProps`-like); the untracked fields it
   * updates are only read through this getter.
   */
  get state(): State {
    void this.stateVersion;
    this.deriveStateFromArgs(this.args.query);
    return this._state;
  }

  private deriveStateFromArgs(nextQuery: QueryType | undefined): void {
    if (nextQuery === this.prevArgsQuery) return;
    const prevQuery = this._state.query;
    const shouldUpdate =
      (nextQuery || nextQuery === '') &&
      ((typeof nextQuery !== 'string' && nextQuery.text !== prevQuery.text) ||
        (typeof nextQuery === 'string' && nextQuery !== prevQuery.text));
    if (shouldUpdate) {
      this.prevArgsQuery = nextQuery;
      const parsed = this.parseQuery(nextQuery);
      this._state = { query: parsed, queryText: parsed.text, error: null };
    }
  }

  setState(state: State): void {
    this._state = state;
    this.stateVersion++;
  }

  @action
  onSearch(newQueryText: string): void {
    const oldState: NotifyControllingParent = { ...this.state };
    try {
      const newQuery = this.parseQuery(newQueryText);
      notifyControllingParent(
        oldState,
        { query: newQuery, queryText: newQueryText, error: null },
        this.args.onChange
      );
      this.setState({ query: newQuery, queryText: newQuery.text, error: null });
    } catch (e) {
      const error: Error =
        e instanceof Error
          ? { name: e.name, message: e.message }
          : { name: 'Unexpected error', message: String(e) };
      notifyControllingParent(
        oldState,
        { query: null, queryText: newQueryText, error },
        this.args.onChange
      );
      this.setState({ query: this.state.query, queryText: newQueryText, error });
    }
  }

  @action
  onFiltersChange(newQuery: Query): void {
    notifyControllingParent(
      { ...this.state },
      { query: newQuery, queryText: newQuery.text, error: null },
      this.args.onChange
    );
    this.setState({ query: newQuery, queryText: newQuery.text, error: null });
  }

  get showErrorTooltip(): boolean {
    return this.args.showErrorTooltip ?? true;
  }

  get isHintVisible(): boolean {
    return this.args.hint?.popoverProps?.isOpen ?? this.isHintVisibleState;
  }

  get describedBy(): string | undefined {
    const ids = [
      this.args.box?.['aria-describedby'],
      this.args.hint ? (this.isHintVisible ? this.hintId : undefined) : undefined
    ]
      .filter(Boolean)
      .join(' ');
    return ids || undefined;
  }

  setIsHintVisible = (isVisible: boolean): void => {
    this.isHintVisibleState = isVisible;
  };

  get hint(): EuiSearchBoxHint | undefined {
    const { hint } = this.args;
    if (!hint) return undefined;
    return {
      id: this.hintId,
      isVisible: this.isHintVisible,
      setIsVisible: this.setIsHintVisible,
      popoverProps: hint.popoverProps
    };
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    return {
      searchHolder: useEuiBorealisStyles(context, euiSearchBar__searchHolder),
      filtersHolder: useEuiBorealisStyles(context, euiSearchBar__filtersHolder)
    };
  }

  <template>
    <EuiFlexGroup
      @gutterSize="s"
      @alignItems="center"
      @wrap={{true}}
      ...attributes
    >
      {{#if (flag @hasToolsLeftBlock (has-block "toolsLeft"))}}
        <EuiFlexItem @grow={{false}}>{{yield to="toolsLeft"}}</EuiFlexItem>
      {{/if}}
      <EuiFlexItem
        class="euiSearchBar__searchHolder"
        @css={{this.styles.searchHolder}}
        @grow={{true}}
      >
        {{#if this.showErrorTooltip}}
          <EuiToolTip @content={{this.state.error.message}} @display="block">
            <EuiSearchBox
              @compressed={{@compressed}}
              @box={{@box}}
              @query={{this.state.queryText}}
              @onSearch={{this.onSearch}}
              @isInvalid={{if this.state.error true false}}
              @ariaDescribedBy={{this.describedBy}}
              @hint={{this.hint}}
            >
              <:hint>
                {{#if (flag @hasHintBlock (has-block "hint"))}}{{yield to="hint"}}{{else}}{{@hint.content}}{{/if}}
              </:hint>
            </EuiSearchBox>
          </EuiToolTip>
        {{else}}
          <EuiSearchBox
            @compressed={{@compressed}}
            @box={{@box}}
            @query={{this.state.queryText}}
            @onSearch={{this.onSearch}}
            @isInvalid={{if this.state.error true false}}
            @ariaDescribedBy={{this.describedBy}}
            @hint={{this.hint}}
          >
            <:hint>
              {{#if (flag @hasHintBlock (has-block "hint"))}}{{yield to="hint"}}{{else}}{{@hint.content}}{{/if}}
            </:hint>
          </EuiSearchBox>
        {{/if}}
      </EuiFlexItem>
      {{#if @filters}}
        <EuiFlexItem
          class="euiSearchBar__filtersHolder"
          @css={{this.styles.filtersHolder}}
          @grow={{false}}
        >
          <EuiSearchBarFilters
            @filters={{@filters}}
            @query={{this.state.query}}
            @onChange={{this.onFiltersChange}}
            @compressed={{@compressed}}
          />
        </EuiFlexItem>
      {{/if}}
      {{#if (flag @hasToolsRightBlock (has-block "toolsRight"))}}
        <EuiFlexItem @grow={{false}}>{{yield to="toolsRight"}}</EuiFlexItem>
      {{/if}}
    </EuiFlexGroup>
  </template>
}

/** A forwarded block flag, or this component's own `has-block`. */
function flag(forwarded: boolean | undefined, own: boolean): boolean {
  return forwarded ?? own;
}
