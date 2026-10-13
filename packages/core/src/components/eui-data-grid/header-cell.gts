import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

import { focusTrap } from 'ember-focus-trap';
import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiDataGridDraggableHeaderStyles,
  euiDataGridHeaderCellStyles,
  euiDataGridHeaderCellWrapperStyles
} from '../../utils/eui/styles.generated.ts';
import {
  disableInteractives,
  enableAndFocusInteractives
} from '../../utils/data-grid/focus.ts';
import { afterRender } from '../../utils/data-grid/scheduling.ts';
import * as keys from '../../utils/keys.ts';
import EuiIcon from '../eui-icon.gts';
import EuiLiveAnnouncer from '../eui-live-announcer.gts';
import EuiDataGridColumnActions, { hasColumnActions } from './column-actions.gts';
import EuiDataGridColumnResizer from './column-resizer.gts';
import EuiDataGridCopyMarker from './copy-marker.gts';

import type Owner from '@ember/owner';
import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridHeaderBody } from './header-row.gts';
import type { ModifierLike } from '@glint/template';
import type {
  EuiDataGridColumn,
  EuiDataGridControlColumn
} from '../../utils/data-grid/types.ts';

export interface EuiDataGridHeaderCellSignature {
  Element: HTMLDivElement;
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridHeaderBody;
    /** Visible column index (including leading control columns). */
    index: number;
    column?: EuiDataGridColumn;
    controlColumn?: EuiDataGridControlColumn;
    /** Drag and drop columns: the `EuiDraggable` handle modifier for the cell. */
    dragHandle?: ModifierLike<{ Element: HTMLElement }>;
    /** Drag and drop columns: this column is being dragged. */
    isDragging?: boolean;
    /** Drag and drop columns: this column is being dragged with the keyboard. */
    isKeyboardDragging?: boolean;
    /** Drag and drop columns: id of the drag instructions text. */
    dragInstructionsId?: string;
  };
  Blocks: {
    controlHeaderCell: [{ columnId: string }];
  };
}

/**
 * Header cell (`role=columnheader`) for data and control columns. Port of
 * upstream `EuiDataGridHeaderCell`, `EuiDataGridControlHeaderCell` and
 * `EuiDataGridHeaderCellWrapper` (focus state, interactive children).
 */
export default class EuiDataGridHeaderCell extends Component<EuiDataGridHeaderCellSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isFocused = false;
  @tracked isActionsPopoverOpen = false;
  @tracked isColumnMoving = false;
  @tracked interactiveCount = 0;
  @tracked isCellEntered = false;
  @tracked isExited = false;

  headerElement: HTMLElement | null = null;
  readonly sortingAriaId = `euiDataGridCellHeader-${guidFor(this)}-sorting`;
  readonly focusTrapHintId = `euiDataGridCellHeader-${guidFor(this)}-focusTrapHint`;
  constructor(owner: Owner, args: EuiDataGridHeaderCellSignature['Args']) {
    super(owner, args);
    this.isFocused = args.grid.isFocusedCell(args.index, -1);
  }

  /** Subscribes to focus changes of this header's column index (re-run when columns move). */
  registerFocus = modifier((_element: HTMLElement, [index]: [number]) => {
    const { grid } = this.args;
    afterRender(this, () => {
      const isFocused = grid.isFocusedCell(index, -1);
      if (isFocused !== this.isFocused) this.isFocused = isFocused;
    });
    return grid.onFocusUpdate([index, -1], this.onFocusUpdate);
  });

  onFocusUpdate = (isFocused: boolean): void => {
    if (this.isDestroying) return;
    this.isFocused = isFocused;
    const header = this.headerElement;
    // Only focus the cell if not already focused on something in the cell
    if (isFocused && header && !header.contains(document.activeElement)) header.focus();
  };

  /* -------------------------------------------------------------------- */
  /* Column                                                               */
  /* -------------------------------------------------------------------- */

  get isControlColumn(): boolean {
    return !!this.args.controlColumn;
  }

  get id(): string {
    return this.args.controlColumn?.id ?? this.args.column?.id ?? '';
  }

  get title(): string {
    const column = this.args.column;
    return column?.displayAsText || this.id;
  }

  get width(): number | undefined {
    if (this.args.controlColumn) return this.args.controlColumn.width;
    return this.args.body.widthForColumn(this.id);
  }

  get columnType(): string | null {
    if (this.isControlColumn) return null;
    return this.args.grid.schema[this.id]?.columnType ?? null;
  }

  get isLastColumn(): boolean {
    return this.args.index === this.args.grid.visibleColCount - 1;
  }

  /** The last data column ends a copied row (tabular copy). */
  get copyMarkerType(): 'no-copy' | 'newline' | 'tab' {
    if (this.isControlColumn) return 'no-copy';
    const columns = this.args.grid.columns;
    const isLastCopyColumn =
      columns.length > 0 ? columns[columns.length - 1]!.id === this.id : this.isLastColumn;
    return isLastCopyColumn ? 'newline' : 'tab';
  }

  get hasColumnActions(): boolean {
    return !this.isControlColumn && hasColumnActions(this.args.column?.actions);
  }

  get cellContentId(): string {
    return `dataGridHeaderCellContent-${this.id}`;
  }

  get resizerWidth(): number {
    return this.width ?? 0;
  }

  get dataColumn(): EuiDataGridColumn {
    return this.args.column!;
  }

  get isDraggable(): boolean {
    return !this.isControlColumn && !!this.args.dragHandle;
  }

  get showResizer(): boolean {
    // draggable columns render their resizer outside the drag handle
    if (this.isDraggable) return false;
    return !this.isControlColumn && this.args.column?.isResizable !== false && this.width != null;
  }

  /** The `EuiDraggable` handle modifier, or a no-op for static columns. */
  get dragHandleModifier(): ModifierLike<{ Element: HTMLElement }> {
    return this.args.dragHandle ?? noopModifier;
  }

  /* -------------------------------------------------------------------- */
  /* Sorting                                                              */
  /* -------------------------------------------------------------------- */

  get sortedColumn() {
    return this.args.grid.args.sorting?.columns.find((col) => col.id === this.id);
  }

  get hasOnlyOneSort(): boolean {
    return this.args.grid.args.sorting?.columns.length === 1;
  }

  get hasAriaSortOnly(): boolean {
    return !!this.sortedColumn && this.hasOnlyOneSort;
  }

  /**
   * `aria-sort` only when a single column is sorted
   * (see https://github.com/w3c/aria/issues/283 for multi-column sorting).
   */
  get ariaSort(): 'ascending' | 'descending' | undefined {
    if (!this.hasAriaSortOnly) return undefined;
    return this.args.grid.args.sorting!.columns[0]!.direction === 'asc'
      ? 'ascending'
      : 'descending';
  }

  /** Screen-reader sorting status, the alternative to `aria-sort` for multi-column sorting. */
  get sortingScreenReaderText(): string | null {
    if (!this.sortedColumn || this.hasAriaSortOnly) return null;
    const columns = this.args.grid.args.sorting?.columns ?? [];
    const parts = columns.map(({ id: columnId, direction }, index) => {
      if (this.hasOnlyOneSort) {
        return direction === 'asc'
          ? this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByAscendingSingle', 'Sorted ascending')
          : this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByDescendingSingle', 'Sorted descending');
      } else if (index === 0) {
        return direction === 'asc'
          ? this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByAscendingFirst', 'Sorted by {columnId}, ascending', { columnId })
          : this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByDescendingFirst', 'Sorted by {columnId}, descending', { columnId });
      }
      return direction === 'asc'
        ? this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByAscendingMultiple', ', then sorted by {columnId}, ascending', { columnId })
        : this.euiI18n.lookupToken('euiDataGridHeaderCell.sortedByDescendingMultiple', ', then sorted by {columnId}, descending', { columnId });
    });
    return `${parts.join('')}.`;
  }

  /* -------------------------------------------------------------------- */
  /* Focus & interactive children                                         */
  /* -------------------------------------------------------------------- */

  /** Interactive children besides the column actions button need a focus trap. */
  get renderFocusTrap(): boolean {
    return this.interactiveCount > (this.hasColumnActions ? 1 : 0);
  }

  setupHeader = modifier((element: HTMLElement) => {
    this.headerElement = element;
    if (this.args.grid.isFocusedCell(this.args.index, -1) && !element.contains(document.activeElement)) {
      element.focus({ preventScroll: true });
    }
    const count = disableInteractives(element).length;
    afterRender(this, () => {
      if (count !== this.interactiveCount) this.interactiveCount = count;
    });
    const onFocus = () => this.args.grid.setFocusedCell([this.args.index, -1]);
    element.addEventListener('focus', onFocus, true);
    return () => {
      element.removeEventListener('focus', onFocus, true);
      this.headerElement = null;
    };
  });

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (this.isDraggable) {
      // while dragging, keys belong to the drag (the header row stops them)
      if (this.args.isDragging) return;
      // only Space on the cell itself lifts the column (like upstream): Enter
      // keeps opening the column actions, keys in interactive children are theirs
      if (event.key === keys.ENTER || (event.key === keys.SPACE && event.target !== event.currentTarget)) {
        event.stopPropagation();
      }
    }
    // Ignore keys that conflict with the focus trap being entered/exited
    if (this.renderFocusTrap && (event.key === keys.ENTER || event.key === keys.ESCAPE)) return;
    // Enter on the cell itself (not bubbled from the actions button) opens the actions
    if (this.hasColumnActions && event.key === keys.ENTER && event.target === event.currentTarget) {
      this.isActionsPopoverOpen = true;
    }
  }

  @action
  onKeyUp(event: KeyboardEvent): void {
    if (!this.renderFocusTrap) return;
    switch (event.key) {
      case keys.ENTER:
      case keys.F2:
        event.preventDefault();
        if (!this.isCellEntered) {
          this.isCellEntered = true;
          if (this.headerElement) enableAndFocusInteractives(this.headerElement);
        }
        break;
      case keys.ESCAPE:
        event.preventDefault();
        if (this.isCellEntered) {
          this.isCellEntered = false;
          this.isExited = true;
          const header = this.headerElement;
          if (header) {
            disableInteractives(header);
            requestAnimationFrame(() => header.focus());
          }
        }
        break;
    }
  }

  @action
  onBlur(): void {
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
    fallbackFocus: () => this.headerElement!
  };

  @action
  setIsActionsPopoverOpen(isOpen: boolean): void {
    this.isActionsPopoverOpen = isOpen;
  }

  @action
  setIsColumnMoving(isMoving: boolean): void {
    if (!this.isDestroying) this.isColumnMoving = isMoving;
  }

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
  /* Classes & attributes                                                 */
  /* -------------------------------------------------------------------- */

  @cached
  get themeStyles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      wrapper: useEuiBorealisStyles(context, euiDataGridHeaderCellWrapperStyles),
      cell: useEuiBorealisStyles(context, euiDataGridHeaderCellStyles),
      draggable: useEuiBorealisStyles(context, euiDataGridDraggableHeaderStyles)
    };
  }

  @cached
  get wrapperClass(): string {
    const { context, wrapper, draggable } = this.themeStyles;
    if (!this.isDraggable) return euiClass(context, wrapper.euiDataGridHeaderCell);
    return euiClass(
      context,
      wrapper.euiDataGridHeaderCell,
      // re-apply the background and border, since the droppable zone sets
      // its own and confuses :first-of-type CSS
      draggable[this.args.grid.gridStyles.header],
      this.args.index !== 0 && draggable.noLeadingBorder,
      this.args.isKeyboardDragging && draggable.isKeyboardDragging
    );
  }

  @cached
  get draggableIconCss() {
    const { cell } = this.themeStyles;
    return [cell.euiDataGridHeaderCell__actions.action, cell.euiDataGridHeaderCell__actions.start];
  }

  get classes(): string {
    const columnType = this.columnType;
    const displayClass = this.isControlColumn
      ? this.args.controlColumn?.headerCellProps?.className
      : this.args.column?.displayHeaderCellProps?.className;
    return [
      'euiDataGridHeaderCell',
      this.isControlColumn && 'euiDataGridHeaderCell--controlColumn',
      columnType && `euiDataGridHeaderCell--${columnType}`,
      this.hasColumnActions && 'euiDataGridHeaderCell--hasColumnActions',
      this.isActionsPopoverOpen && 'euiDataGridHeaderCell--isActionsPopoverOpen',
      displayClass,
      this.wrapperClass
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get contentClass(): string {
    const { context, cell } = this.themeStyles;
    const isRight = this.columnType === 'numeric' || this.columnType === 'currency';
    return `euiDataGridHeaderCell__content ${euiClass(
      context,
      cell.euiDataGridHeaderCell__content,
      isRight && cell.right
    )}`;
  }

  get style() {
    return this.width != null ? htmlSafe(`width:${this.width}px`) : undefined;
  }

  get ariaDescribedBy(): string | undefined {
    const ids = [
      this.sortingScreenReaderText ? this.sortingAriaId : null,
      this.renderFocusTrap ? this.focusTrapHintId : null,
      this.isDraggable ? this.args.dragInstructionsId : null
    ].filter(Boolean);
    return ids.length ? ids.join(' ') : undefined;
  }

  /** Extra attributes from `displayHeaderCellProps` / `headerCellProps`. */
  extraAttributes = modifier((element: HTMLElement, [props]: [Record<string, unknown> | undefined]) => {
    const names: string[] = [];
    for (const [name, value] of Object.entries(props ?? {})) {
      if (name === 'className' || value == null || typeof value === 'function') continue;
      element.setAttribute(name, String(value as string | number | boolean));
      names.push(name);
    }
    return () => names.forEach((name) => element.removeAttribute(name));
  });

  get extraProps(): Record<string, unknown> | undefined {
    return this.isControlColumn
      ? this.args.controlColumn?.headerCellProps
      : this.args.column?.displayHeaderCellProps;
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      role="columnheader"
      class={{this.classes}}
      style={{this.style}}
      tabindex={{if this.isFocused "0" "-1"}}
      aria-colindex={{this.ariaColIndex}}
      aria-sort={{this.ariaSort}}
      aria-labelledby={{if this.renderFocusTrap (unless this.isControlColumn this.cellContentId)}}
      aria-describedby={{this.ariaDescribedBy}}
      data-test-subj="dataGridHeaderCell-{{this.id}}"
      data-gridcell-column-id={{this.id}}
      data-gridcell-column-index={{@index}}
      data-gridcell-row-index="-1"
      data-gridcell-visible-row-index="-1"
      data-column-moving={{if this.isColumnMoving "true" (if @isKeyboardDragging "true")}}
      {{on "keydown" this.onKeyDown}}
      {{on "keyup" this.onKeyUp}}
      {{on "blur" this.onBlur}}
      {{this.extraAttributes this.extraProps}}
      {{this.registerFocus @index}}
      {{this.setupHeader}}
      {{this.dragHandleModifier}}
    >
      {{#if this.isControlColumn}}<EuiDataGridCopyMarker @grid={{@grid}} @type="no-copy" />{{/if}}
      <div
        data-focus-lock-disabled={{if this.isCellEntered "false" "disabled"}}
        {{focusTrap isActive=this.isCellEntered focusTrapOptions=this.focusTrapOptions}}
      >
        {{#if @controlColumn}}
          {{#if @controlColumn.headerCellRender}}
            {{#let @controlColumn.headerCellRender as |HeaderCellRender|}}
              <HeaderCellRender />
            {{/let}}
          {{else}}
            {{yield (hash columnId=this.id) to="controlHeaderCell"}}
          {{/if}}
        {{else}}
          {{#if this.showResizer}}
            <EuiDataGridColumnResizer
              @columnId={{this.id}}
              @columnWidth={{this.resizerWidth}}
              @setColumnWidth={{@body.setColumnWidth}}
              @isLastColumn={{this.isLastColumn}}
            />
          {{/if}}
          {{#if this.isDraggable}}
            <span class="euiDataGridHeaderCell__draggableIcon">
              <EuiIcon @type="drag" @size="s" @css={{this.draggableIconCss}} />
            </span>
          {{/if}}
          <div
            class={{this.contentClass}}
            title={{this.title}}
            id={{this.cellContentId}}
            aria-label={{this.title}}
          >
            {{#if @column.display}}
              {{#let @column.display as |Display|}}<Display />{{/let}}
            {{else}}
              {{this.title}}
            {{/if}}
          </div>
          {{#if this.sortedColumn}}
            <EuiIcon
              @type={{if (eqDirection this.sortedColumn.direction "asc") "sortUp" "sortDown"}}
              @color="text"
              class="euiDataGridHeaderCell__sortingArrow"
              data-test-subj="dataGridHeaderCellSortingIcon-{{this.id}}"
            />
          {{/if}}
          {{#if this.sortingScreenReaderText}}
            <p id={{this.sortingAriaId}} hidden>{{this.sortingScreenReaderText}}</p>
          {{/if}}
          {{#if this.hasColumnActions}}
            <EuiDataGridColumnActions
              @grid={{@grid}}
              @index={{@index}}
              @column={{this.dataColumn}}
              @title={{this.title}}
              @hasFocusTrap={{this.renderFocusTrap}}
              @isPopoverOpen={{this.isActionsPopoverOpen}}
              @setIsPopoverOpen={{this.setIsActionsPopoverOpen}}
              @setIsColumnMoving={{this.setIsColumnMoving}}
            />
          {{/if}}
        {{/if}}
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
      <EuiDataGridCopyMarker @grid={{@grid}} @type={{this.copyMarkerType}} />
    </div>
  </template>

  /** Ember addition, see the body cell. */
  get ariaColIndex(): number {
    return this.args.index + 1;
  }
}

function eqDirection(a: unknown, b: unknown): boolean {
  return a === b;
}

const noopModifier = modifier(() => {}) as unknown as ModifierLike<{ Element: HTMLElement }>;
