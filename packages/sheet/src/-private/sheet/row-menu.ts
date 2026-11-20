/** The row menu and the context menu (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

import { valueOf } from '../../core/index.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { LayerAnchor } from '../layer.gts';
import type { RowMenuItem } from '../row-menu.gts';
import type { MenuState, WrapperBox } from './types.ts';

/** Menu items whose action moves focus itself. */
const MENU_ITEMS_THAT_MOVE_FOCUS = new Set([
  'insertAbove',
  'insertBelow',
  'duplicate',
  'expand',
  'delete'
]);

export default class SheetRowMenu<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The open row menu. */
  @tracked menu: MenuState | null = null;

  /** The row menu's anchor in the viewport (the layer reads it at every placement). */
  menuAnchor = (): LayerAnchor | null =>
    this.menu ? this.sheet.dom.toViewport(this.menu.anchor) : null;

  /* -------------------------------------------------------------------- */
  /* The row menu                                                          */
  /* -------------------------------------------------------------------- */

  /** Opens the menu under a cell (Shift+F10, the ContextMenu key). */
  openMenuAt(row: number, col: number | null, cell: HTMLElement): void {
    const rect = this.sheet.dom.rectOf(cell);
    if (!rect) return;
    // the keyboard path acts on the selection, or on this row
    if (
      col === null &&
      !this.sheet.selection.isRowSelected(row) &&
      !this.sheet.checked.checkedRecords.length
    ) {
      this.sheet.focus.keepRangeOnFocus = true;
      this.sheet.selection.selectRows(row, false);
    }
    this.openMenu(row, col, rect);
  }

  openMenu(row: number, col: number | null, anchor: WrapperBox): void {
    if (this.sheet.edit.editing) this.sheet.edit.commit({ refocus: false });
    const records = this.sheet.selection.selectionRecords();
    const record = this.sheet.rows.recordAt(row);
    this.menu = {
      row,
      col,
      anchor: {
        top: anchor.top,
        left: anchor.left,
        width: anchor.width,
        height: anchor.height
      },
      records: records.length ? records : record === undefined ? [] : [record]
    };
    document.addEventListener('mousedown', this.onDocumentMouseDown, true);
  }

  /** Closes the menu; `refocus` focuses the cell it was opened on. */
  closeMenu(refocus: boolean): void {
    const menu = this.menu;
    document.removeEventListener('mousedown', this.onDocumentMouseDown, true);
    if (!menu) return;
    this.menu = null;
    if (!refocus || menu.row >= this.sheet.rows.rowCount) return;
    if (menu.col === null) {
      this.sheet.focus.keepRangeOnFocus = true;
      this.sheet.dom.focusRowNumberCell(menu.row);
    } else {
      // onFocusIn sees the cell it already knows and keeps the range
      this.sheet.focus.domCursor = { row: menu.row, col: menu.col };
      this.sheet.dom.focusGridCell({ row: menu.row, col: menu.col });
    }
  }

  /** A press outside the menu closes it. */
  onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.sheet.dom.isInMenu(event.target)) return;
    // the mouse events a browser sends after the long press that opened it
    if (this.sheet.touch.longPressOpened) return;
    this.closeMenu(false);
  };

  get menuItems(): RowMenuItem[] {
    const menu = this.menu;
    if (!menu) return [];
    const records = menu.records as T[];
    const count = records.length;
    const messages = this.sheet.messages;
    const items: RowMenuItem[] = [];
    if (this.sheet.canInsert) {
      items.push(
        {
          id: 'insertAbove',
          label: messages.insertAbove(),
          icon: 'sortUp',
          onSelect: () =>
            this.sheet.records.insertNear(
              menu.row,
              'before',
              this.menuFieldId(menu)
            )
        },
        {
          id: 'insertBelow',
          label: messages.insertBelow(),
          icon: 'sortDown',
          onSelect: () =>
            this.sheet.records.insertNear(
              menu.row,
              'after',
              this.menuFieldId(menu)
            )
        },
        {
          id: 'duplicate',
          label:
            count > 1
              ? messages.duplicateRecords(count)
              : messages.duplicateRecord(),
          icon: 'copy',
          disabled: !count,
          onSelect: () =>
            this.sheet.records.duplicate(records, this.menuFieldId(menu))
        }
      );
    }
    if (count === 1) {
      items.push({
        id: 'expand',
        label: messages.expandRecord(),
        icon: 'expand',
        onSelect: () => {
          const recordId = this.sheet.args.getRecordId(records[0]!);
          this.sheet.expanded.expandRecord(recordId, {
            recordId,
            fieldId: this.menuFieldId(menu)
          });
        }
      });
    }
    const link = this.menuLink(menu);
    if (link) {
      items.push({
        id: 'openLink',
        label: messages.openLink(),
        icon: 'popout',
        onSelect: () => this.sheet.cells.openLink(link)
      });
    }
    items.push({
      id: 'copy',
      label: count > 1 ? messages.copyRows(count) : messages.copyRow(),
      icon: 'copyClipboard',
      disabled: !count,
      onSelect: () => this.sheet.clipboard.copyRows(records)
    });
    for (const action of this.sheet.args.rowActions ?? []) {
      items.push({
        id: action.id,
        label: action.label,
        icon: action.icon,
        color: action.color,
        disabled: action.isDisabled?.(records) ?? false,
        onSelect: () => action.onSelect(records)
      });
    }
    if (this.sheet.canDelete) {
      items.push({
        id: 'delete',
        label:
          count > 1 ? messages.deleteRecords(count) : messages.deleteRecord(),
        icon: 'trash',
        color: 'danger',
        disabled: !count,
        onSelect: () =>
          this.sheet.records.deleteRecordIds(
            records.map((record) => this.sheet.args.getRecordId(record)),
            { fieldId: this.menuFieldId(menu) }
          )
      });
    }
    return items;
  }

  /** The link of the cell the menu was opened on, if it has one. */
  menuLink(menu: MenuState): string | undefined {
    if (menu.col === null) return undefined;
    const record = this.sheet.rows.recordAt(menu.row);
    const field = this.sheet.fields.visibleFields[menu.col];
    if (record === undefined || !field) return undefined;
    return this.sheet.cells.linkOf(
      this.sheet.fields.typeOf(field),
      field,
      valueOf(record, field.id)
    );
  }

  /** The field the menu was opened on; the first one from a row number. */
  menuFieldId(menu: MenuState): string | null {
    const col = menu.col ?? 0;
    return (
      this.sheet.fields.visibleFields[col]?.id ??
      this.sheet.fields.visibleFields[0]?.id ??
      null
    );
  }

  onMenuSelect = (item: RowMenuItem): void => {
    // focus goes back to the cell, unless the action moves it (to a new
    // row, a remaining row, the expanded record)
    this.closeMenu(!MENU_ITEMS_THAT_MOVE_FOCUS.has(item.id));
    item.onSelect();
  };

  /** The grid row of a data cell or a row-number cell on a record; -1 elsewhere. */
  menuRowOf(target: Element): number {
    const rowCell = this.sheet.dom.rowNumberCell(target);
    const cell = rowCell ? null : this.sheet.dom.dataCell(target);
    const row = rowCell
      ? this.sheet.dom.rowIndexOf(rowCell)
      : cell
        ? this.sheet.dom.cursor(cell).row
        : -1;
    return this.sheet.rows.isRecordRow(row) ? row : -1;
  }

  /** Right-click on a data cell or a row number: the row menu. */
  @action
  onContextMenu(event: MouseEvent): void {
    const target = event.target as Element;
    // the ContextMenu key's own event, once focus is in the menu: not the
    // browser's menu over it; and a long press that already opened it
    if (this.sheet.dom.isInMenu(target) || this.sheet.touch.longPressOpened) {
      event.preventDefault();
      return;
    }
    this.sheet.touch.cancelLongPress();
    // a header's menu is a popover that closes on a press outside it: where
    // the browser fires contextmenu on the press (Linux, macOS), the release
    // that follows would close it at once, so it opens after the release
    if ((event.buttons & 2) !== 0 && this.sheet.dom.headerCell(target)) {
      event.preventDefault();
      const open = (): void => {
        window.removeEventListener('mouseup', onUp, true);
        clearTimeout(timer);
        requestAnimationFrame(() => {
          if (!this.sheet.isDestroying && !this.sheet.isDestroyed) {
            this.openContextMenu(target, event.clientX, event.clientY);
          }
        });
      };
      const onUp = (up: MouseEvent): void => {
        if (up.button === 2) open();
      };
      window.addEventListener('mouseup', onUp, true);
      // a release outside the window never comes
      const timer = setTimeout(open, 1000);
      return;
    }
    if (this.openContextMenu(target, event.clientX, event.clientY)) {
      event.preventDefault();
    }
  }

  /** The row menu at a viewport point, for a right-click or a long press on `target`; whether it opened. */
  openContextMenu(target: Element, x: number, y: number): boolean {
    if (this.sheet.edit.editing) return false;
    // a header: its own menu, as its "⋯" button opens it (V03 batch 1)
    const header = this.sheet.dom.headerCell(target);
    if (header) {
      const button = header.querySelector<HTMLElement>(
        '[data-test-subj^=dataGridHeaderCellActionButton-]'
      );
      if (!button) return false;
      button.click();
      return true;
    }
    const rowCell = this.sheet.dom.rowNumberCell(target);
    const cell = rowCell ? null : this.sheet.dom.dataCell(target);
    const row = rowCell
      ? this.sheet.dom.rowIndexOf(rowCell)
      : cell
        ? this.sheet.dom.cursor(cell).row
        : -1;
    if (!this.sheet.rows.isRecordRow(row)) return false;
    let col: number | null = null;
    if (rowCell) {
      if (!this.sheet.selection.isRowSelected(row))
        this.sheet.selection.selectRows(row, false);
    } else if (cell) {
      const pos = this.sheet.dom.cursor(cell);
      col = pos.col;
      if (!this.sheet.selection.isSelected(pos.row, pos.col)) {
        this.sheet.selection.anchor = pos;
        this.sheet.selection.head = pos;
        this.sheet.selection.rangeKind = 'cells';
      }
    }
    const point = this.sheet.dom.pointInWrapper(x, y);
    this.openMenu(row, col, { ...point, width: 0, height: 0 });
    return true;
  }
}
