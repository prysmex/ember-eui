import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { afterRender } from '../../utils/data-grid/scheduling.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridColumnSortingStyles } from '../../utils/eui/styles.generated.ts';
import { euiDragDropReorder } from '../../utils/drag-drop.ts';
import { getDetailsForSchema } from '../../utils/data-grid/schema.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiButtonGroup from '../eui-button-group.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiDataGridToolbarControl from '../eui-data-grid-toolbar-control.gts';
import EuiDragDropContext from '../eui-drag-drop-context.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiIcon from '../eui-icon.gts';
import EuiPopover from '../eui-popover.gts';
import EuiPopoverFooter from '../eui-popover-footer.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiText from '../eui-text.gts';
import EuiToken from '../eui-token.gts';
import { defaultSortAscLabel, defaultSortDescLabel, sortLabel } from './column-actions.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { DropResult } from '../eui-drag-drop-context.gts';
import type {
  EuiDataGridColumn,
  EuiDataGridSchemaDetector,
  EuiDataGridSorting,
  EuiDataGridSortingColumn
} from '../../utils/data-grid/types.ts';

export interface EuiDataGridColumnSortingSignature {
  Args: { grid: EuiDataGrid; sorting: EuiDataGridSorting };
}

/** Toolbar "Sort fields" popover: sorted columns (drag to reorder) and field picker. */
export default class EuiDataGridColumnSorting extends Component<EuiDataGridColumnSortingSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;
  @tracked availableColumnsIsOpen = false;

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridColumnSortingStyles);
    return {
      list: styles.euiDataGridColumnSorting,
      dragHandle: styles.euiDataGridColumnSorting__dragHandle,
      item: styles.euiDataGridColumnSorting__item,
      name: styles.euiDataGridColumnSorting__name,
      order: styles.euiDataGridColumnSorting__order,
      fieldList: `euiDataGridColumnSorting__fieldList ${euiClass(context, styles.euiDataGridColumnSorting__fieldList)}`,
      field: `euiDataGridColumnSorting__field ${euiClass(context, styles.euiDataGridColumnSorting__field)}`
    };
  }

  /** Visible columns (sorting pruning and the field picker only consider these). */
  get columns(): EuiDataGridColumn[] {
    return this.args.grid.columns;
  }

  /** Prune sorted columns that are hidden or no longer exist (upstream effect). */
  pruneSorting = modifier(
    (_element: HTMLElement, [sorting, columns]: [EuiDataGridSorting, EuiDataGridColumn[]]) => {
      const available = new Set(columns.map(({ id }) => id));
      const next = sorting.columns.filter((column) => available.has(column.id));
      // after render: consumers update tracked state in onSort
      if (next.length !== sorting.columns.length) afterRender(this, () => sorting.onSort(next));
    }
  );

  get inactiveSortableColumns(): EuiDataGridColumn[] {
    const active = new Set(this.args.sorting.columns.map(({ id }) => id));
    return this.columns.filter((column) => {
      if (active.has(column.id)) return false;
      if (column.isSortable != null) return column.isSortable;
      const details = this.schemaDetails(column.id);
      if (details != null) return details.isSortable ?? true;
      return true;
    });
  }

  schemaDetails = (id: string): EuiDataGridSchemaDetector | null | undefined => {
    const { schema, schemaDetectors } = this.args.grid;
    const columnType = schema[id]?.columnType;
    return columnType != null ? getDetailsForSchema(schemaDetectors, columnType) : null;
  };

  tokenIcon = (id: string): string => this.schemaDetails(id)?.icon ?? 'tokenString';
  tokenColor = (id: string): string | undefined => this.schemaDetails(id)?.color;
  display = (id: string): string => this.args.grid.displayValues[id] ?? id;

  get showFooter(): boolean {
    return this.inactiveSortableColumns.length > 0 || this.args.sorting.columns.length > 0;
  }

  t = (token: string, fallback: string, values?: Record<string, unknown>): string =>
    this.euiI18n.lookupToken(token, fallback, values);

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  @action
  toggleAvailableColumns(): void {
    this.availableColumnsIsOpen = !this.availableColumnsIsOpen;
  }

  @action
  closeAvailableColumns(): void {
    this.availableColumnsIsOpen = false;
  }

  @action
  onDragEnd({ source, destination }: DropResult): void {
    if (!destination) return;
    const { sorting } = this.args;
    sorting.onSort(euiDragDropReorder(sorting.columns, source.index, destination.index));
  }

  @action
  addSort(column: EuiDataGridColumn): void {
    const { sorting } = this.args;
    sorting.onSort([
      ...sorting.columns,
      {
        id: column.id,
        direction:
          column.defaultSortDirection ||
          this.schemaDetails(column.id)?.defaultSortDirection ||
          'asc'
      }
    ]);
  }

  @action
  clearSorting(): void {
    this.args.sorting.onSort([]);
  }

  @action
  removeSort(id: string): void {
    const next = [...this.args.sorting.columns];
    next.splice(
      next.map(({ id: columnId }) => columnId).indexOf(id),
      1
    );
    this.args.sorting.onSort(next);
  }

  @action
  setDirection(id: string, selectedId: string): void {
    const direction: EuiDataGridSortingColumn['direction'] = selectedId.endsWith('Desc')
      ? 'desc'
      : 'asc';
    const next = [...this.args.sorting.columns];
    next.splice(next.map(({ id: columnId }) => columnId).indexOf(id), 1, { id, direction });
    this.args.sorting.onSort(next);
  }

  directionOptions = (id: string) => {
    const details = this.schemaDetails(id);
    return [
      {
        id: `${id}Asc`,
        value: 'asc',
        label: sortLabel(this.euiI18n, details ? details.sortTextAsc : defaultSortAscLabel),
        'data-test-subj': `euiDataGridColumnSorting-sortColumn-${id}-asc`
      },
      {
        id: `${id}Desc`,
        value: 'desc',
        label: sortLabel(this.euiI18n, details ? details.sortTextDesc : defaultSortDescLabel),
        'data-test-subj': `euiDataGridColumnSorting-sortColumn-${id}-desc`
      }
    ];
  };

  selectedDirection = (id: string, direction: string): string =>
    direction === 'asc' ? `${id}Asc` : `${id}Desc`;

  itemClass = (isDragging: boolean): string =>
    `euiDataGridColumnSorting__item${isDragging ? ' euiDataGridColumnSorting__item-isDragging' : ''}`;

  <template>
    <EuiPopover
      data-test-subj="dataGridColumnSortingPopover"
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition="downLeft"
      @panelPaddingSize="s"
      {{this.pruneSorting @sorting this.columns}}
    >
      <:button>
        <EuiDataGridToolbarControl
          @badgeContent={{@sorting.columns.length}}
          @iconType="sortable"
          data-test-subj="dataGridColumnSortingButton"
          {{on "click" this.toggle}}
        >{{this.t "euiColumnSorting.button" "Sort fields"}}</EuiDataGridToolbarControl>
      </:button>
      <:content>
        {{#if @sorting.columns.length}}
          <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
            <dnd.Droppable @droppableId="columnSorting" @css={{this.classes.list}} as |list|>
              {{#each @sorting.columns key="id" as |column index|}}
                <list.Draggable
                  @draggableId={{column.id}}
                  @index={{index}}
                  @hasInteractiveChildren={{true}}
                  @customDragHandle={{true}}
                  class="euiDataGridColumnSorting__dragHandle"
                  @css={{this.classes.dragHandle}}
                  as |item|
                >
                  <EuiFlexGroup
                    class={{this.itemClass item.isDragging}}
                    @css={{this.classes.item}}
                    @gutterSize="xs"
                    @alignItems="center"
                    @responsive={{false}}
                    data-test-subj="euiDataGridColumnSorting-sortColumn-{{column.id}}"
                  >
                    <EuiScreenReaderOnly>
                      <p>{{this.t
                          "euiColumnSortingDraggable.activeSortLabel"
                          "{display} is sorting this data grid"
                          (hash display=(this.display column.id))
                        }}</p>
                    </EuiScreenReaderOnly>
                    <EuiFlexItem @grow={{false}}>
                      <EuiButtonIcon
                        @color="text"
                        class="euiDataGridColumnSorting__button"
                        aria-label={{this.t
                          "euiColumnSortingDraggable.removeSortLabel"
                          "Remove {display} from data grid sort"
                          (hash display=(this.display column.id))
                        }}
                        @iconType="cross"
                        {{on "click" (fn this.removeSort column.id)}}
                      />
                    </EuiFlexItem>
                    {{! the name is extra grab area for mouse users, hidden from AT }}
                    <EuiFlexItem
                      class="euiDataGridColumnSorting__name"
                      @css={{this.classes.name}}
                      tabindex="-1"
                      aria-hidden="true"
                    >
                      <EuiFlexGroup @gutterSize="xs" @alignItems="center" @responsive={{false}}>
                        <EuiFlexItem @grow={{false}}>
                          <EuiToken
                            @color={{this.tokenColor column.id}}
                            @iconType={{this.tokenIcon column.id}}
                          />
                        </EuiFlexItem>
                        <EuiFlexItem>
                          <EuiText @size="xs">{{this.display column.id}}</EuiText>
                        </EuiFlexItem>
                      </EuiFlexGroup>
                    </EuiFlexItem>
                    <EuiFlexItem>
                      <EuiButtonGroup
                        class="euiDataGridColumnSorting__order"
                        @css={{this.classes.order}}
                        @legend={{this.t
                          "euiColumnSortingDraggable.toggleLegend"
                          "Select sorting method for {display}"
                          (hash display=(this.display column.id))
                        }}
                        @isFullWidth={{true}}
                        @buttonSize="s"
                        @options={{this.directionOptions column.id}}
                        @idSelected={{this.selectedDirection column.id column.direction}}
                        @onChange={{fn this.setDirection column.id}}
                      />
                    </EuiFlexItem>
                    <EuiFlexItem @grow={{false}}>
                      <span
                        aria-label={{this.t "euiColumnSortingDraggable.dragHandleAriaLabel" "Drag handle"}}
                        {{item.dragHandle}}
                      ><EuiIcon @type="dragVertical" @color="subdued" /></span>
                    </EuiFlexItem>
                  </EuiFlexGroup>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        {{else}}
          <EuiText @size="s" @color="subdued">
            <p role="alert">{{this.t "euiColumnSorting.emptySorting" "Currently no fields are sorted"}}</p>
          </EuiText>
        {{/if}}
        {{#if this.showFooter}}
          <EuiPopoverFooter>
            <EuiFlexGroup @gutterSize="m" @justifyContent="spaceBetween" @responsive={{false}}>
              <EuiFlexItem @grow={{false}}>
                {{#if this.inactiveSortableColumns.length}}
                  <EuiPopover
                    data-test-subj="dataGridColumnSortingPopoverColumnSelection"
                    @isOpen={{this.availableColumnsIsOpen}}
                    @closePopover={{this.closeAvailableColumns}}
                    @anchorPosition="downLeft"
                    @panelPaddingSize="none"
                  >
                    <:button>
                      <EuiButtonEmpty
                        @size="xs"
                        @flush="left"
                        @iconType="chevronSingleDown"
                        @iconSide="right"
                        data-test-subj="dataGridColumnSortingSelectionButton"
                        {{on "click" this.toggleAvailableColumns}}
                      >{{this.t "euiColumnSorting.pickFields" "Pick fields to sort by"}}</EuiButtonEmpty>
                    </:button>
                    <:content>
                      <div class={{this.classes.fieldList}} role="listbox">
                        {{#each this.inactiveSortableColumns key="id" as |column|}}
                          <button
                            type="button"
                            class={{this.classes.field}}
                            aria-label="{{this.t 'euiColumnSorting.sortFieldAriaLabel' 'Sort by: '}} {{column.id}}"
                            role="option"
                            aria-selected="false"
                            data-test-subj="dataGridColumnSortingPopoverColumnSelection-{{column.id}}"
                            {{on "click" (fn this.addSort column)}}
                          >
                            <EuiFlexGroup @alignItems="center" @gutterSize="s" @tagName="span" @responsive={{false}}>
                              <EuiFlexItem @grow={{false}} @tagName="span">
                                <EuiToken
                                  @iconType={{this.tokenIcon column.id}}
                                  @color={{this.tokenColor column.id}}
                                />
                              </EuiFlexItem>
                              <EuiFlexItem @grow={{false}} @tagName="span">
                                <EuiText @size="xs">{{this.display column.id}}</EuiText>
                              </EuiFlexItem>
                            </EuiFlexGroup>
                          </button>
                        {{/each}}
                      </div>
                    </:content>
                  </EuiPopover>
                {{/if}}
              </EuiFlexItem>
              {{#if @sorting.columns.length}}
                <EuiFlexItem @grow={{false}}>
                  <EuiButtonEmpty
                    @size="xs"
                    @flush="right"
                    data-test-subj="dataGridColumnSortingClearButton"
                    {{on "click" this.clearSorting}}
                  >{{this.t "euiColumnSorting.clearAll" "Clear sorting"}}</EuiButtonEmpty>
                </EuiFlexItem>
              {{/if}}
            </EuiFlexGroup>
          </EuiPopoverFooter>
        {{/if}}
      </:content>
    </EuiPopover>
  </template>
}
