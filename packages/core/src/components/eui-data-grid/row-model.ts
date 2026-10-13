import { cached, tracked } from '@glimmer/tracking';

import {
  buildFlatRows,
  buildRowTree,
  collectExpandableIds,
  compareGroupValues,
  findAncestors,
  flattenRowTree,
  groupRowTree,
  sortRowTree
} from '../../utils/data-grid/row-tree.ts';

import type {
  RowTreeNode,
  RowTreeNodeKind,
  RowTreeVisibleRow
} from '../../utils/data-grid/row-tree.ts';
import type {
  EuiDataGridGrouping,
  EuiDataGridRefProps,
  EuiDataGridRowTree,
  EuiDataGridRowTreeOptions,
  EuiDataGridSorting
} from '../../utils/data-grid/types.ts';

/** What the row model reads from the grid. */
export interface EuiDataGridRowModelHost {
  readonly args: {
    rowTree?: EuiDataGridRowTree;
    grouping?: EuiDataGridGrouping;
    rowCount?: number;
    sorting?: EuiDataGridSorting;
  };
  /** In-memory sort order (`map[position] = rowIndex`), empty when unsorted. */
  readonly sortedRowMap: number[];
}

const EMPTY: string[] = [];

/**
 * State of `@rowTree` / `@grouping` (Ember EUI extension): the row tree, the
 * expanded ids (controlled or internal) and the flat list of visible rows the
 * grid renders instead of `0..rowCount`.
 */
export default class EuiDataGridRowModel {
  constructor(private host: EuiDataGridRowModelHost) {}

  /** Internal expanded ids (uncontrolled), null until the first toggle. */
  @tracked private internalRowIds: string[] | null = null;
  @tracked private internalGroupIds: string[] | null = null;

  get isActive(): boolean {
    const { rowTree, grouping } = this.host.args;
    return !!rowTree || !!grouping?.groupBy?.length;
  }

  @cached
  get treeOptions(): EuiDataGridRowTreeOptions | undefined {
    const rowTree = this.host.args.rowTree;
    if (!rowTree) return undefined;
    return Array.isArray(rowTree) ? { rows: rowTree } : rowTree;
  }

  get grouping(): EuiDataGridGrouping | undefined {
    const grouping = this.host.args.grouping;
    return grouping?.groupBy?.length ? grouping : undefined;
  }

  /** Data rows (before grouping): the row tree, or flat rows. */
  @cached
  get built(): { roots: RowTreeNode[]; rows: unknown[] | null } {
    const tree = this.treeOptions;
    if (tree) return buildRowTree(tree);
    const rows = this.grouping?.rows;
    if (rows) return { roots: buildFlatRows(rows.length), rows };
    return { roots: buildFlatRows(this.host.args.rowCount ?? 0), rows: null };
  }

  /** Row objects by data row index (null when the grid has no row objects). */
  get rows(): unknown[] | null {
    return this.built.rows;
  }

  /** Number of data rows (all levels). */
  get dataRowCount(): number {
    const rows = this.built.rows;
    return rows ? rows.length : (this.host.args.rowCount ?? 0);
  }

  rowAt(rowIndex: number): unknown {
    return this.built.rows?.[rowIndex];
  }

  @cached
  get groupedRoots(): RowTreeNode[] {
    const { roots, rows } = this.built;
    const grouping = this.grouping;
    if (!grouping) return roots;
    const getValue =
      grouping.getValue ??
      ((rowIndex: number, columnId: string) => {
        const row = rows?.[rowIndex];
        return row && typeof row === 'object'
          ? (row as Record<string, unknown>)[columnId]
          : undefined;
      });
    return groupRowTree(roots, grouping.groupBy, (rowIndex, columnId) =>
      getValue(rowIndex, columnId, rows?.[rowIndex])
    );
  }

  /**
   * Siblings sorted: groups by value (in the sort direction of their column
   * when it is sorted), rows by the in-memory sort order when there is one.
   */
  @cached
  get roots(): RowTreeNode[] {
    const roots = this.groupedRoots;
    const sortedRowMap = this.host.sortedRowMap;
    const hasGroups = !!this.grouping;
    if (!hasGroups && !sortedRowMap.length) return roots;
    const rank = new Map<number, number>();
    sortedRowMap.forEach((rowIndex, position) => rank.set(rowIndex, position));
    const directions = new Map(
      (this.host.args.sorting?.columns ?? []).map((column) => [column.id, column.direction])
    );
    return sortRowTree(roots, (a, b) => {
      if (a.group && b.group) {
        const result = compareGroupValues(a.group.value, b.group.value);
        return directions.get(a.group.columnId) === 'desc' ? -result : result;
      }
      if (!rank.size) return 0;
      return (rank.get(a.rowIndex) ?? Infinity) - (rank.get(b.rowIndex) ?? Infinity);
    });
  }

  @cached
  get expandableIds(): { row: string[]; group: string[] } {
    return collectExpandableIds(this.groupedRoots);
  }

  private defaultIds(defaults: string[] | 'all' | undefined, all: string[]): string[] {
    if (defaults === 'all') return all;
    return defaults ?? EMPTY;
  }

  get expandedRowIds(): string[] {
    const tree = this.treeOptions;
    return (
      tree?.expandedRowIds ??
      this.internalRowIds ??
      this.defaultIds(tree?.defaultExpandedRowIds, this.expandableIds.row)
    );
  }

  get expandedGroupIds(): string[] {
    const grouping = this.grouping;
    return (
      grouping?.expandedGroupIds ??
      this.internalGroupIds ??
      this.defaultIds(grouping?.defaultExpandedGroupIds, this.expandableIds.group)
    );
  }

  @cached
  get expandedSets(): Record<RowTreeNodeKind, Set<string>> {
    return { row: new Set(this.expandedRowIds), group: new Set(this.expandedGroupIds) };
  }

  /** The rows the grid renders, in order. */
  @cached
  get visibleRows(): RowTreeVisibleRow[] {
    const sets = this.expandedSets;
    return flattenRowTree(this.roots, (node) => sets[node.kind].has(node.id));
  }

  /** Column with the indentation and toggle (undefined: the first data column). */
  get toggleColumnId(): string | undefined {
    return this.treeOptions?.toggleColumnId ?? this.grouping?.toggleColumnId;
  }

  /**
   * The visible row at a grid row index, which is page-relative or absolute
   * (like `getCorrectRowIndex`): `startRow` is the page's first row.
   */
  visibleRowAt(visibleRowIndex: number, startRow: number): RowTreeVisibleRow | undefined {
    const isPaginated = visibleRowIndex - startRow < 0;
    return this.visibleRows[isPaginated ? visibleRowIndex + startRow : visibleRowIndex];
  }

  /** Data row index (negative for groups) of an unpaginated visible row. */
  rowIndexAt(unpaginatedRowIndex: number): number {
    return this.visibleRows[unpaginatedRowIndex]?.rowIndex ?? unpaginatedRowIndex;
  }

  /**
   * Unpaginated visible index of a data row for the imperative API,
   * expanding its collapsed ancestors first.
   */
  findVisibleRowIndex(rowIndex: number): number {
    this.reveal(rowIndex);
    const visibleRowIndex = this.indexOfRowIndex(rowIndex);
    if (visibleRowIndex === -1) {
      // controlled expansion the consumer has not applied yet
      throw new Error(`Row ${rowIndex} is not visible: its parent rows are collapsed.`);
    }
    return visibleRowIndex;
  }

  /** `@registerApi` additions. */
  readonly api: Partial<EuiDataGridRefProps> = {
    expandRow: (id: string) => this.setRowExpanded(id, true),
    collapseRow: (id: string) => this.setRowExpanded(id, false),
    expandAll: () => this.expandAll(),
    collapseAll: () => this.collapseAll()
  };

  /** Visible position of a data row index, or -1. */
  indexOfRowIndex(rowIndex: number): number {
    return this.visibleRows.findIndex((row) => row.rowIndex === rowIndex);
  }

  private kindOf(id: string): RowTreeNodeKind | undefined {
    if (this.expandableIds.group.includes(id)) return 'group';
    if (this.expandableIds.row.includes(id)) return 'row';
    return undefined;
  }

  setExpanded(kind: RowTreeNodeKind, ids: string[]): void {
    if (kind === 'group') {
      const grouping = this.grouping;
      if (!grouping?.expandedGroupIds) this.internalGroupIds = ids;
      grouping?.onExpandedChange?.(ids);
    } else {
      const tree = this.treeOptions;
      if (!tree?.expandedRowIds) this.internalRowIds = ids;
      tree?.onExpandedChange?.(ids);
    }
  }

  setRowExpanded(id: string, isExpanded: boolean, kind = this.kindOf(id)): void {
    if (!kind) return;
    const current = kind === 'group' ? this.expandedGroupIds : this.expandedRowIds;
    if (current.includes(id) === isExpanded) return;
    this.setExpanded(
      kind,
      isExpanded ? [...current, id] : current.filter((other) => other !== id)
    );
  }

  toggle(row: Pick<RowTreeVisibleRow, 'id' | 'kind' | 'isExpanded'>): void {
    this.setRowExpanded(row.id, !row.isExpanded, row.kind);
  }

  expandAll(): void {
    const { row, group } = this.expandableIds;
    if (row.length) this.setExpanded('row', row);
    if (group.length) this.setExpanded('group', group);
  }

  collapseAll(): void {
    if (this.expandedRowIds.length) this.setExpanded('row', []);
    if (this.expandedGroupIds.length) this.setExpanded('group', []);
  }

  /** Expands the ancestors of a data row so it becomes visible. */
  reveal(rowIndex: number): void {
    const ancestors = findAncestors(this.roots, rowIndex) ?? [];
    for (const kind of ['group', 'row'] as const) {
      const current = kind === 'group' ? this.expandedGroupIds : this.expandedRowIds;
      const ids = ancestors
        .filter((node) => node.kind === kind && !current.includes(node.id))
        .map((node) => node.id);
      if (ids.length) this.setExpanded(kind, [...current, ...ids]);
    }
  }
}
