/**
 * The grid's `@renderCellValue`: draws selection and errors with
 * `setCellProps` and shows the type's cell component, or the text
 * (PACKAGE-DESIGN.md 7.3).
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiHighlight from '@ember-eui/core/components/eui-highlight';
import EuiIcon from '@ember-eui/core/components/eui-icon';

import type EuiSheet from '../components/eui-sheet.gts';
import type { CellView } from '../components/eui-sheet.gts';
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

  @cached
  get view(): CellView | null {
    return this.sheet.cellView(
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
    const view = this.view;
    const props: Record<string, unknown> = {};
    const classes: string[] = [];
    // the frozen field (V02-DESIGN.md 9.2): sticky, also on the add row
    const frozen = this.sheet.frozenCellProps(this.args.colIndex);
    if (frozen) {
      classes.push(frozen.className);
      props['style'] = frozen.style;
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
    if (view?.errors.length) {
      classes.push('euiSheet__cell--invalid');
      props['aria-invalid'] = 'true';
      props['title'] = view.errors.join('\n');
    }
    if (classes.length) props['className'] = classes.join(' ');
    this.args.setCellProps(props);
    return '';
  }

  /** The add row's first data cell shows "+ Add record"; its other cells nothing. */
  get addRecordLabel(): string | undefined {
    if (this.col !== 0 || !this.sheet.isAddRow(this.args.rowIndex)) {
      return undefined;
    }
    return this.sheet.messages.addRecord();
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
    this.sheet.commitCellValue(this.args.rowIndex, this.col, value);
  };

  <template>
    {{this.cellProps}}
    {{#if this.addRecordLabel}}
      <span class="euiSheet__addRecord" data-test-subj="euiSheetAddRecord">
        <EuiIcon @type="plus" @size="s" />
        {{this.addRecordLabel}}
      </span>
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
