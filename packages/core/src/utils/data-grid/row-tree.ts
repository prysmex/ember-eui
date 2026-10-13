/**
 * Row tree model for EuiDataGrid's nested rows (`@rowTree`) and row grouping
 * (`@grouping`). Ember EUI extension: upstream EUI has neither.
 *
 * Framework free: builds a tree of data rows (from nested `children` arrays
 * or flat `parentId` references), optionally groups rows by column values,
 * sorts siblings, and flattens the tree into the list of visible rows given
 * the expanded ids.
 */

export type RowTreeNodeKind = 'row' | 'group';

export interface RowTreeGroup {
  /** The grouped column. */
  columnId: string;
  /** The column value shared by the group's rows. */
  value: unknown;
  /** Number of grouped rows (data rows at the grouped level, in all subgroups). */
  count: number;
  /** Data row indexes of the grouped rows. */
  rowIndices: number[];
}

export interface RowTreeNode {
  id: string;
  kind: RowTreeNodeKind;
  /**
   * Data row index for rows; a stable negative index (`-1`, `-2`, …) for
   * groups, so per-row grid state (heights, cell props) never collides with
   * data rows.
   */
  rowIndex: number;
  group?: RowTreeGroup;
  children: RowTreeNode[];
}

export interface RowTreeVisibleRow {
  id: string;
  kind: RowTreeNodeKind;
  rowIndex: number;
  group?: RowTreeGroup;
  /** 0 for root rows. */
  depth: number;
  hasChildren: boolean;
  isExpanded: boolean;
  parentId: string | null;
  /** 1-based position among its siblings. */
  posInSet: number;
  setSize: number;
}

export type RowId = string | number;

export interface RowTreeSource<T = any> {
  rows: T[];
  /** Child rows of a row (nested form). Defaults to `row.children` when it is an array. */
  getChildren?: (row: T) => T[] | null | undefined;
  /** Parent row id of a row (flat form). Defaults to `row.parentId ?? row.parent`. */
  getParentId?: (row: T) => RowId | null | undefined;
  /** Row id. Defaults to `row.id`, else the row's index. */
  getRowId?: (row: T, rowIndex: number) => RowId | null | undefined;
}

export interface BuiltRowTree {
  roots: RowTreeNode[];
  /** Row objects by data row index (pre-order for nested rows, array index for flat rows). */
  rows: unknown[];
}

const isObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;

function defaultChildren(row: unknown): unknown[] | undefined {
  return isObject(row) && Array.isArray(row['children'])
    ? (row['children'] as unknown[])
    : undefined;
}

function defaultParentId(row: unknown): RowId | null | undefined {
  if (!isObject(row)) return undefined;
  return (row['parentId'] ?? row['parent']) as RowId | null | undefined;
}

function defaultRowId(row: unknown): RowId | null | undefined {
  return isObject(row) ? (row['id'] as RowId | null | undefined) : undefined;
}

/** Whether rows nest through `children` (otherwise they reference a `parentId`). */
export function isNestedRowSource(source: RowTreeSource): boolean {
  if (source.getChildren) return true;
  if (source.getParentId) return false;
  return source.rows.some((row) => defaultChildren(row) !== undefined);
}

/**
 * Builds the data row tree. Nested rows get data row indexes in pre-order
 * (parents before children); flat rows keep their array index.
 */
export function buildRowTree<T>(source: RowTreeSource<T>): BuiltRowTree {
  const getRowId = source.getRowId ?? defaultRowId;
  const idOf = (row: T, rowIndex: number): string => {
    const id = getRowId(row, rowIndex);
    return id == null ? String(rowIndex) : String(id);
  };

  if (isNestedRowSource(source)) {
    const getChildren = (source.getChildren ?? defaultChildren) as (row: T) => T[] | null | undefined;
    const rows: unknown[] = [];
    const seen = new Set<unknown>();
    const visit = (row: T): RowTreeNode | null => {
      if (isObject(row)) {
        if (seen.has(row)) return null; // cycle or shared row
        seen.add(row);
      }
      const rowIndex = rows.length;
      rows.push(row);
      const node: RowTreeNode = {
        id: idOf(row, rowIndex),
        kind: 'row',
        rowIndex,
        children: []
      };
      for (const child of getChildren(row) ?? []) {
        const childNode = visit(child);
        if (childNode) node.children.push(childNode);
      }
      return node;
    };
    const roots: RowTreeNode[] = [];
    for (const row of source.rows) {
      const node = visit(row);
      if (node) roots.push(node);
    }
    return { roots, rows };
  }

  const getParentId = (source.getParentId ?? defaultParentId) as (row: T) => RowId | null | undefined;
  const nodes = source.rows.map(
    (row, rowIndex): RowTreeNode => ({
      id: idOf(row, rowIndex),
      kind: 'row',
      rowIndex,
      children: []
    })
  );
  const byId = new Map<string, RowTreeNode>();
  for (const node of nodes) if (!byId.has(node.id)) byId.set(node.id, node);
  const parentOf = new Map<RowTreeNode, RowTreeNode>();
  for (const [rowIndex, node] of nodes.entries()) {
    const parentId = getParentId(source.rows[rowIndex]!);
    if (parentId == null) continue;
    const parent = byId.get(String(parentId));
    if (parent && parent !== node) parentOf.set(node, parent);
  }
  // break cycles: a row whose ancestry loops back becomes a root
  for (const node of nodes) {
    const ancestors = new Set<RowTreeNode>([node]);
    let parent = parentOf.get(node);
    while (parent) {
      if (ancestors.has(parent)) {
        parentOf.delete(node);
        break;
      }
      ancestors.add(parent);
      parent = parentOf.get(parent);
    }
  }
  const roots: RowTreeNode[] = [];
  for (const node of nodes) {
    const parent = parentOf.get(node);
    if (parent) parent.children.push(node);
    else roots.push(node);
  }
  return { roots, rows: source.rows };
}

/** Root nodes for `rowCount` flat rows (grouping without `rows`). */
export function buildFlatRows(rowCount: number): RowTreeNode[] {
  return Array.from({ length: Math.max(0, rowCount) }, (_, rowIndex) => ({
    id: String(rowIndex),
    kind: 'row' as const,
    rowIndex,
    children: []
  }));
}

/** Identifier of a group: its column values from the outermost group down. */
export function groupId(values: unknown[]): string {
  return `group:${JSON.stringify(values.map((value) => (value === undefined ? null : value)))}`;
}

/**
 * Groups rows by the values of `groupBy` columns (outermost first). Groups
 * keep the order in which their values first appear; sort them with
 * `sortRowTree`. Grouped rows keep their own children.
 */
export function groupRowTree(
  nodes: RowTreeNode[],
  groupBy: string[],
  getValue: (rowIndex: number, columnId: string) => unknown
): RowTreeNode[] {
  if (!groupBy.length) return nodes;
  let ordinal = 0;
  const group = (items: RowTreeNode[], level: number, path: unknown[]): RowTreeNode[] => {
    if (level >= groupBy.length) return items;
    const columnId = groupBy[level]!;
    const buckets = new Map<unknown, RowTreeNode[]>();
    for (const item of items) {
      const value = getValue(item.rowIndex, columnId);
      // Dates group by time, not identity; null and undefined are one group
      const key = value instanceof Date ? `date:${value.getTime()}` : (value ?? null);
      const bucket = buckets.get(key);
      if (bucket) bucket.push(item);
      else buckets.set(key, [item]);
    }
    const groups: RowTreeNode[] = [];
    for (const bucket of buckets.values()) {
      const value = getValue(bucket[0]!.rowIndex, columnId);
      const valuePath = [...path, value];
      const node: RowTreeNode = {
        id: groupId(valuePath),
        kind: 'group',
        rowIndex: -1 - ordinal++,
        group: {
          columnId,
          value,
          count: bucket.length,
          rowIndices: bucket.map((item) => item.rowIndex)
        },
        children: []
      };
      node.children = group(bucket, level + 1, valuePath);
      groups.push(node);
    }
    return groups;
  };
  return group(nodes, 0, []);
}

/** Compares group values: empty values last, numbers/dates numerically, text naturally. */
export function compareGroupValues(a: unknown, b: unknown): number {
  const aEmpty = a == null || a === '';
  const bEmpty = b == null || b === '';
  if (aEmpty || bEmpty) return aEmpty === bEmpty ? 0 : aEmpty ? 1 : -1;
  if (a instanceof Date && b instanceof Date) return a.getTime() - b.getTime();
  if (typeof a === 'number' && typeof b === 'number') return a - b;
  if (typeof a === 'boolean' && typeof b === 'boolean') return Number(a) - Number(b);
  return String(a as string).localeCompare(String(b as string), undefined, {
    numeric: true,
    sensitivity: 'base'
  });
}

/**
 * Sorts every level of the tree (stable; returns new arrays). Siblings are
 * compared with `compare`; nodes it ranks equal keep their order.
 */
export function sortRowTree(
  nodes: RowTreeNode[],
  compare: (a: RowTreeNode, b: RowTreeNode) => number
): RowTreeNode[] {
  return nodes
    .map((node, index) => ({ node, index }))
    .sort((a, b) => compare(a.node, b.node) || a.index - b.index)
    .map(({ node }) =>
      node.children.length ? { ...node, children: sortRowTree(node.children, compare) } : node
    );
}

/** The visible rows: roots, and the children of expanded rows, depth first. */
export function flattenRowTree(
  roots: RowTreeNode[],
  isExpanded: (node: RowTreeNode) => boolean
): RowTreeVisibleRow[] {
  const result: RowTreeVisibleRow[] = [];
  const visit = (nodes: RowTreeNode[], depth: number, parentId: string | null) => {
    const setSize = nodes.length;
    nodes.forEach((node, index) => {
      const hasChildren = node.children.length > 0;
      const expanded = hasChildren && isExpanded(node);
      result.push({
        id: node.id,
        kind: node.kind,
        rowIndex: node.rowIndex,
        group: node.group,
        depth,
        hasChildren,
        isExpanded: expanded,
        parentId,
        posInSet: index + 1,
        setSize
      });
      if (expanded) visit(node.children, depth + 1, node.id);
    });
  };
  visit(roots, 0, null);
  return result;
}

/** Ids of every node with children, by kind. */
export function collectExpandableIds(roots: RowTreeNode[]): { row: string[]; group: string[] } {
  const ids = { row: [] as string[], group: [] as string[] };
  const visit = (nodes: RowTreeNode[]) => {
    for (const node of nodes) {
      if (!node.children.length) continue;
      ids[node.kind].push(node.id);
      visit(node.children);
    }
  };
  visit(roots);
  return ids;
}

/** Ancestors (outermost first) of the node with a data row index, or null if absent. */
export function findAncestors(roots: RowTreeNode[], rowIndex: number): RowTreeNode[] | null {
  const path: RowTreeNode[] = [];
  const visit = (nodes: RowTreeNode[]): boolean => {
    for (const node of nodes) {
      if (node.rowIndex === rowIndex) return true;
      path.push(node);
      if (visit(node.children)) return true;
      path.pop();
    }
    return false;
  };
  return visit(roots) ? path : null;
}
