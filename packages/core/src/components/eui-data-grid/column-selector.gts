import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { not } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridColumnSelectorStyles } from '../../utils/eui/styles.generated.ts';
import { euiDragDropReorder } from '../../utils/drag-drop.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiDataGridToolbarControl from '../eui-data-grid-toolbar-control.gts';
import EuiDragDropContext from '../eui-drag-drop-context.gts';
import EuiFieldText from '../eui-field-text.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiIcon from '../eui-icon.gts';
import EuiPopover from '../eui-popover.gts';
import EuiPopoverFooter from '../eui-popover-footer.gts';
import EuiPopoverTitle from '../eui-popover-title.gts';
import EuiSwitch from '../eui-switch.gts';
import EuiText from '../eui-text.gts';
import { getNestedObjectOptions } from './toolbar-utils.ts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { DropResult } from '../eui-drag-drop-context.gts';

export interface EuiDataGridColumnSelectorSignature {
  Args: { grid: EuiDataGrid };
}

/** Toolbar "Columns" popover: search, show/hide and drag to reorder columns. */
export default class EuiDataGridColumnSelector extends Component<EuiDataGridColumnSelectorSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;
  @tracked columnSearchText = '';

  get showColumnSelector() {
    const visibility = this.args.grid.args.toolbarVisibility;
    if (visibility === undefined || typeof visibility === 'boolean') return visibility ?? true;
    return visibility.showColumnSelector;
  }

  get allowColumnHiding(): boolean {
    return getNestedObjectOptions(this.showColumnSelector, 'allowHide');
  }

  get allowColumnReorder(): boolean {
    return getNestedObjectOptions(this.showColumnSelector, 'allowReorder');
  }

  get show(): boolean {
    return this.allowColumnHiding || this.allowColumnReorder;
  }

  get sortedColumns(): string[] {
    return this.args.grid.sortedColumns;
  }

  @cached
  get visibleColumnIds(): Set<string> {
    return new Set(this.args.grid.visibleColumnIds);
  }

  get numberOfHiddenFields(): number {
    return this.args.grid.args.columns.length - this.args.grid.visibleColumnIds.length;
  }

  get badgeContent(): string | number {
    return this.numberOfHiddenFields > 0
      ? `${this.args.grid.columns.length}/${this.sortedColumns.length}`
      : this.sortedColumns.length;
  }

  get filteredColumns(): string[] {
    const search = this.columnSearchText.toLowerCase();
    const displayValues = this.args.grid.displayValues;
    return this.sortedColumns.filter(
      (id) => (displayValues[id] || id).toLowerCase().indexOf(search) !== -1
    );
  }

  /** Only allow drag and drop when not filtering columns. */
  get isDragEnabled(): boolean {
    return this.allowColumnReorder && this.columnSearchText.length === 0;
  }

  get dragHandleAriaLabel(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.dragHandleAriaLabel', 'drag handle');
  }

  get buttonText(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.button', 'Columns');
  }

  get searchPlaceholder(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.search', 'Search');
  }

  get searchAriaLabel(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.searchcolumns', 'Search columns');
  }

  get showAllText(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.selectAll', 'Show all');
  }

  get hideAllText(): string {
    return this.euiI18n.lookupToken('euiColumnSelector.hideAll', 'Hide all');
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridColumnSelectorStyles);
    return {
      list: euiClass(context, styles.euiDataGridColumnSelector),
      item: `euiDataGridColumnSelector__item ${euiClass(context, styles.euiDataGridColumnSelector__item)}`
    };
  }

  label = (id: string): string => this.args.grid.displayValues[id] || id;

  isVisible = (id: string): boolean => this.visibleColumnIds.has(id);

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  @action
  onSearch(event: Event): void {
    this.columnSearchText = (event.target as HTMLInputElement).value;
  }

  @action
  toggleColumn(id: string): void {
    const checked = !this.visibleColumnIds.has(id);
    const visible = this.visibleColumnIds;
    this.args.grid.setVisibleColumns(
      this.sortedColumns.filter((columnId) =>
        checked
          ? visible.has(columnId) || id === columnId
          : visible.has(columnId) && id !== columnId
      )
    );
  }

  @action
  onDragEnd({ source, destination }: DropResult): void {
    if (!destination) return;
    this.args.grid.setSortedColumns(
      euiDragDropReorder(this.sortedColumns, source.index, destination.index)
    );
  }

  @action
  showAll(): void {
    this.args.grid.setVisibleColumns(this.sortedColumns);
  }

  @action
  hideAll(): void {
    this.args.grid.setVisibleColumns([]);
  }

  itemClass = (isDragging: boolean): string =>
    `${this.classes.item}${isDragging ? ' euiDataGridColumnSelector__item-isDragging' : ''}`;

  <template>
    {{#if this.show}}
      <EuiPopover
        data-test-subj="dataGridColumnSelectorPopover"
        @isOpen={{this.isOpen}}
        @closePopover={{this.close}}
        @anchorPosition="downLeft"
        @panelPaddingSize="none"
      >
        <:button>
          <EuiDataGridToolbarControl
            @badgeContent={{this.badgeContent}}
            @iconType="table"
            data-test-subj="dataGridColumnSelectorButton"
            {{on "click" this.toggle}}
          >{{this.buttonText}}</EuiDataGridToolbarControl>
        </:button>
        <:content>
          {{#if this.allowColumnHiding}}
            <EuiPopoverTitle @paddingSize="s">
              <EuiFieldText
                @compressed={{true}}
                @placeholder={{this.searchPlaceholder}}
                @value={{this.columnSearchText}}
                aria-label={{this.searchAriaLabel}}
                data-test-subj="dataGridColumnSelectorSearch"
                {{on "input" this.onSearch}}
              />
            </EuiPopoverTitle>
          {{/if}}
          {{! EuiDroppable has no @css: the list styles go on a wrapper }}
          <div class={{this.classes.list}}>
          <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
            <dnd.Droppable
              @droppableId="columnOrder"
              @isDropDisabled={{not this.isDragEnabled}}
              as |list|
            >
              {{#each this.filteredColumns key="@identity" as |id index|}}
                <list.Draggable
                  @draggableId={{id}}
                  @index={{index}}
                  @isDragDisabled={{not this.isDragEnabled}}
                  @hasInteractiveChildren={{true}}
                  @customDragHandle={{true}}
                  as |item|
                >
                  <div
                    class={{this.itemClass item.isDragging}}
                    data-test-subj="dataGridColumnSelectorColumnItem-{{id}}"
                  >
                    <EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="center">
                      {{#if this.allowColumnHiding}}
                        <EuiFlexItem @grow={{false}}>
                          <EuiSwitch
                            name={{id}}
                            @label={{this.label id}}
                            @showLabel={{false}}
                            @checked={{this.isVisible id}}
                            @mini={{true}}
                            @onChange={{fn this.toggleColumn id}}
                            data-test-subj="dataGridColumnSelectorToggleColumnVisibility-{{id}}"
                          />
                        </EuiFlexItem>
                      {{/if}}
                      {{! the label is extra grab area for mouse users, hidden from AT }}
                      <EuiFlexItem aria-hidden="true">
                        <EuiText @size="xs" class="euiDataGridColumnSelector__itemLabel">
                          {{this.label id}}
                        </EuiText>
                      </EuiFlexItem>
                      {{#if this.isDragEnabled}}
                        <EuiFlexItem @grow={{false}}>
                          <span
                            class="euiDataGridColumnSelector__dragHandle"
                            aria-label="{{this.label id}} {{this.dragHandleAriaLabel}}"
                            {{item.dragHandle}}
                          ><EuiIcon @type="dragVertical" @color="subdued" /></span>
                        </EuiFlexItem>
                      {{/if}}
                    </EuiFlexGroup>
                  </div>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
          </div>
          {{#if this.allowColumnHiding}}
            <EuiPopoverFooter @paddingSize="s">
              <EuiFlexGroup @gutterSize="s" @responsive={{false}} @justifyContent="spaceBetween">
                <EuiFlexItem @grow={{false}}>
                  <EuiButtonEmpty
                    @size="xs"
                    @flush="left"
                    data-test-subj="dataGridColumnSelectorShowAllButton"
                    {{on "click" this.showAll}}
                  >{{this.showAllText}}</EuiButtonEmpty>
                </EuiFlexItem>
                <EuiFlexItem @grow={{false}}>
                  <EuiButtonEmpty
                    @size="xs"
                    @flush="right"
                    data-test-subj="dataGridColumnSelectorHideAllButton"
                    {{on "click" this.hideAll}}
                  >{{this.hideAllText}}</EuiButtonEmpty>
                </EuiFlexItem>
              </EuiFlexGroup>
            </EuiPopoverFooter>
          {{/if}}
        </:content>
      </EuiPopover>
    {{/if}}
  </template>
}
