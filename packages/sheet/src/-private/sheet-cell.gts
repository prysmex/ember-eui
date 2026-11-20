/**
 * The grid's `@renderCellValue`: draws selection and errors with
 * `setCellProps` and shows the type's cell component, or the text
 * (PACKAGE-DESIGN.md 7.3).
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiHighlight from '@ember-eui/core/components/eui-highlight';
import EuiIcon from '@ember-eui/core/components/eui-icon';

import AddPinned from './add-pinned.gts';
import GroupLabel from './group-label.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { CellView } from '../components/eui-sheet.gts';
import type { SheetGroup } from '../core/index.ts';
import type { EuiDataGridCellValueElementProps } from '@ember-eui/core/utils/data-grid/types';

interface SheetCellContext {
  sheet: EuiSheet<object>;
}

export default class SheetCell extends Component<{
  Args: EuiDataGridCellValueElementProps;
}> {
  get sheet(): EuiSheet<object> {
    return (this.args.cellContext as unknown as SheetCellContext).sheet;
  }

  /** The data column: the grid's column index counts the sheet's control columns. */
  get col(): number {
    return this.args.colIndex - this.sheet.colOffset;
  }

  /** The group when this cell is in a group header row (V03 9.1). */
  get group(): SheetGroup | undefined {
    return this.sheet.groupHeaders.groupHeaderAt(this.args.rowIndex);
  }

  @cached
  get view(): CellView | null {
    return this.sheet.cells.cellView(
      this.args.rowIndex,
      this.col,
      this.args.columnId
    );
  }

  // Re-runs on every selection, error or value change and when the cell is
  // re-created after scrolling. setCellProps only schedules (applied after
  // render), so calling it here is allowed. The grid replaces the whole
  // props object, so everything goes in one call.
  get cellProps(): string {
    // a group header's cell: no frozen, selection or error props; the
    // header row's CSS places the label (V03 9.1)
    const group = this.group;
    if (group) {
      this.args.setCellProps(this.sheet.groupHeaders.groupCellProps(group));
      return '';
    }
    const view = this.view;
    const props: Record<string, unknown> = {};
    const classes: string[] = [];
    // the frozen field (V02-DESIGN.md 9.2): sticky, also on the add row
    const frozen = this.sheet.frozen.frozenCellProps(this.args.colIndex);
    if (frozen) {
      classes.push(frozen.className);
      props['style'] = frozen.style;
    }
    // the row's colour bar without row numbers: on the first field (V03 10.2)
    if (view && this.col === 0 && !this.sheet.colOffset) {
      const bar = this.sheet.rowColors.barProps(this.args.rowIndex);
      if (bar) {
        classes.push(bar.className);
        props['style'] = { ...frozen?.style, ...bar.style };
      }
    }
    // a checked row's light tint (V03 batch 1); never the add row
    if (view && this.sheet.checked.isChecked(this.args.rowIndex)) {
      classes.push('euiSheet__cell--checked');
    }
    // V03 10.1: a row being dragged
    if (view && this.sheet.rowDrag.isMoving(this.args.rowIndex)) {
      classes.push('euiSheet__rowCell--moving');
    }
    if (view?.selected) {
      classes.push('euiSheet__cell--selected');
      props['aria-selected'] = 'true';
    }
    if (view?.pending) {
      classes.push('euiSheet__cell--pending');
      props['aria-busy'] = 'true';
    }
    if (view?.dropTarget) classes.push('euiSheet__cell--dropTarget');
    if (this.sheet.filling.isFillPreview(this.args.rowIndex, this.col)) {
      classes.push('euiSheet__cell--fillPreview');
    }
    if (view?.errors.length) {
      classes.push('euiSheet__cell--invalid');
      props['aria-invalid'] = 'true';
      props['title'] = view.errors.join('\n');
    }
    if (classes.length) props['className'] = classes.join(' ');
    this.args.setCellProps(props);
    return '';
  }

  /** The add row's first data cell shows "Add record"; its other cells nothing. */
  get addRecordLabel(): string | undefined {
    if (this.col !== 0 || !this.sheet.rows.isAddRow(this.args.rowIndex)) {
      return undefined;
    }
    return this.sheet.messages.addRecord();
  }

  /** Any data cell of an add row: it carries the pinned "+ Add record". */
  get isAddRowCell(): boolean {
    return this.sheet.rows.isAddRow(this.args.rowIndex);
  }

  get addPinnedLabel(): string {
    return this.sheet.messages.addRecord();
  }

  /** One plus on the add row (V03 5.2): the row-number cell's, else this one. */
  get addRecordIcon(): boolean {
    return this.sheet.colOffset === 0;
  }

  get cellComponent() {
    const view = this.view;
    return view && !view.rejected ? view.type.cell : undefined;
  }

  /** The type's opener icon, on cells that can be edited. */
  get opener(): string | undefined {
    const view = this.view;
    if (!view || view.readOnly || !view.type.editor) return undefined;
    return view.type.opener;
  }

  /** `@highlight`, when there is something to mark. */
  get highlight(): string | undefined {
    return this.sheet.args.highlight || undefined;
  }

  onCommit = (value: unknown): void => {
    this.sheet.cells.commitCellValue(this.args.rowIndex, this.col, value);
  };

  <template>
    {{this.cellProps}}
    {{#if this.group}}
      <GroupLabel
        @sheet={{this.sheet}}
        @group={{this.group}}
        @fieldId={{@columnId}}
      />
    {{else if this.addRecordLabel}}
      <span class="euiSheet__addRecord" data-test-subj="euiSheetAddRecord">
        {{#if this.addRecordIcon}}<EuiIcon @type="plus" @size="s" />{{/if}}
        {{this.addRecordLabel}}
      </span>
      {{#if this.sheet.gridOptions.pinsAddRow}}
        <AddPinned
          @label={{this.addPinnedLabel}}
          @inline={{this.addRecordIcon}}
        />
      {{/if}}
    {{else if this.isAddRowCell}}
      {{#if this.sheet.gridOptions.pinsAddRow}}
        <AddPinned
          @label={{this.addPinnedLabel}}
          @inline={{this.addRecordIcon}}
        />
      {{/if}}
    {{else if this.view}}
      {{#if this.cellComponent}}
        <this.cellComponent
          @value={{this.view.value}}
          @text={{this.view.text}}
          @field={{this.view.field}}
          @record={{this.view.record}}
          @errors={{this.view.errors}}
          @readOnly={{this.view.readOnly}}
          @onCommit={{this.onCommit}}
          @highlight={{this.highlight}}
          @link={{this.view.link}}
          @pending={{this.view.pending}}
          @disabled={{this.view.disabled}}
        />
      {{else if this.highlight}}
        <EuiHighlight
          @text={{this.view.text}}
          @search={{this.highlight}}
          @highlightAll={{true}}
        />
      {{else}}
        {{this.view.text}}
      {{/if}}
      {{#if this.opener}}
        {{! not focusable (P9): a click is handled by the sheet }}
        <span
          class="euiSheet__opener"
          data-eui-sheet-opener
          data-test-subj="euiSheetOpener"
          aria-hidden="true"
        ><EuiIcon @type={{this.opener}} @size="s" /></span>
      {{/if}}
    {{/if}}
  </template>
}
