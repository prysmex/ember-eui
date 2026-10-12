import type EuiDataGrid from '../eui-data-grid.gts';
import type { TOC } from '@ember/component/template-only';
import type { EuiDataGridCellValueElementProps, EuiDataGridInMemory } from '../../utils/data-grid/types.ts';

export interface EuiDataGridInMemoryRendererSignature {
  Args: { grid: EuiDataGrid; inMemory: EuiDataGridInMemory; rowCount: number };
  Blocks: { cell: [EuiDataGridCellValueElementProps] };
}

const EuiDataGridInMemoryRenderer: TOC<EuiDataGridInMemoryRendererSignature> = <template></template>;
export default EuiDataGridInMemoryRenderer;
