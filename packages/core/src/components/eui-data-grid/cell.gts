import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { schedule } from '@ember/runloop';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

import { focusTrap } from 'ember-focus-trap';
import { modifier } from 'ember-modifier';
import { eq } from 'ember-truth-helpers';

import { afterRender, observeResize } from '../../utils/data-grid/scheduling.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiDataGridCellPopoverStyles,
  euiDataGridFooterStyles,
  euiDataGridRowCellStyles,
  euiTextBreakWord,
  euiTextTruncate
} from '../../utils/eui/styles.generated.ts';
import { euiTextBlockTruncateStyles } from '../../utils/eui/text-truncate.ts';
import {
  disableInteractives,
  enableAndFocusInteractives
} from '../../utils/data-grid/focus.ts';
import * as keys from '../../utils/keys.ts';
import EuiCodeBlock from '../eui-code-block.gts';
import EuiLiveAnnouncer from '../eui-live-announcer.gts';
import EuiPopover from '../eui-popover.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiText from '../eui-text.gts';
import {
  EuiDataGridCellActions,
  EuiDataGridCellPopoverActions
} from './cell-actions.gts';

import type Owner from '@ember/owner';
import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridSignature } from '../eui-data-grid.gts';
import type EuiDataGridBodyBase from './body-base.ts';
import type { ComponentLike } from '@glint/template';
import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridCellValueSignature,
  EuiDataGridColumn,
  EuiDataGridControlColumn,
  EuiDataGridSetCellProps
} from '../../utils/data-grid/types.ts';
import type { RowHeightType } from '../../utils/data-grid/row-heights.ts';

const concatClass = (...classes: unknown[]): string =>
  classes.filter((value) => typeof value === 'string' && value).join(' ');

const TEXT_TRUNCATE = euiTextTruncate();
const TEXT_BREAK_WORD = euiTextBreakWord();
const { euiTextBlockTruncate } = euiTextBlockTruncateStyles;

export interface EuiDataGridCellSignature {
  Element: HTMLDivElement;
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridBodyBase<any>;
    colIndex: number;
    visibleRowIndex: number;
    /** Footer cells sit in the flex footer row instead of being positioned. */
    isFooter?: boolean;
    hasCellPopoverBlock?: boolean;
    /** Custom grid body overrides (upstream's `Cell` props). */
    isExpandable?: boolean;
    renderCellValue?: ComponentLike<EuiDataGridCellValueSignature>;
  };
  Blocks: Pick<
    EuiDataGridSignature['Blocks'],
    'cell' | 'cellPopover' | 'controlCell' | 'footerCell' | 'controlFooterCell'
  >;
}

function shallowEqual(
  a: Record<string, unknown>,
  b: Record<string, unknown>
): boolean {
  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  if (aKeys.length !== bKeys.length) return false;
  for (const key of aKeys) {
    const aValue = a[key];
    const bValue = b[key];
    if (aValue === bValue) continue;
    if (
      key === 'style' &&
      typeof aValue === 'object' &&
      typeof bValue === 'object' &&
      aValue &&
      bValue &&
      shallowEqual(aValue as Record<string, unknown>, bValue as Record<string, unknown>)
    )
      continue;
    return false;
  }
  return true;
}

const toKebab = (property: string) =>
  property.startsWith('--')
    ? property
    : property.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`);

const UNITLESS = new Set(['opacity', 'z-index', 'flex-grow', 'flex-shrink', 'line-height', 'font-weight', 'order']);

function styleString(style?: Record<string, string | number | undefined>): string {
  if (!style) return '';
  return Object.entries(style)
    .filter(([, value]) => value != null && value !== '')
    .map(([key, value]) => {
      const property = toKebab(key);
      const cssValue =
        typeof value === 'number' && !UNITLESS.has(property) ? `${value}px` : String(value);
      return `${property}:${cssValue}`;
    })
    .join(';');
}

/**
 * A grid cell (`role=gridcell`): data, control and footer cells. Port of
 * upstream `EuiDataGridCell` + `CellWrapper` + `HandleInteractiveChildren`.
 */
export default class EuiDataGridCell extends Component<EuiDataGridCellSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isFocused = false;
  @tracked isHovered = false;
  @tracked hasInteractiveChildren = false;
  @tracked isCellEntered = false;
  @tracked isExited = false;

  cellElement: HTMLElement | null = null;
  contentElement: HTMLElement | null = null;
  readonly focusTrapHintId = `euiDataGridCell-${guidFor(this)}-focusTrapHint`;

  constructor(owner: Owner, args: EuiDataGridCellSignature['Args']) {
    super(owner, args);
    // Account for virtualization: a cell scrolled back into view keeps focus
    this.isFocused = args.grid.isFocusedCell(args.colIndex, args.visibleRowIndex);
  }

  /** Subscribes to focus changes of this cell's location (re-run if it moves). */
  registerFocus = modifier((_element: HTMLElement, [colIndex, visibleRowIndex]: [number, number]) => {
    const { grid } = this.args;
    afterRender(this, () => {
      const isFocused = grid.isFocusedCell(colIndex, visibleRowIndex);
      if (isFocused !== this.isFocused) this.isFocused = isFocused;
    });
    return grid.onFocusUpdate([colIndex, visibleRowIndex], this.onFocusUpdate);
  });

  willDestroy(): void {
    super.willDestroy();
    const { grid, colIndex, visibleRowIndex } = this.args;
    if (grid.isFocusedCell(colIndex, visibleRowIndex)) grid.setIsFocusedCellInView(false);
    if (this.isPopoverOpen) grid.closeCellPopover();
  }

  get grid(): EuiDataGrid {
    return this.args.grid;
  }

  /* -------------------------------------------------------------------- */
  /* Column                                                               */
  /* -------------------------------------------------------------------- */

  get leadingCount(): number {
    return this.grid.leadingControlColumns.length;
  }

  get isLeadingControlColumn(): boolean {
    return this.args.colIndex < this.leadingCount;
  }

  get isTrailingControlColumn(): boolean {
    return this.args.colIndex >= this.leadingCount + this.grid.columns.length;
  }

  get isControlColumn(): boolean {
    return this.isLeadingControlColumn || this.isTrailingControlColumn;
  }

  get controlColumn(): EuiDataGridControlColumn | undefined {
    const { colIndex } = this.args;
    if (this.isLeadingControlColumn) return this.grid.leadingControlColumns[colIndex];
    if (this.isTrailingControlColumn)
      return this.grid.trailingControlColumns[
        colIndex - this.leadingCount - this.grid.columns.length
      ];
    return undefined;
  }

  get column(): EuiDataGridColumn | undefined {
    if (this.isControlColumn) return undefined;
    return this.grid.columns[this.args.colIndex - this.leadingCount];
  }

  get columnId(): string {
    return this.controlColumn?.id ?? this.column?.id ?? '';
  }

  get columnType(): string | null {
    if (this.isControlColumn) return null;
    return this.grid.schema[this.columnId]?.columnType ?? null;
  }

  get textTransform(): string | undefined {
    const column = this.column;
    if (!column && !this.isControlColumn) return undefined;
    const columnId = this.columnId;
    return this.grid.schemaDetectors.find((detector) =>
      column?.schema ? column.schema === detector.type : columnId === detector.type
    )?.textTransform;
  }

  get rowIndex(): number {
    if (this.args.isFooter) return this.args.visibleRowIndex;
    return this.grid.getCorrectRowIndex(this.args.visibleRowIndex);
  }

  get width(): number | undefined {
    const control = this.controlColumn;
    if (control) return control.width;
    return this.args.body.widthForColumn(this.columnId);
  }

  get isFirstColumn(): boolean {
    return this.args.colIndex === 0;
  }

  get isLastColumn(): boolean {
    return this.args.colIndex === this.grid.visibleColCount - 1;
  }

  /* -------------------------------------------------------------------- */
  /* setCellProps                                                          */
  /* -------------------------------------------------------------------- */

  // props set by the cell renderer, reset when the cell shows another row/column
  @tracked private cellPropsState: { key: string; props: EuiDataGridSetCellProps } | null =
    null;

  get cellPropsKey(): string {
    return `${this.columnId}:${this.rowIndex}`;
  }

  get cellProps(): EuiDataGridSetCellProps {
    const state = this.cellPropsState;
    return state && state.key === this.cellPropsKey ? state.props : {};
  }

  /** Renderers may call this during render; the update is applied after rendering. */
  setCellProps = (props: EuiDataGridSetCellProps): void => {
    const key = this.cellPropsKey;
    schedule('afterRender', () => {
      if (this.isDestroying || this.isDestroyed) return;
      const current = this.cellPropsState;
      if (current && current.key === key && shallowEqual(current.props, props)) return;
      if (!current && Object.keys(props).length === 0) return;
      this.cellPropsState = { key, props };
    });
  };

  /** Arbitrary attributes from setCellProps (other than class/style/data-test-subj). */
  cellPropsAttributes = modifier(
    (element: HTMLElement, [props]: [EuiDataGridSetCellProps]) => {
      const names: string[] = [];
      for (const [name, value] of Object.entries(props)) {
        if (['className', 'style', 'isExpandable', 'data-test-subj'].includes(name)) continue;
        if (value == null || value === false || typeof value === 'function') continue;
        element.setAttribute(name, String(value as string | number | boolean));
        names.push(name);
      }
      return () => names.forEach((name) => element.removeAttribute(name));
    }
  );

  /* -------------------------------------------------------------------- */
  /* Expansion & popover                                                   */
  /* -------------------------------------------------------------------- */

  get defaultIsExpandable(): boolean {
    if (this.args.isExpandable !== undefined && !this.args.isFooter) return this.args.isExpandable;
    if (this.isControlColumn) return false;
    if (this.args.isFooter) return true;
    return this.column?.isExpandable ?? true;
  }

  get isExpandable(): boolean {
    // A cell with cell actions must always be expandable, otherwise keyboard
    // and screen reader users can't access them
    if (this.column?.cellActions?.length) return true;
    return this.cellProps.isExpandable ?? this.defaultIsExpandable;
  }

  get isPopoverOpen(): boolean {
    return (
      this.isExpandable &&
      this.grid.isPopoverOpenFor(this.args.colIndex, this.args.visibleRowIndex)
    );
  }

  get showCellActions(): boolean {
    return this.isExpandable && (this.isPopoverOpen || this.isFocused || this.isHovered);
  }

  @action
  handleCellExpansionClick(): void {
    if (this.isPopoverOpen) {
      this.grid.closeCellPopover();
    } else {
      this.grid.openCellPopover({
        rowIndex: this.args.visibleRowIndex,
        colIndex: this.args.colIndex
      });
    }
  }

  @action
  closePopover(): void {
    this.grid.closeCellPopover();
  }

  /** Clicking the expand action must toggle, not count as an outside click. */
  @action
  onPopoverClickOutside(event: Event): void {
    const actions = this.cellElement?.querySelector('.euiDataGridRowCell__actionsWrapper');
    if (!actions?.contains(event.target as Node)) this.grid.closeCellPopover();
  }

  private popoverPanel: HTMLElement | null = null;

  @action
  registerPopoverPanel(panel: HTMLElement | null): void {
    this.popoverPanel?.removeEventListener('keydown', this.onPopoverKeyDown, true);
    this.popoverPanel = panel;
    panel?.addEventListener('keydown', this.onPopoverKeyDown, true);
  }

  @action
  onPopoverKeyDown(event: KeyboardEvent): void {
    if (event.key === keys.F2 || event.key === keys.ESCAPE) {
      event.preventDefault();
      event.stopPropagation();
      this.grid.closeCellPopover();
      const cell = this.cellElement;
      // prevent the actions animation from replaying while focus moves back
      cell?.setAttribute('data-keyboard-closing', 'true');
      requestAnimationFrame(() => {
        cell?.focus();
        cell?.removeAttribute('data-keyboard-closing');
      });
    }
  }

  get popoverFocusTrapOptions() {
    return {
      onClickOutside: this.onPopoverClickOutside,
      clickOutsideDeactivates: false,
      // let clicks through (e.g. the expand button toggling the popover)
      allowOutsideClick: true
    };
  }

  get popoverPanelClassName(): string {
    return concatClass('euiDataGridRowCell__popover', this.grid.cellPopoverProps.panelClassName);
  }

  get popoverZIndex(): number | undefined {
    return this.grid.cellPopoverProps.zIndex;
  }

  get popoverPanelStyle(): Record<string, string> {
    const width = this.cellElement?.offsetWidth ?? 0;
    return {
      maxInlineSize: `min(75vw, max(${width}px, 400px))`,
      maxBlockSize: '50vh'
    };
  }

  get schema(): string | null | undefined {
    return this.column?.schema || this.columnType;
  }

  get cellText(): string {
    return this.contentElement?.innerText ?? '';
  }

  get jsonPopoverText(): string {
    let formatted = this.cellText;
    try {
      formatted = JSON.stringify(JSON.parse(formatted), null, 2);
    } catch {
      // not JSON: show as is
    }
    return formatted;
  }

  get isJsonSchema(): boolean {
    return this.schema === 'json';
  }

  @action
  setCellPopoverProps(props: Record<string, unknown>): void {
    schedule('afterRender', () => {
      if (!this.isDestroying) this.grid.cellPopoverProps = props;
    });
  }

  get popoverRendererProps() {
    return {
      rowIndex: this.rowIndex,
      colIndex: this.args.colIndex,
      columnId: this.columnId,
      schema: this.schema,
      cellContentsElement: this.contentElement,
      setCellPopoverProps: this.setCellPopoverProps
    };
  }

  /* -------------------------------------------------------------------- */
  /* Focus                                                                */
  /* -------------------------------------------------------------------- */

  onFocusUpdate = (isFocused: boolean, preventScroll = false): void => {
    if (this.isDestroying) return;
    this.isFocused = isFocused;
    if (isFocused) this.takeFocus(preventScroll);
  };

  takeFocus(preventScroll: boolean): void {
    const cell = this.cellElement;
    // Only focus the cell if not already focused on something in the cell
    if (cell && !cell.contains(document.activeElement)) cell.focus({ preventScroll });
  }

  @action
  updateCellFocusContext(): void {
    this.grid.setFocusedCell([this.args.colIndex, this.args.visibleRowIndex]);
  }

  setupCell = modifier((element: HTMLElement) => {
    this.cellElement = element;
    const { grid, colIndex, visibleRowIndex } = this.args;
    if (grid.isFocusedCell(colIndex, visibleRowIndex)) {
      // preventScroll: don't hijack the user's scrolling when the cell re-mounts
      this.takeFocus(true);
      afterRender(this, () => grid.setIsFocusedCellInView(true));
    }
    // take interactive children out of the tab order
    const hasInteractives = disableInteractives(element).length > 0;
    afterRender(this, () => {
      if (hasInteractives !== this.hasInteractiveChildren)
        this.hasInteractiveChildren = hasInteractives;
    });
    // focusing any (interactive) child updates the grid focus
    const onFocus = () => this.updateCellFocusContext();
    element.addEventListener('focus', onFocus, true);
    return () => {
      element.removeEventListener('focus', onFocus, true);
      this.cellElement = null;
    };
  });

  @action
  onMouseEnter(): void {
    this.isHovered = true;
  }

  @action
  onMouseLeave(): void {
    this.isHovered = false;
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (this.isExpandable) {
      if (this.isPopoverOpen) return;
      if (event.key === keys.ENTER || event.key === keys.F2) {
        event.preventDefault();
        this.grid.openCellPopover({
          rowIndex: this.args.visibleRowIndex,
          colIndex: this.args.colIndex
        });
      }
    }
  }

  /* -------------------------------------------------------------------- */
  /* Focus trap for non-expandable cells with interactive children         */
  /* -------------------------------------------------------------------- */

  get renderFocusTrap(): boolean {
    return !this.isExpandable && this.hasInteractiveChildren;
  }

  @action
  onKeyUp(event: KeyboardEvent): void {
    if (!this.renderFocusTrap) return;
    switch (event.key) {
      case keys.ENTER:
      case keys.F2:
        event.preventDefault();
        if (!this.isCellEntered) this.enterCell();
        break;
      case keys.ESCAPE:
        event.preventDefault();
        if (this.isCellEntered) this.exitCell();
        break;
    }
  }

  enterCell(): void {
    this.isCellEntered = true;
    if (this.cellElement) enableAndFocusInteractives(this.cellElement);
  }

  @action
  exitCell(): void {
    if (!this.isCellEntered) return;
    this.isCellEntered = false;
    this.isExited = true;
    const cell = this.cellElement;
    if (cell) {
      disableInteractives(cell);
      requestAnimationFrame(() => cell.focus());
    }
  }

  @action
  onBlur(): void {
    // ensures the SR text is reset when navigating to a different cell
    if (this.isExited) this.isExited = false;
  }

  focusTrapOptions = {
    clickOutsideDeactivates: true,
    escapeDeactivates: false,
    // like react-focus-on, entering the cell focuses its first interactive child
    returnFocusOnDeactivate: false,
    onDeactivate: () => {
      if (this.isCellEntered) this.isCellEntered = false;
    },
    fallbackFocus: () => this.cellElement!
  };

  get focusTrapEnterPrompt(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridCell.focusTrapEnterPrompt',
      "Press the Enter key to interact with this cell's contents."
    );
  }

  get focusTrapExitPrompt(): string {
    return this.euiI18n.lookupToken('euiDataGridCell.focusTrapExitPrompt', 'Exited cell content.');
  }

  get focusTrapEnteredExitPrompt(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridCell.focusTrapEnteredExitPrompt',
      'Press the Escape key to exit the cell.'
    );
  }

  /* -------------------------------------------------------------------- */
  /* Row heights                                                          */
  /* -------------------------------------------------------------------- */

  get rowHeightOption() {
    return this.args.body.rowHeightUtils.getRowHeightOption(
      this.rowIndex,
      this.grid.rowHeightsOptions
    );
  }

  get cellHeightType(): RowHeightType {
    const utils = this.args.body.rowHeightUtils;
    const option = this.rowHeightOption;
    if (utils.isAutoBelowLineCount(this.grid.rowHeightsOptions, option))
      return 'autoBelowLineCount';
    return utils.getHeightType(option) || 'default';
  }

  get lineClamp(): number | undefined {
    const type = this.cellHeightType;
    if ((type === 'lineCount' || type === 'autoBelowLineCount') && !this.isControlColumn) {
      return this.args.body.rowHeightUtils.getLineCount(this.rowHeightOption);
    }
    return undefined;
  }

  /** Port of `recalculateLineHeight`: one cell per row measures line heights. */
  measureLineHeight = modifier((element: HTMLElement, positional: unknown[]) => {
    void positional; // re-run when font size, padding or height options change
    if (!this.isFirstColumn || this.args.isFooter) return;
    const { body, grid } = this.args;
    const utils = body.rowHeightUtils;
    const options = grid.rowHeightsOptions;
    const option = utils.getRowHeightOption(this.rowIndex, options);
    if (utils.isAutoBelowLineCount(options, option)) return; // auto height instead
    const lineCount = option == null ? 1 : utils.getLineCount(option);
    if (!lineCount) return;
    const height = utils.calculateHeightForLineCount(element, lineCount);
    if (utils.isRowHeightOverride(this.rowIndex, options)) {
      utils.setRowHeight(this.rowIndex, this.columnId, height, this.args.visibleRowIndex);
    } else {
      afterRender(this, () => body.setMinRowHeight(height));
    }
  });

  /** Port of `recalculateAutoHeight`: auto rows report their content height. */
  measureAutoHeight = modifier((element: HTMLElement, [isAuto]: [boolean]) => {
    if (!isAuto || this.args.isFooter) return;
    const report = () => {
      if (this.isDestroying) return;
      this.args.body.rowHeightUtils.setRowHeight(
        this.rowIndex,
        this.columnId,
        element.offsetHeight,
        this.args.visibleRowIndex
      );
    };
    report();
    return observeResize([element], report);
  });

  get isAutoHeight(): boolean {
    return this.args.body.rowHeightUtils.isAutoHeight(
      this.rowIndex,
      this.grid.rowHeightsOptions
    );
  }

  setContentElement = modifier((element: HTMLElement) => {
    this.contentElement = element;
    return () => {
      if (this.contentElement === element) this.contentElement = null;
    };
  });

  /* -------------------------------------------------------------------- */
  /* Classes, styles & attributes                                         */
  /* -------------------------------------------------------------------- */

  @cached
  get themeStyles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      cell: useEuiBorealisStyles(context, euiDataGridRowCellStyles),
      footer: useEuiBorealisStyles(context, euiDataGridFooterStyles),
      popover: useEuiBorealisStyles(context, euiDataGridCellPopoverStyles)
    };
  }

  @cached
  get cellClass(): string {
    const { context, cell, footer } = this.themeStyles;
    return euiClass(
      context,
      cell.euiDataGridRowCell,
      this.args.isFooter && footer.euiDataGridFooterCell
    );
  }

  get classes(): string {
    const columnType = this.columnType;
    return [
      'euiDataGridRowCell',
      columnType && `euiDataGridRowCell--${columnType}`,
      this.isPopoverOpen && 'euiDataGridRowCell--open',
      this.args.isFooter && 'euiDataGridFooterCell',
      this.isFirstColumn && 'euiDataGridRowCell--firstColumn',
      this.isLastColumn && 'euiDataGridRowCell--lastColumn',
      this.isControlColumn && 'euiDataGridRowCell--controlColumn',
      this.textTransform && `euiDataGridRowCell--${this.textTransform}`,
      this.args.isFooter && this.isControlColumn && (this.controlColumn?.footerCellProps?.className as string),
      this.cellProps.className,
      this.cellClass
    ]
      .filter(Boolean)
      .join(' ');
  }

  get dataTestSubj(): string {
    return ['dataGridRowCell', this.cellProps['data-test-subj']].filter(Boolean).join(' ');
  }

  /** Ember addition: upstream sets no `aria-colindex`; columns are virtualized here. */
  get ariaColIndex(): number {
    return this.args.colIndex + 1;
  }

  get ariaRowIndex(): number {
    const pagination = this.grid.pagination;
    const { visibleRowIndex } = this.args;
    return pagination
      ? visibleRowIndex + 1 + pagination.pageSize * pagination.pageIndex
      : visibleRowIndex + 1;
  }

  get style() {
    const { body, colIndex, visibleRowIndex, isFooter } = this.args;
    const width = this.width;
    const parts: string[] = [];
    if (!isFooter && !body.isVirtualized) {
      // custom grid body: cells flow in the consumer's rows
      parts.push(`height:${this.isAutoHeight ? 'auto' : `${body.rowHeight(visibleRowIndex)}px`}`);
    } else if (!isFooter) {
      parts.push(
        'position:absolute',
        `left:${body.columnLeft(colIndex)}px`,
        'top:0',
        `height:${body.rowHeight(visibleRowIndex)}px`
      );
    }
    if (width != null) parts.push(`width:${width}px`);
    const lineHeight = this.grid.rowHeightsOptions?.lineHeight;
    if (lineHeight) parts.push(`line-height:${lineHeight}`);
    const extra = styleString(this.cellProps.style);
    if (extra) parts.push(extra);
    return htmlSafe(parts.join(';'));
  }

  @cached
  get contentClass(): string {
    const { context, cell } = this.themeStyles;
    const type = this.cellHeightType;
    const isControl = this.isControlColumn;
    const isAuto = type === 'auto' || type === 'autoBelowLineCount';
    const hasClamp = this.lineClamp != null;
    return [
      'euiDataGridRowCell__content',
      `euiDataGridRowCell__content--${type}Height`,
      !isControl && type !== 'default' && 'eui-textBreakWord',
      !isControl && type === 'default' && 'eui-textTruncate',
      hasClamp && 'euiTextBlockTruncate',
      euiClass(
        context,
        cell.content.euiDataGridRowCell__content,
        ...(isControl
          ? [cell.content.controlColumn, cell.content.autoHeight]
          : [isAuto ? cell.content.autoHeight : cell.content.defaultHeight]),
        !isControl && type !== 'default' && TEXT_BREAK_WORD,
        !isControl && type === 'default' && TEXT_TRUNCATE,
        hasClamp && euiTextBlockTruncate
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  get contentStyle() {
    const lines = this.lineClamp;
    return lines ? htmlSafe(`-webkit-line-clamp:${lines}`) : undefined;
  }

  @cached
  get popoverPanelCss() {
    return this.themeStyles.popover.euiDataGridRowCell__popover;
  }

  /* -------------------------------------------------------------------- */
  /* Renderers                                                            */
  /* -------------------------------------------------------------------- */

  get kind(): 'data' | 'control' | 'footer' | 'controlFooter' {
    if (this.args.isFooter) return this.isControlColumn ? 'controlFooter' : 'footer';
    return this.isControlColumn ? 'control' : 'data';
  }

  get renderer() {
    if (this.args.renderCellValue && !this.args.isFooter) return this.args.renderCellValue;
    switch (this.kind) {
      case 'data':
        return this.grid.args.renderCellValue;
      case 'footer':
        return this.grid.args.renderFooterCellValue;
      case 'control':
        return this.controlColumn?.rowCellRender;
      case 'controlFooter':
        return this.controlColumn?.footerCellRender;
    }
    return undefined;
  }

  get cellValueProps(): EuiDataGridCellValueElementProps {
    return {
      rowIndex: this.rowIndex,
      colIndex: this.args.colIndex,
      columnId: this.columnId,
      setCellProps: this.setCellProps,
      isExpandable: this.isExpandable,
      isExpanded: this.isPopoverOpen,
      isDetails: false,
      schema: this.schema,
      cellContext: this.grid.args.cellContext
    };
  }

  get detailsValueProps(): EuiDataGridCellValueElementProps {
    return {
      ...this.cellValueProps,
      isExpandable: true,
      isExpanded: true,
      isDetails: true
    };
  }

  get cellPosition(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridCell.position',
      '{columnName}, column {columnIndex}, row {rowIndex}',
      {
        columnName: this.column?.displayAsText || this.columnId,
        columnIndex: this.args.colIndex + 1,
        rowIndex: this.ariaRowIndex
      }
    );
  }

  get expansionEnterPrompt(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridCell.expansionEnterPrompt',
      'Press the Enter key to expand this cell.'
    );
  }

  get screenReaderDescription(): string {
    return ` - ${this.cellPosition}${this.showCellActions ? `. ${this.expansionEnterPrompt}` : ''}`;
  }

  get ariaDescribedBy(): string | undefined {
    return this.renderFocusTrap ? this.focusTrapHintId : undefined;
  }

  <template>
    {{! template-lint-disable no-invalid-interactive require-aria-activedescendant-tabindex }}
    <div
      role="gridcell"
      class={{this.classes}}
      style={{this.style}}
      tabindex={{if this.isFocused "0" "-1"}}
      aria-rowindex={{this.ariaRowIndex}}
      aria-colindex={{this.ariaColIndex}}
      aria-describedby={{this.ariaDescribedBy}}
      data-test-subj={{this.dataTestSubj}}
      data-gridcell-column-id={{this.columnId}}
      data-gridcell-column-index={{@colIndex}}
      data-gridcell-row-index={{this.rowIndex}}
      data-gridcell-visible-row-index={{@visibleRowIndex}}
      {{on "keydown" this.onKeyDown}}
      {{on "keyup" this.onKeyUp}}
      {{on "blur" this.onBlur}}
      {{on "mouseenter" this.onMouseEnter}}
      {{on "mouseleave" this.onMouseLeave}}
      {{this.cellPropsAttributes this.cellProps}}
      {{this.registerFocus @colIndex @visibleRowIndex}}
      {{this.setupCell}}
      ...attributes
    >
      {{#if this.isExpandable}}
        {{! template-lint-disable no-duplicate-landmark-elements }}
        <div
          data-datagrid-cellcontent
          class={{this.contentClass}}
          style={{this.contentStyle}}
          {{this.setContentElement}}
          {{this.measureLineHeight
            this.grid.gridStyles.fontSize
            this.grid.gridStyles.cellPadding
            this.grid.rowHeightsOptions
            this.rowHeightOption
          }}
          {{this.measureAutoHeight this.isAutoHeight}}
        >
          {{#if this.renderer}}
            {{#let this.renderer as |Renderer|}}
              <Renderer
                @rowIndex={{this.rowIndex}}
                @colIndex={{@colIndex}}
                @columnId={{this.columnId}}
                @setCellProps={{this.setCellProps}}
                @isExpandable={{this.isExpandable}}
                @isExpanded={{this.isPopoverOpen}}
                @isDetails={{false}}
                @schema={{this.schema}}
                @cellContext={{@grid.args.cellContext}}
              />
            {{/let}}
          {{else if (eq this.kind "data")}}
            {{yield this.cellValueProps to="cell"}}
          {{else if (eq this.kind "control")}}
            {{yield this.cellValueProps to="controlCell"}}
          {{else if (eq this.kind "footer")}}
            {{yield this.cellValueProps to="footerCell"}}
          {{else if (eq this.kind "controlFooter")}}
            {{yield this.cellValueProps to="controlFooterCell"}}
          {{/if}}
        </div>
      {{else}}
        <div
          data-focus-lock-disabled={{if this.isCellEntered "false" "disabled"}}
          {{focusTrap
            isActive=this.isCellEntered
            focusTrapOptions=this.focusTrapOptions
          }}
        >
          <div
            data-datagrid-cellcontent
            class={{this.contentClass}}
            style={{this.contentStyle}}
            {{this.setContentElement}}
            {{this.measureLineHeight
              this.grid.gridStyles.fontSize
              this.grid.gridStyles.cellPadding
              this.grid.rowHeightsOptions
              this.rowHeightOption
            }}
            {{this.measureAutoHeight this.isAutoHeight}}
          >
            {{#if this.renderer}}
              {{#let this.renderer as |Renderer|}}
                <Renderer
                  @rowIndex={{this.rowIndex}}
                  @colIndex={{@colIndex}}
                  @columnId={{this.columnId}}
                  @setCellProps={{this.setCellProps}}
                  @isExpandable={{this.isExpandable}}
                  @isExpanded={{false}}
                  @isDetails={{false}}
                  @schema={{this.schema}}
                  @cellContext={{@grid.args.cellContext}}
                />
              {{/let}}
            {{else if (eq this.kind "data")}}
              {{yield this.cellValueProps to="cell"}}
            {{else if (eq this.kind "control")}}
              {{yield this.cellValueProps to="controlCell"}}
            {{else if (eq this.kind "footer")}}
              {{yield this.cellValueProps to="footerCell"}}
            {{else if (eq this.kind "controlFooter")}}
              {{yield this.cellValueProps to="controlFooterCell"}}
            {{/if}}
          </div>
          {{#if this.renderFocusTrap}}
            <p id={{this.focusTrapHintId}} hidden>
              {{#if this.isExited}}{{this.focusTrapExitPrompt}}{{/if}}
              {{#unless this.isCellEntered}}{{this.focusTrapEnterPrompt}}{{/unless}}
            </p>
            <EuiLiveAnnouncer @clearAfterMs={{1000}}>
              {{#if this.isCellEntered}}{{this.focusTrapEnteredExitPrompt}}{{/if}}
            </EuiLiveAnnouncer>
          {{/if}}
        </div>
      {{/if}}
      {{#if this.isFocused}}
        <EuiScreenReaderOnly><p>{{this.screenReaderDescription}}</p></EuiScreenReaderOnly>
      {{/if}}
      {{#if this.showCellActions}}
        <EuiDataGridCellActions
          @column={{this.column}}
          @rowIndex={{this.rowIndex}}
          @colIndex={{@colIndex}}
          @onExpandClick={{this.handleCellExpansionClick}}
        >
          <:popover>
            <EuiPopover
              @isOpen={{this.isPopoverOpen}}
              @closePopover={{this.closePopover}}
              @display="block"
              @hasArrow={{false}}
              @attachToAnchor={{true}}
              @panelPaddingSize="s"
              @anchorPosition="downLeft"
              @repositionToCrossAxis={{false}}
              @panelClassName={{this.popoverPanelClassName}}
              @panelCss={{this.popoverPanelCss}}
              @panelStyle={{this.popoverPanelStyle}}
              @panelRef={{this.registerPopoverPanel}}
              @focusTrapOptions={{this.popoverFocusTrapOptions}}
              @zIndex={{this.popoverZIndex}}
            >
              <:button>
                <div data-test-subject="cellPopoverAnchor"></div>
              </:button>
              <:content>
                <div data-test-subj="euiDataGridExpansionPopover">
                  {{#if @grid.args.renderCellPopover}}
                    {{#let @grid.args.renderCellPopover as |PopoverRenderer|}}
                      <PopoverRenderer
                        @rowIndex={{this.rowIndex}}
                        @colIndex={{@colIndex}}
                        @columnId={{this.columnId}}
                        @schema={{this.schema}}
                        @cellContentsElement={{this.contentElement}}
                        @setCellPopoverProps={{this.setCellPopoverProps}}
                      >
                        {{#if this.renderer}}
                          {{#let this.renderer as |Renderer|}}
                            <Renderer
                              @rowIndex={{this.rowIndex}}
                              @colIndex={{@colIndex}}
                              @columnId={{this.columnId}}
                              @setCellProps={{this.setCellProps}}
                              @isExpandable={{true}}
                              @isExpanded={{true}}
                              @isDetails={{true}}
                              @schema={{this.schema}}
                              @cellContext={{@grid.args.cellContext}}
                            />
                          {{/let}}
                        {{/if}}
                      </PopoverRenderer>
                    {{/let}}
                  {{else if @hasCellPopoverBlock}}
                    {{yield
                      (hash
                        rowIndex=this.rowIndex
                        colIndex=@colIndex
                        columnId=this.columnId
                        schema=this.schema
                        cellContentsElement=this.contentElement
                        setCellPopoverProps=this.setCellPopoverProps
                        cellActions=(component
                          EuiDataGridCellPopoverActions
                          column=this.column
                          rowIndex=this.rowIndex
                          colIndex=@colIndex
                        )
                      )
                      to="cellPopover"
                    }}
                  {{else if this.isJsonSchema}}
                    <EuiCodeBlock
                      @isCopyable={{true}}
                      @transparentBackground={{true}}
                      @paddingSize="none"
                      @language="json"
                    >{{this.jsonPopoverText}}</EuiCodeBlock>
                    <EuiDataGridCellPopoverActions
                      @column={{this.column}}
                      @rowIndex={{this.rowIndex}}
                      @colIndex={{@colIndex}}
                    />
                  {{else}}
                    <EuiText>
                      {{#if this.renderer}}
                        {{#let this.renderer as |Renderer|}}
                          <Renderer
                            @rowIndex={{this.rowIndex}}
                            @colIndex={{@colIndex}}
                            @columnId={{this.columnId}}
                            @setCellProps={{this.setCellProps}}
                            @isExpandable={{true}}
                            @isExpanded={{true}}
                            @isDetails={{true}}
                            @schema={{this.schema}}
                            @cellContext={{@grid.args.cellContext}}
                          />
                        {{/let}}
                      {{else if (eq this.kind "footer")}}
                        {{yield this.detailsValueProps to="footerCell"}}
                      {{else}}
                        {{yield this.detailsValueProps to="cell"}}
                      {{/if}}
                    </EuiText>
                    <EuiDataGridCellPopoverActions
                      @column={{this.column}}
                      @rowIndex={{this.rowIndex}}
                      @colIndex={{@colIndex}}
                    />
                  {{/if}}
                </div>
              </:content>
            </EuiPopover>
          </:popover>
        </EuiDataGridCellActions>
      {{/if}}
    </div>
  </template>
}
