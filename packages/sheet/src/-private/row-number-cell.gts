/**
 * The row-number column (V02-DESIGN.md 5.3): the body cell shows the
 * record's position (or `@rowLabel`), a checkbox on hover or when checked,
 * and an expand icon; on the add row a "+". The header cell has the
 * "select all" checkbox. Spans only: no tabbable element (P9), the sheet
 * handles their clicks and the cell's keys.
 */
import Component from '@glimmer/component';

import EuiIcon from '@ember-eui/core/components/eui-icon';

import AddPinned from './add-pinned.gts';
import GroupLabel from './group-label.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { SheetGroup } from '../core/index.ts';
import type { EuiDataGridSetCellProps } from '@ember-eui/core/utils/data-grid/types';

interface RowNumberCellSignature {
  Args: {
    sheet: EuiSheet<any>;
    rowIndex: number;
    setCellProps: (props: EuiDataGridSetCellProps) => void;
  };
}

export class RowNumberCell extends Component<RowNumberCellSignature> {
  get sheet(): EuiSheet<any> {
    return this.args.sheet;
  }

  get isAddRow(): boolean {
    return this.sheet.rows.isAddRow(this.args.rowIndex);
  }

  /** The group when this is a group header row's cell (V03 9.1). */
  get group(): SheetGroup | undefined {
    return this.sheet.groupHeaders.groupHeaderAt(this.args.rowIndex);
  }

  get hasRecord(): boolean {
    return this.sheet.rows.recordAt(this.args.rowIndex) !== undefined;
  }

  get label(): string {
    return this.sheet.rows.rowLabelOf(this.args.rowIndex);
  }

  get checked(): boolean {
    return this.sheet.checked.isChecked(this.args.rowIndex);
  }

  get selected(): boolean {
    return this.sheet.selection.isRowSelected(this.args.rowIndex);
  }

  get selectLabel(): string {
    return this.sheet.messages.selectRow();
  }

  get expandLabel(): string {
    return this.sheet.messages.expandRecord();
  }

  /** The row drag's grip (V03 10.1): with `@canMove`, on a record's row. */
  get showsGrip(): boolean {
    return this.sheet.rowDrag.showsGrip;
  }

  get gripLabel(): string {
    const count = this.showsGrip
      ? this.sheet.rowDrag.idsFor(this.args.rowIndex).length
      : 1;
    return count > 1
      ? this.sheet.messages.moveRecords(count)
      : this.sheet.messages.moveRecord();
  }

  // as SheetCell: setCellProps only schedules, so calling it in render is allowed
  get cellProps(): string {
    const props: Record<string, unknown> = {};
    const classes = ['euiSheet__rowCell'];
    // a group header: not frozen (its first rendered cell is made sticky
    // by the row's CSS, V03 9.1), no number
    const group = this.group;
    if (group) {
      this.args.setCellProps({
        ...this.sheet.groupHeaders.groupCellProps(group),
        className: classes.join(' ')
      });
      return '';
    }
    // frozen with the first field (V02-DESIGN.md 6.7)
    const frozen = this.sheet.frozen.frozenCellProps(0);
    if (frozen) {
      classes.push(frozen.className);
      props['style'] = frozen.style;
    }
    // the row's colour bar (V03 10.2), sticky with the cell when frozen
    const bar = this.sheet.rowColors.barProps(this.args.rowIndex);
    if (bar) {
      classes.push(bar.className);
      props['style'] = { ...frozen?.style, ...bar.style };
    }
    const messages = this.sheet.messages;
    if (this.isAddRow) {
      classes.push('euiSheet__rowCell--add');
      props['aria-label'] = messages.addRecord();
    } else if (this.hasRecord) {
      // the row's checkbox is drawn, not a control: its state is in the label
      const position = this.sheet.rows.positionOf(this.args.rowIndex);
      props['aria-label'] = this.checked
        ? messages.rowNumberChecked(position)
        : messages.rowNumber(position);
      if (this.checked) classes.push('euiSheet__rowCell--checked');
      // V03 10.1: a row being dragged
      if (this.sheet.rowDrag.isMoving(this.args.rowIndex)) {
        classes.push('euiSheet__rowCell--moving');
      }
      // V03 batch 1: a cell range's rows
      if (this.sheet.selection.isRowMarked(this.args.rowIndex)) {
        classes.push('euiSheet__rowCell--marked');
      }
      if (this.selected) {
        classes.push('euiSheet__rowCell--selected');
        props['aria-selected'] = 'true';
      }
    }
    props['className'] = classes.join(' ');
    this.args.setCellProps(props);
    return '';
  }

  get addRecordText(): string {
    return this.sheet.messages.addRecord();
  }

  <template>
    {{this.cellProps}}
    {{#if this.group}}
      <GroupLabel @sheet={{this.sheet}} @group={{this.group}} />
    {{else if this.isAddRow}}
      <span
        class="euiSheet__rowAdd"
        data-test-subj="euiSheetRowAdd"
        aria-hidden="true"
      ><EuiIcon @type="plus" @size="s" /></span>
      {{#if this.sheet.gridOptions.pinsAddRow}}
        <AddPinned @label={{this.addRecordText}} @inline={{false}} />
      {{/if}}
    {{else if this.hasRecord}}
      <span class="euiSheet__rowStart">
        {{#if this.showsGrip}}
          <span
            class="euiSheet__rowGrip"
            data-eui-sheet-row-grip
            data-test-subj="euiSheetRowGrip"
            title={{this.gripLabel}}
            aria-hidden="true"
          ><EuiIcon @type="grab" @size="s" /></span>
        {{/if}}
        <span
          class="euiSheet__rowLabel"
          data-test-subj="euiSheetRowLabel"
        >{{this.label}}</span>
        <span
          class="euiSheet__checkbox euiSheet__rowCheck
            {{if this.checked 'euiSheet__checkbox--checked'}}"
          data-eui-sheet-row-check
          data-test-subj="euiSheetRowCheck"
          title={{this.selectLabel}}
          aria-hidden="true"
        ></span>
      </span>
      <span
        class="euiSheet__rowExpand"
        data-eui-sheet-row-expand
        data-test-subj="euiSheetRowExpand"
        title={{this.expandLabel}}
        aria-hidden="true"
      ><EuiIcon @type="expand" @size="s" /></span>
    {{/if}}
  </template>
}

interface RowNumberHeaderSignature {
  Args: { sheet: EuiSheet<any> };
}

/** The control column's header: checks every record of `@records`, or none when all are. */
export class RowNumberHeader extends Component<RowNumberHeaderSignature> {
  get state(): 'all' | 'some' | 'none' {
    return this.args.sheet.checked.checkedState;
  }

  get label(): string {
    return this.args.sheet.messages.selectAllRows();
  }

  /** The column header's name (its checkbox is drawn and `aria-hidden`). */
  get headerName(): string {
    return this.args.sheet.messages.rowNumberHeader();
  }

  <template>
    <span
      class="euiSheet__checkbox euiSheet__rowCheckAll
        {{if (isAll this.state) 'euiSheet__checkbox--checked'}}
        {{if (isSome this.state) 'euiSheet__checkbox--mixed'}}"
      data-eui-sheet-row-check-all
      data-test-subj="euiSheetRowCheckAll"
      title={{this.label}}
      aria-hidden="true"
    ></span><span class="euiSheet__srOnly">{{this.headerName}}</span>
  </template>
}

function isAll(state: string): boolean {
  return state === 'all';
}

function isSome(state: string): boolean {
  return state === 'some';
}
