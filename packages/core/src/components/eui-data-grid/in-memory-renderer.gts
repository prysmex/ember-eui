import Component from '@glimmer/component';
import { hash } from '@ember/helper';

import { modifier } from 'ember-modifier';

import { afterRender } from '../../utils/data-grid/scheduling.ts';

import type EuiDataGrid from '../eui-data-grid.gts';
import type {
  EuiDataGridCellValueElementProps,
  EuiDataGridColumn,
  EuiDataGridInMemory
} from '../../utils/data-grid/types.ts';

export interface EuiDataGridInMemoryRendererSignature {
  Args: { grid: EuiDataGrid; inMemory: EuiDataGridInMemory; rowCount: number };
  Blocks: { cell: [EuiDataGridCellValueElementProps] };
}

const noop = () => {};

function getElementText(element: HTMLElement): string {
  return element.innerText || element.textContent || '';
}

/**
 * Renders every cell off-document (like upstream's portal into a document
 * fragment) and reports the text of each cell to the grid, which uses it
 * for schema detection and in-memory sorting.
 */
export default class EuiDataGridInMemoryRenderer extends Component<EuiDataGridInMemoryRendererSignature> {
  /** Detached container: rendered, never attached to the document. */
  readonly container = document.createElement('div');

  get columns(): Array<{ column: EuiDataGridColumn; colIndex: number; isExpandable: boolean }> {
    const skip = this.args.inMemory.skipColumns ?? [];
    return this.args.grid.args.columns
      .map((column, colIndex) => ({
        column,
        colIndex,
        isExpandable: column.isExpandable ?? true
      }))
      .filter(({ column }) => !skip.includes(column.id));
  }

  get rows(): number[] {
    return Array.from({ length: this.args.rowCount }, (_, i) => i);
  }

  /** Reads all cell texts after rendering and watches later changes. */
  observe = modifier((element: HTMLElement) => {
    const { grid } = this.args;
    const report = (cellDiv: HTMLElement) => {
      const rowIndex = parseInt(cellDiv.getAttribute('data-dg-row')!, 10);
      const column = cellDiv.getAttribute('data-dg-column')!;
      grid.onCellRender(rowIndex, column, getElementText(cellDiv));
    };
    afterRender(this, () => {
      for (const cellDiv of Array.from(element.children) as HTMLElement[]) report(cellDiv);
    });
    const observer = new MutationObserver((records) => {
      const cells = new Set<HTMLElement>();
      for (const record of records) {
        let target: Node | null = record.target;
        while (target && !(target instanceof HTMLElement && target.hasAttribute('data-dg-row'))) {
          target = target.parentNode;
        }
        if (target) cells.add(target as HTMLElement);
      }
      afterRender(this, () => cells.forEach(report));
    });
    observer.observe(element, {
      characterData: true,
      subtree: true,
      attributes: true,
      childList: true
    });
    return () => observer.disconnect();
  });

  /** Upstream resets stale values when the level or row count changes. */
  resetValues = modifier((_element: HTMLElement, [, rowCount]: [string, number]) => {
    afterRender(this, () => this.args.grid.resetInMemoryValues(rowCount));
  });

  <template>
    {{#in-element this.container insertBefore=null}}
      <div {{this.observe}} {{this.resetValues @inMemory.level @rowCount}}>
        {{#each this.rows as |rowIndex|}}
          {{#each this.columns as |entry|}}
            <div data-dg-row={{rowIndex}} data-dg-column={{entry.column.id}}>
              {{#if @grid.args.renderCellValue}}
                {{#let @grid.args.renderCellValue as |Renderer|}}
                  <Renderer
                    @rowIndex={{rowIndex}}
                    @colIndex={{entry.colIndex}}
                    @columnId={{entry.column.id}}
                    @setCellProps={{noop}}
                    @schema={{entry.column.schema}}
                    @isExpandable={{entry.isExpandable}}
                    @isExpanded={{false}}
                    @isDetails={{false}}
                    @cellContext={{@grid.args.cellContext}}
                  />
                {{/let}}
              {{else}}
                {{yield
                  (hash
                    rowIndex=rowIndex
                    colIndex=entry.colIndex
                    columnId=entry.column.id
                    setCellProps=noop
                    schema=entry.column.schema
                    isExpandable=entry.isExpandable
                    isExpanded=false
                    isDetails=false
                    cellContext=@grid.args.cellContext
                  )
                  to="cell"
                }}
              {{/if}}
            </div>
          {{/each}}
        {{/each}}
      </div>
    {{/in-element}}
  </template>
}
