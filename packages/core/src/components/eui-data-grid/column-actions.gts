import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { tabbable } from 'tabbable';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridHeaderCellStyles } from '../../utils/eui/styles.generated.ts';
import { getDetailsForSchema } from '../../utils/data-grid/schema.ts';
import * as keys from '../../utils/keys.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiListGroup from '../eui-list-group.gts';
import EuiListGroupItem from '../eui-list-group-item.gts';
import EuiPopover from '../eui-popover.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnActionConfig,
  EuiDataGridColumnActions as ColumnActionsConfig,
  EuiDataGridSchemaDetector
} from '../../utils/data-grid/types.ts';

type ActionKey = Exclude<keyof ColumnActionsConfig, 'additional'>;

interface ColumnActionItem {
  label: string;
  iconType?: string;
  isDisabled?: boolean;
  color?: string;
  onClick: (event: MouseEvent) => void;
  'data-test-subj'?: string;
}

/** Upstream `useHasColumnActions`. */
export function hasColumnActions(actions: EuiDataGridColumn['actions']): boolean {
  // By default, all column actions are enabled
  if (actions === undefined) return true;
  if (actions === false) return false;
  if (actions.additional && actions.additional.length) return true;
  // Check if all (currently 5) default column actions have been manually disabled
  const disabled = Object.values(actions).filter((value) => value === false);
  return disabled.length < 5;
}

export function isColumnActionEnabled(
  actionKey: ActionKey,
  actions: EuiDataGridColumn['actions']
): boolean {
  if (actions === false) return false;
  if (actions?.[actionKey] === false) return false;
  return true;
}

function getColumnActionConfig(
  item: ColumnActionItem,
  actionKey: ActionKey,
  actions: EuiDataGridColumn['actions']
): ColumnActionItem {
  const configuration = actions !== false && actions?.[actionKey];
  return typeof configuration === 'object'
    ? { ...item, ...(configuration as EuiDataGridColumnActionConfig) }
    : item;
}

/** Resolve a schema sort label (plain text or an i18n token pair). */
export function sortLabel(
  euiI18n: EuiI18n,
  label: EuiDataGridSchemaDetector['sortTextAsc']
): string {
  return typeof label === 'string'
    ? label
    : euiI18n.lookupToken(label.token, label.default);
}

export const defaultSortAscLabel = {
  token: 'euiColumnSortingDraggable.defaultSortAsc',
  default: 'A-Z'
};
export const defaultSortDescLabel = {
  token: 'euiColumnSortingDraggable.defaultSortDesc',
  default: 'Z-A'
};

export interface EuiDataGridColumnActionsSignature {
  Args: {
    grid: EuiDataGrid;
    index: number;
    column: EuiDataGridColumn;
    title: string;
    hasFocusTrap: boolean;
    isPopoverOpen: boolean;
    setIsPopoverOpen: (isOpen: boolean) => void;
    setIsColumnMoving: (isMoving: boolean) => void;
  };
}

/** The header cell's "…" button and its column actions popover. */
export default class EuiDataGridColumnActions extends Component<EuiDataGridColumnActionsSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked private panel: HTMLElement | null = null;

  @cached
  get buttonCss() {
    const styles = useEuiBorealisStyles(getEuiThemeContext(this), euiDataGridHeaderCellStyles);
    return {
      popover: styles.euiDataGridHeaderCell__popover,
      button: [
        styles.euiDataGridHeaderCell__actions.action,
        styles.euiDataGridHeaderCell__actions.end
      ]
    };
  }

  get actionsButtonAriaLabel(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridHeaderCell.actionsButtonAriaLabel',
      '{title}. Click to view column header actions.',
      { title: this.args.title }
    );
  }

  get actionsEnterKeyInstructions(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridHeaderCell.actionsEnterKeyInstructions',
      "Press the Enter key to view this column's actions"
    );
  }

  get popoverScreenReaderText(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridHeaderCell.actionsPopoverScreenReaderText',
      'To navigate through the list of column actions, press the Tab or Up and Down arrow keys.'
    );
  }

  @action
  togglePopover(): void {
    this.args.setIsPopoverOpen(!this.args.isPopoverOpen);
  }

  @action
  closePopover(): void {
    this.args.setIsPopoverOpen(false);
  }

  /** Arrow key navigation through the actions, like the rest of the grid. */
  @action
  registerPanel(panel: HTMLElement | null): void {
    this.panel?.removeEventListener('keydown', this.onPanelKeyDown);
    this.panel = panel;
    panel?.addEventListener('keydown', this.onPanelKeyDown);
  }

  onPanelKeyDown = (event: KeyboardEvent): void => {
    if (event.key !== keys.ARROW_DOWN && event.key !== keys.ARROW_UP) return;
    const panel = this.panel;
    if (!panel) return;
    const actions = tabbable(panel) as HTMLElement[];
    if (!actions.length) return;
    event.preventDefault();
    const initialState = document.activeElement === panel;
    const currentIndex = initialState
      ? -1
      : actions.findIndex((element) => document.activeElement === element);
    const lastIndex = actions.length - 1;
    let indexToFocus: number;
    if (event.key === keys.ARROW_DOWN) {
      indexToFocus = initialState ? 0 : currentIndex + 1 > lastIndex ? 0 : currentIndex + 1;
    } else {
      indexToFocus = initialState
        ? lastIndex
        : currentIndex - 1 < 0
          ? lastIndex
          : currentIndex - 1;
    }
    actions[indexToFocus]!.focus();
  };

  /* actions ------------------------------------------------------------ */

  get items(): ColumnActionItem[] {
    const { column } = this.args;
    if (column.actions === false) return [];
    const items = [
      ...this.hideColumnAction,
      ...this.sortColumnActions,
      ...this.moveColumnActions,
      ...((column.actions?.additional ?? []) as unknown as ColumnActionItem[])
    ];
    return items.map((item) => ({
      ...item,
      // close the popover and prevent bubbling up
      onClick: (event: MouseEvent) => {
        event.stopPropagation();
        this.args.setIsPopoverOpen(false);
        item.onClick?.(event);
      }
    }));
  }

  get hideColumnAction(): ColumnActionItem[] {
    const { grid, column } = this.args;
    if (!isColumnActionEnabled('showHide', column.actions)) return [];
    const item: ColumnActionItem = {
      label: this.euiI18n.lookupToken('euiColumnActions.hideColumn', 'Hide column'),
      onClick: () => {
        grid.setVisibleColumns(
          grid.columns.filter((col) => col.id !== column.id).map((col) => col.id)
        );
        // Since we hid the current column, set focus back onto the grid
        grid.focusFirstVisibleInteractiveCell();
      },
      iconType: 'eyeSlash',
      color: 'text',
    };
    return [getColumnActionConfig(item, 'showHide', column.actions)];
  }

  get moveColumnActions(): ColumnActionItem[] {
    const { grid, column, index } = this.args;
    const columns = grid.columns;
    const colIdx = columns.findIndex((col) => col.id === column.id);
    const items: ColumnActionItem[] = [];

    // prevent the column actions hover animation from flashing after a move
    const handleAnimationFlash = () => {
      this.args.setIsColumnMoving(true);
      requestAnimationFrame(() => this.args.setIsColumnMoving(false));
    };
    const moveFocus = (direction: 'left' | 'right') => {
      // wait a beat so the popover's focus return does not steal it
      setTimeout(() => {
        grid.setFocusedCell([index + (direction === 'left' ? -1 : 1), -1]);
      });
    };

    if (isColumnActionEnabled('showMoveLeft', column.actions)) {
      items.push(
        getColumnActionConfig(
          {
            label: this.euiI18n.lookupToken('euiColumnActions.moveLeft', 'Move left'),
            iconType: 'sortLeft',
            color: 'text',
            isDisabled: colIdx === 0,
            onClick: () => {
              const target = columns[colIdx - 1];
              if (target) {
                grid.switchColumnPos(column.id, target.id);
                handleAnimationFlash();
                moveFocus('left');
              }
            }
          },
          'showMoveLeft',
          column.actions
        )
      );
    }
    if (isColumnActionEnabled('showMoveRight', column.actions)) {
      items.push(
        getColumnActionConfig(
          {
            label: this.euiI18n.lookupToken('euiColumnActions.moveRight', 'Move right'),
            iconType: 'sortRight',
            color: 'text',
            isDisabled: colIdx === columns.length - 1,
            onClick: () => {
              const target = columns[colIdx + 1];
              if (target) {
                grid.switchColumnPos(column.id, target.id);
                handleAnimationFlash();
                moveFocus('right');
              }
            }
          },
          'showMoveRight',
          column.actions
        )
      );
    }
    return items;
  }

  get sortColumnActions(): ColumnActionItem[] {
    const { grid, column } = this.args;
    const sorting = grid.args.sorting;
    if (!sorting) return [];
    const schema = grid.schema;
    const sortingIdx = sorting.columns.findIndex((col) => col.id === column.id);
    const columnType = schema[column.id]?.columnType;
    const schemaDetails =
      columnType != null ? getDetailsForSchema(grid.schemaDetectors, columnType) : null;

    const sortBy = (direction: 'asc' | 'desc') => {
      if (sortingIdx >= 0 && sorting.columns[sortingIdx]?.direction === direction) {
        // unsort if the same current and new direction are same
        sorting.onSort(sorting.columns.filter((_, idx) => idx !== sortingIdx));
      } else if (sortingIdx >= 0) {
        // replace existing sort
        const next = [...sorting.columns];
        next[sortingIdx] = { id: column.id, direction };
        sorting.onSort(next);
      } else {
        // add new sort
        sorting.onSort([...sorting.columns, { id: column.id, direction }]);
      }
    };

    const items: ColumnActionItem[] = [];
    const makeItem = (
      direction: 'asc' | 'desc',
      key: ActionKey,
      iconType: string,
      labelSource: EuiDataGridSchemaDetector['sortTextAsc']
    ) => {
      const schemaLabel = sortLabel(this.euiI18n, labelSource);
      const isSorted =
        sortingIdx >= 0 && sorting.columns[sortingIdx]!.direction === direction;
      items.push(
        getColumnActionConfig(
          {
            label: isSorted
              ? this.euiI18n.lookupToken('euiColumnActions.unsort', 'Unsort {schemaLabel}', {
                  schemaLabel
                })
              : this.euiI18n.lookupToken('euiColumnActions.sort', 'Sort {schemaLabel}', {
                  schemaLabel
                }),
            onClick: () => sortBy(direction),
            isDisabled: column.isSortable === false,
            iconType,
            color: 'text'
          },
          key,
          column.actions
        )
      );
    };
    if (isColumnActionEnabled('showSortAsc', column.actions)) {
      makeItem(
        'asc',
        'showSortAsc',
        'sortUp',
        schemaDetails ? schemaDetails.sortTextAsc : defaultSortAscLabel
      );
    }
    if (isColumnActionEnabled('showSortDesc', column.actions)) {
      makeItem(
        'desc',
        'showSortDesc',
        'sortDown',
        schemaDetails ? schemaDetails.sortTextDesc : defaultSortDescLabel
      );
    }
    return items;
  }

  <template>
    <EuiPopover
      @display="block"
      @panelPaddingSize="s"
      @offset={{7}}
      @anchorPosition="downRight"
      @css={{this.buttonCss.popover}}
      @isOpen={{@isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelRef={{this.registerPanel}}
      @popoverScreenReaderText={{this.popoverScreenReaderText}}
    >
      <:button>
        <EuiButtonIcon
          @iconType="ellipsis"
          @iconSize="s"
          @color="text"
          class="euiDataGridHeaderCell__button"
          aria-label={{if @hasFocusTrap this.actionsButtonAriaLabel this.actionsEnterKeyInstructions}}
          @css={{this.buttonCss.button}}
          data-test-subj="dataGridHeaderCellActionButton-{{@column.id}}"
          {{on "click" this.togglePopover}}
        />
      </:button>
      <:content>
        <EuiListGroup data-test-subj="dataGridHeaderCellActionGroup-{{@column.id}}">
          {{#each this.items as |item|}}
            <EuiListGroupItem
              @label={{item.label}}
              @iconType={{item.iconType}}
              @isDisabled={{item.isDisabled}}
              @color={{item.color}}
              @onClick={{item.onClick}}
              data-test-subj={{item.data-test-subj}}
            />
          {{/each}}
        </EuiListGroup>
      </:content>
    </EuiPopover>
  </template>
}
