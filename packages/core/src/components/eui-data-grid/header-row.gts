import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { autoScrollForElements } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiDataGridDraggableHeaderStyles,
  euiDataGridHeaderStyles
} from '../../utils/eui/styles.generated.ts';
import EuiDragDropContext from '../eui-drag-drop-context.gts';
import EuiDataGridColumnResizer from './column-resizer.gts';
import EuiDataGridHeaderCell from './header-cell.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type EuiDataGridBodyBase from './body-base.ts';
import type { DragStart, DropResult } from '../eui-drag-drop-context.gts';
import type { EuiDataGridColumn } from '../../utils/data-grid/types.ts';

/** Width/resize state the header cells read (the virtualized or custom body). */
export type EuiDataGridHeaderBody = Pick<EuiDataGridBodyBase<any>, 'widthForColumn' | 'setColumnWidth'>;

export interface EuiDataGridHeaderRowSignature {
  Element: HTMLDivElement;
  Args: {
    grid: EuiDataGrid;
    body: EuiDataGridHeaderBody;
  };
  Blocks: {
    controlHeaderCell: [{ columnId: string }];
  };
}

/**
 * The sticky header row: control and data column header cells. With
 * `columnVisibility.canDragAndDropColumns` the data columns are an
 * `EuiDroppable` list of `EuiDraggable` header cells (port of upstream
 * `draggable_columns.tsx`): drag a header with the pointer, or focus it and
 * press Space, move it with the arrow keys and press Space again to drop it
 * (Escape cancels).
 */
export default class EuiDataGridHeaderRow extends Component<EuiDataGridHeaderRowSignature> {
  @service declare euiI18n: EuiI18n;

  readonly droppableId = `euiDataGridHeaderDroppable-${guidFor(this)}`;
  readonly dragInstructionsId = `${this.droppableId}-instructions`;

  /** Column being dragged, and whether the drag uses the keyboard. */
  @tracked draggingColumnId: string | null = null;
  @tracked isKeyboardDragging = false;
  private wasDragging = false;

  @cached
  get themeStyles() {
    const context = getEuiThemeContext(this);
    return {
      context,
      header: useEuiBorealisStyles(context, euiDataGridHeaderStyles),
      draggable: useEuiBorealisStyles(context, euiDataGridDraggableHeaderStyles)
    };
  }

  @cached
  get classes(): string {
    const { context, header } = this.themeStyles;
    const style = this.args.grid.gridStyles.header;
    return `euiDataGridHeader ${euiClass(context, header.euiDataGridHeader, header[style])}`;
  }

  get dataColumnOffset(): number {
    return this.args.grid.leadingControlColumns.length;
  }

  get trailingOffset(): number {
    return this.dataColumnOffset + this.args.grid.columns.length;
  }

  get canDragAndDropColumns(): boolean {
    return !!this.args.grid.args.columnVisibility?.canDragAndDropColumns;
  }

  /* -------------------------------------------------------------------- */
  /* Drag and drop                                                        */
  /* -------------------------------------------------------------------- */

  get droppableCss() {
    return this.themeStyles.draggable.euiDataGridHeaderDroppable;
  }

  @cached
  get draggableCss() {
    const { draggable } = this.themeStyles;
    return [
      draggable.euiDataGridHeaderCellDraggableWrapper,
      draggable.euiDataGridHeaderCellDraggable,
      // Ember's EuiDraggable wraps its content in an item element
      { '& > .euiDraggable__item': { display: 'flex', blockSize: '100%' } }
    ];
  }

  get dragInstructions(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridHeaderCell.dragInstructions',
      'Press the space bar to start a drag. When dragging, use the arrow keys to move the column and the space bar to drop it, or press Escape to cancel.'
    );
  }

  /** Width for a resizable column's resizer (undefined: no resizer). */
  resizerWidth = (column: EuiDataGridColumn): number | undefined =>
    column.isResizable === false ? undefined : this.args.body.widthForColumn(column.id);

  isLastColumn = (index: number): boolean => index === this.args.grid.visibleColCount - 1;

  @action
  onDragStart({ draggableId }: DragStart): void {
    this.draggingColumnId = draggableId;
  }

  @action
  onDragEnd({ source, destination }: DropResult): void {
    this.draggingColumnId = null;
    this.isKeyboardDragging = false;
    const { grid } = this.args;
    const columns: EuiDataGridColumn[] = grid.columns;
    if (destination && destination.index !== source.index) {
      const sourceColumn = columns[source.index];
      const destinationColumn = columns[destination.index];
      if (sourceColumn && destinationColumn) {
        grid.switchColumnPos(sourceColumn.id, destinationColumn.id);
      }
    }
    // Force focus the header cell so the grid doesn't become unfocusable,
    // including on drag cancel
    const index = (destination ?? source).index + this.dataColumnOffset;
    setTimeout(() => {
      if (!grid.isDestroying) grid.setFocusedCell([index, -1], true);
    });
  }

  /** Scrolls the grid body horizontally while a header is dragged near its edges. */
  autoScrollGrid = modifier((element: HTMLElement) => {
    const scroller = element.closest<HTMLElement>('.euiDataGrid__virtualized');
    if (!scroller) return;
    return autoScrollForElements({
      element: scroller,
      canScroll: () => this.draggingColumnId != null && !this.isKeyboardDragging
    });
  });

  @action
  onKeyDownCapture(): void {
    this.wasDragging = this.draggingColumnId != null;
  }

  /** Keys pressed while a column is lifted are the drag's only (like upstream). */
  @action
  onKeyDown(event: KeyboardEvent): void {
    const isDragging = this.draggingColumnId != null;
    if (!this.wasDragging && !isDragging) return;
    if (isDragging && !this.wasDragging) this.isKeyboardDragging = true;
    event.preventDefault();
    event.stopPropagation();
  }

  <template>
    <div role="row" class={{this.classes}} data-test-subj="dataGridHeader" ...attributes>
      {{#each @grid.leadingControlColumns key="id" as |controlColumn index|}}
        <EuiDataGridHeaderCell
          @grid={{@grid}}
          @body={{@body}}
          @index={{index}}
          @controlColumn={{controlColumn}}
        >
          <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
        </EuiDataGridHeaderCell>
      {{/each}}
      {{#if this.canDragAndDropColumns}}
        <EuiDragDropContext
          @onDragStart={{this.onDragStart}}
          @onDragEnd={{this.onDragEnd}}
          @autoScrollWindow={{false}}
          as |dnd|
        >
          <dnd.Droppable
            @droppableId={{this.droppableId}}
            @direction="horizontal"
            @css={{this.droppableCss}}
            @autoScroll={{false}}
            data-test-subj="euiDataGridHeaderDroppable"
            {{on "keydown" this.onKeyDownCapture capture=true}}
            {{on "keydown" this.onKeyDown}}
            {{this.autoScrollGrid}}
            as |list|
          >
            {{#each @grid.columns key="id" as |column index|}}
              <list.Draggable
                @draggableId={{column.id}}
                @index={{index}}
                @customDragHandle="custom"
                @hasInteractiveChildren={{true}}
                @css={{this.draggableCss}}
                class="euiDataGridHeaderCellDraggable"
                as |item|
              >
                <EuiDataGridHeaderCell
                  @grid={{@grid}}
                  @body={{@body}}
                  @index={{add index this.dataColumnOffset}}
                  @column={{column}}
                  @dragHandle={{item.dragHandle}}
                  @isDragging={{item.isDragging}}
                  @isKeyboardDragging={{if item.isDragging this.isKeyboardDragging}}
                  @dragInstructionsId={{this.dragInstructionsId}}
                />
                {{! the resizer sits outside the drag handle so both work independently (after it: the header cell stays :first-of-type) }}
                {{#let (this.resizerWidth column) as |width|}}
                  {{#if width}}
                    <EuiDataGridColumnResizer
                      @columnId={{column.id}}
                      @columnWidth={{width}}
                      @setColumnWidth={{@body.setColumnWidth}}
                      @isLastColumn={{this.isLastColumn (add index this.dataColumnOffset)}}
                    />
                  {{/if}}
                {{/let}}
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
        <p id={{this.dragInstructionsId}} hidden>{{this.dragInstructions}}</p>
      {{else}}
        {{#each @grid.columns key="id" as |column index|}}
          <EuiDataGridHeaderCell
            @grid={{@grid}}
            @body={{@body}}
            @index={{add index this.dataColumnOffset}}
            @column={{column}}
          />
        {{/each}}
      {{/if}}
      {{#each @grid.trailingControlColumns key="id" as |controlColumn index|}}
        <EuiDataGridHeaderCell
          @grid={{@grid}}
          @body={{@body}}
          @index={{add index this.trailingOffset}}
          @controlColumn={{controlColumn}}
        >
          <:controlHeaderCell as |cell|>{{yield cell to="controlHeaderCell"}}</:controlHeaderCell>
        </EuiDataGridHeaderCell>
      {{/each}}
    </div>
  </template>
}

function add(a: number, b: number): number {
  return a + b;
}
