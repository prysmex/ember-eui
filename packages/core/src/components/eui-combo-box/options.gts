import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

//@ts-expect-error
import { VerticalCollection } from '@html-next/vertical-collection';
import EmberPowerSelectOptions from 'ember-power-select/components/power-select/options';
import emberPowerSelectIsGroup from 'ember-power-select/helpers/ember-power-select-is-group';
import { and, eq, not, or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  comboBoxBoxReset,
  comboBoxOptionLabel,
  isComboBoxOptionChecked
} from '../../utils/eui/combo-box.ts';
import {
  euiComboBoxOptionListStyles,
  euiListItemLayoutStyles
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiBadge from '../eui-badge.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiIcon from '../eui-icon.gts';
import EuiLoadingSpinner from '../eui-loading-spinner.gts';
import EuiText from '../eui-text.gts';
import EuiToolTip from '../eui-tool-tip.gts';
import EuiComboBoxNode from './node.gts';

import type { TOC } from '@ember/component/template-only';
import type { EuiTooltipArgs } from '../eui-tool-tip';

import type EuiConfigService from '../../services/eui-config';

/** Upstream `anchorClassName="eui-fullWidth"` of option tooltips. */
const TOOLTIP_ANCHOR_CSS = { inlineSize: '100%' };

/**
 * @private Upstream EuiListItemLayout's internal tooltip: wraps the row
 * content in an EuiToolTip when the option has `toolTipContent`, shown on
 * hover and while the option is highlighted (keyboard).
 */
const MaybeToolTip: TOC<{
  Args: {
    content?: string;
    props?: Partial<EuiTooltipArgs>;
    id: string;
    isShown: boolean;
  };
  Blocks: { default: [] };
}> = <template>
  {{#if @content}}
    <EuiToolTip
      @id={{@id}}
      @content={{@content}}
      @title={{@props.title}}
      @position={{@props.position}}
      @delay={{@props.delay}}
      @offset={{@props.offset}}
      @className={{@props.className}}
      @css={{@props.css}}
      @anchorClassName={{@props.anchorClassName}}
      @anchorCss={{TOOLTIP_ANCHOR_CSS}}
      @isShown={{@isShown}}
    >{{yield}}</EuiToolTip>
  {{else}}
    {{yield}}
  {{/if}}
</template>;

interface Row {
  /** ember-power-select's index path (`2`, `1.0`): option ids use it. */
  path: string;
  /** 1-based position among the options (not groups), for `aria-posinset`. */
  position: number;
}

/**
 * @private EuiComboBox's options list: virtualized, with groups. Extends
 * ember-power-select's options component. Rows follow upstream
 * EuiComboBoxOptionsList: `EuiListItemLayout` options (`role="option"`)
 * and `euiComboBoxTitle` group labels.
 */
export default class EuiComboBoxOptionsComponent extends EmberPowerSelectOptions {
  @service declare euiConfig: EuiConfigService;

  /**
   * Groups followed by their options, in one list (the rows of the
   * virtualized list; `data-option-index` is an index in it).
   */
  @cached
  get flattedOptions(): unknown[] {
    return this.flattened.items;
  }

  @cached
  get flattened(): { items: unknown[]; rows: Row[]; count: number } {
    const items: unknown[] = [];
    const rows: Row[] = [];
    let count = 0;

    (this.args.options ?? []).forEach((option: any, i: number) => {
      if (emberPowerSelectIsGroup(option)) {
        items.push(option);
        rows.push({ path: `${i}`, position: 0 });
        (option.options ?? []).forEach((child: unknown, j: number) => {
          items.push(child);
          rows.push({
            path: `${i}.${j}`,
            position: emberPowerSelectIsGroup(child) ? 0 : ++count
          });
        });
      } else {
        items.push(option);
        rows.push({ path: `${i}`, position: ++count });
      }
    });

    return { items, rows, count };
  }

  get hasGroups(): boolean {
    return this.flattened.rows.some((row) => row.position === 0);
  }

  /**
   * ember-power-select attaches its mouse/touch handlers to the first list
   * element only. Ours is replaced while `@search` loads (the list gives way
   * to the loading message), so the new list had no handlers and clicking an
   * option did nothing. Attach to every list element and detach on teardown.
   */
  setupHandlers = modifier((element: Element) => {
    // ember-power-select's handler methods are private in its types
    const base = this as unknown as {
      _listElement?: Element;
      _addHandlers(element: Element): void;
      _removeHandlers(element: Element): void;
    };

    base._listElement = element;
    base._addHandlers(element);

    return () => {
      base._removeHandlers(element);
      if (base._listElement === element) base._listElement = undefined;
    };
  });

  _optionFromIndex(index: string) {
    const parts = index.split('.');
    let option: any = this.flattedOptions[parseInt(parts[0]!, 10)];

    for (let i = 1; i < parts.length; i++) {
      option = option.options[parseInt(parts[i]!, 10)];
    }

    return option;
  }

  get configRowHeight() {
    return (
      (this.euiConfig.getConfig('euiComboBoxOptionsHeight') as number) || 29
    );
  }

  /** `@rowHeight="auto"`: rows wrap their text, nothing is virtualized. */
  get isAuto(): boolean {
    //@ts-expect-error `rowHeight` is curried by EuiComboBox
    return this.args.rowHeight === 'auto';
  }

  get rowHeight(): number {
    //@ts-expect-error `rowHeight` is curried by EuiComboBox
    const rowHeight = this.args.rowHeight as number | 'auto' | undefined;

    return rowHeight === 'auto' || rowHeight == null
      ? this.configRowHeight
      : rowHeight;
  }

  get rowHeightString() {
    return this.isAuto ? undefined : htmlSafe(`height:${this.rowHeight}px;`);
  }

  get staticHeight(): boolean {
    return !this.hasGroups && !this.isAuto;
  }

  get singleSelection(): boolean {
    //@ts-expect-error `singleSelection` is curried by EuiComboBox
    return Boolean(this.args.singleSelection);
  }

  /**
   * Single selection's check mark (upstream: same label and key). In
   * multiple selection the selected options are not listed.
   */
  isChecked = (option: unknown): boolean =>
    this.singleSelection &&
    isComboBoxOptionChecked(
      option,
      //@ts-expect-error `selectedOptions` is curried by EuiComboBox
      this.args.selectedOptions,
      //@ts-expect-error `searchField` is curried by EuiComboBox
      this.args.searchField
    );

  /** The list keeps the focus in the input (upstream). */
  keepFocus = (event: MouseEvent) => event.preventDefault();

  /** Upstream `aria-multiselectable` only for multiple selection. */
  get ariaMultiselectable(): 'true' | undefined {
    return this.singleSelection ? undefined : 'true';
  }

  /** Upstream `getListItemSize`: group labels after the first get 16px more. */
  groupStyle = (index: number) =>
    this.isAuto
      ? undefined
      : htmlSafe(
          `height:${index > 0 ? this.rowHeight + 16 : this.rowHeight}px;`
        );

  optionId = (index: number) =>
    `${(this.args.select as { uniqueId: string }).uniqueId}-${this.flattened.rows[index]?.path ?? index}`;

  position = (index: number) => this.flattened.rows[index]?.position;

  /**
   * Upstream text `title`: the option's own, else its label while it is
   * truncated by CSS (not searching, no `truncationProps`, no
   * `rowHeight="auto"`) and has no tooltip.
   */
  titleFor = (option: unknown) => {
    const record =
      option && typeof option === 'object'
        ? (option as {
            title?: string;
            truncationProps?: unknown;
            toolTipContent?: unknown;
          })
        : undefined;

    if (record && 'title' in record) {
      return record.title;
    }

    if (
      (this.args.select as { searchText?: string }).searchText ||
      //@ts-expect-error `truncationProps` is curried by EuiComboBox
      this.args.truncationProps ||
      record?.truncationProps ||
      record?.toolTipContent ||
      this.isAuto
    ) {
      return undefined;
    }

    //@ts-expect-error `searchField` is curried by EuiComboBox
    return comboBoxOptionLabel(option, this.args.searchField) || undefined;
  };

  /** Upstream: no tooltip on disabled options. */
  toolTipFor = (option: unknown): string | undefined => {
    if (this.isDisabled(option)) return undefined;

    return (option as { toolTipContent?: string } | undefined)
      ?.toolTipContent;
  };

  toolTipId = (index: number) => `${this.optionId(index)}-tooltip`;

  isDisabled = (option: unknown) =>
    Boolean(
      option &&
        typeof option === 'object' &&
        (option as { disabled?: boolean }).disabled === true
    );

  @cached
  get listStyles() {
    return useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiComboBoxOptionListStyles
    );
  }

  /**
   * The listbox: upstream `.euiComboBoxOptionsList` (max height 200px) and
   * its virtualized list (scrolls, with overflow shadows). Positioned so
   * option offsets (keyboard scrolling) are relative to it.
   */
  @cached
  get listClass(): string {
    const context = getEuiThemeContext(this);
    const styles = this.listStyles;

    return euiClass(
      context,
      comboBoxBoxReset,
      styles.euiComboBoxOptionList,
      this.isAuto
        ? styles.hasRowHeightAuto
        : styles.euiComboBoxOptionList__virtualization,
      { position: 'relative', outline: 'none' }
    );
  }

  /** Loading message: the same list wrapper around an upstream empty state. */
  @cached
  get emptyClass(): string {
    const context = getEuiThemeContext(this);
    const styles = this.listStyles;

    return euiClass(
      context,
      comboBoxBoxReset,
      styles.euiComboBoxOptionList,
      styles.euiComboBoxOptionsList__empty
    );
  }

  @cached
  get layoutStyles() {
    return useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiListItemLayoutStyles
    );
  }

  /**
   * Upstream EuiListItemLayout styles per state, composed once per theme
   * and state combination (interactive styles only while enabled).
   */
  @cached
  get optionClassFor(): (
    focused: boolean,
    selected: boolean,
    disabled: boolean
  ) => string {
    const context = getEuiThemeContext(this);
    const s = this.layoutStyles;
    const cache = new Map<string, string>();

    return (focused, selected, disabled) => {
      const key = `${focused}${selected}${disabled}`;
      let value = cache.get(key);

      if (!value) {
        value = euiClass(
          context,
          { boxSizing: 'border-box' },
          s.euiListItemLayout,
          ...(disabled
            ? []
            : [
                s.isInteractive,
                focused && s.isFocused,
                selected && s.isSelected,
                selected && focused && s.isSelectedFocused
              ]),
          disabled && s.isDisabled
        );
        cache.set(key, value);
      }

      return value;
    };
  }

  optionClass = (
    option: unknown,
    highlighted: unknown,
    selected: boolean
  ): string => {
    const disabled = this.isDisabled(option);

    return this.optionClassFor(option === highlighted, selected, disabled);
  };

  @cached
  get contentClass(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.layoutStyles.euiListItemLayout__content
    );
  }

  @cached
  get textClass(): string {
    const s = this.layoutStyles;

    return euiClass(
      getEuiThemeContext(this),
      s.euiListItemLayout__text,
      this.isAuto ? s.textWrap.wrap : s.textWrap.truncate
    );
  }

  @cached
  get prependClass(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.layoutStyles.euiListItemLayout__prepend
    );
  }

  @cached
  get appendClass(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.layoutStyles.euiListItemLayout__append
    );
  }

  /** Single selection check indicator (upstream `showIndicator`). */
  @cached
  get indicatorCss() {
    return this.layoutStyles.euiListItemLayout__icon;
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    {{#let (component @groupComponent) as |Group|}}
      {{#if (or @select.loading @isLoading)}}
        <div
          class="euiComboBoxOptionsList {{this.emptyClass}}"
          {{on "mousedown" this.keepFocus}}
        >
          <EuiText @size="xs" class="euiComboBoxOptionsList__empty">
            <EuiFlexGroup
              @gutterSize="s"
              @justifyContent="center"
              @responsive={{false}}
            >
              <EuiFlexItem @grow={{false}}>
                <EuiLoadingSpinner @size="m" />
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                {{@loadingMessage}}
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiText>
        </div>
      {{else}}
        {{! template-lint-disable }}
        <VerticalCollection
          @items={{this.flattedOptions}}
          @tagName="div"
          @estimateHeight={{this.rowHeight}}
          @staticHeight={{this.staticHeight}}
          @renderAll={{this.isAuto}}
          @bufferSize={{3}}
          role="listbox"
          data-combo-box-list={{@select.uniqueId}}
          data-test-subj="comboBoxOptionsList"
          class="euiComboBoxOptionsList euiComboBoxOptionsList__rowWrap euiComboBoxOptionsList__virtualization
            {{this.listClass}}
            {{@class}}"
          {{this.setupHandlers}}
          {{on "mousedown" this.keepFocus}}
          ...attributes
          aria-multiselectable={{this.ariaMultiselectable}}
          aria-label={{if @listboxAriaLabel @listboxAriaLabel}}
          as |opt index|
        >
          {{! template-lint-enable }}
          {{#if (emberPowerSelectIsGroup opt)}}
            <Group
              @group={{opt}}
              @select={{@select}}
              @extra={{@extra}}
              @isFirst={{eq index 0}}
              style={{this.groupStyle index}}
            />
          {{else}}
            {{#let
              (this.isChecked opt)
              (and
                @onFocusBadge
                (eq opt @select.highlighted)
                (not (this.isDisabled opt))
              )
              as |selected showEnter|
            }}
              <div
                id={{this.optionId index}}
                style={{this.rowHeightString}}
                class="euiComboBoxOption euiListItemLayout
                  {{this.optionClass opt @select.highlighted selected}}"
                aria-selected="{{selected}}"
                aria-disabled={{if (this.isDisabled opt) "true"}}
                aria-current="{{eq opt @select.highlighted}}"
                aria-setsize={{this.flattened.count}}
                aria-posinset={{this.position index}}
                aria-describedby={{if
                  (this.toolTipFor opt)
                  (this.toolTipId index)
                }}
                data-option-index="{{index}}"
                data-test-subj="euiListItemLayout"
                role="option"
              >
                <MaybeToolTip
                  @content={{this.toolTipFor opt}}
                  @props={{opt.toolTipProps}}
                  @id={{this.toolTipId index}}
                  @isShown={{eq opt @select.highlighted}}
                >
                <span
                  class="euiListItemLayout__content {{this.contentClass}}"
                >
                  {{#if this.singleSelection}}
                    <EuiIcon
                      class="euiListItemLayout__icon"
                      @type={{if selected "check" "empty"}}
                      @color={{if
                        (this.isDisabled opt)
                        "subdued"
                        (if selected "primary" "text")
                      }}
                      @css={{this.indicatorCss}}
                    />
                  {{/if}}
                  {{#if opt.prepend}}
                    <span
                      class="euiListItemLayout__prepend {{this.prependClass}}"
                    ><EuiComboBoxNode
                        @node={{opt.prepend}}
                        @option={{opt}}
                      /></span>
                  {{/if}}
                  <span
                    class="euiListItemLayout__text euiComboBoxOption__content
                      {{this.textClass}}"
                    title={{this.titleFor opt}}
                  >
                    {{yield opt index @select}}
                  </span>
                  {{#if (or opt.append showEnter)}}
                    <span
                      class="euiListItemLayout__append {{this.appendClass}}"
                    >
                      {{#if opt.append}}
                        <EuiComboBoxNode
                          @node={{opt.append}}
                          @option={{opt}}
                        />
                      {{/if}}
                      {{#if showEnter}}
                        {{!template-lint-disable require-presentational-children}}
                        <EuiBadge
                          class="euiComboBoxOption__enterBadge"
                          @color="hollow"
                          @iconType="return"
                          aria-hidden="true"
                        />
                      {{/if}}
                    </span>
                  {{/if}}
                </span>
                </MaybeToolTip>
              </div>
            {{/let}}
          {{/if}}
        </VerticalCollection>
      {{/if}}
    {{/let}}
  </template>
}
