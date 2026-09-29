/** Where a draggable is: its list and its index there. */
export interface DraggableLocation {
  droppableId: string;
  index: number;
}

/** The list with the item at `startIndex` moved to `endIndex`. */
export function euiDragDropReorder<T>(list: T[], startIndex: number, endIndex: number): T[] {
  const result = [...list];
  const [removed] = result.splice(startIndex, 1);

  result.splice(endIndex, 0, removed as T);

  return result;
}

/**
 * Both lists after moving an item from one to the other:
 * `{ [sourceId]: newSource, [destinationId]: newDestination }`.
 */
export function euiDragDropMove<T>(
  sourceList: T[],
  destinationList: T[],
  source: DraggableLocation,
  destination: DraggableLocation
): Record<string, T[]> {
  const sourceClone = [...sourceList];
  const destinationClone = [...destinationList];
  const [removed] = sourceClone.splice(source.index, 1);

  destinationClone.splice(destination.index, 0, removed as T);

  return { [source.droppableId]: sourceClone, [destination.droppableId]: destinationClone };
}

/**
 * Both lists after copying an item into the other list; `idModification`
 * gives the copy a new id: `{ property: 'id', modifier: () => newId() }`.
 */
export function euiDragDropCopy<T extends object>(
  sourceList: T[],
  destinationList: T[],
  source: DraggableLocation,
  destination: DraggableLocation,
  idModification: { property: keyof T; modifier: () => unknown }
): Record<string, T[]> {
  const destinationClone = [...destinationList];

  destinationClone.splice(destination.index, 0, {
    ...sourceList[source.index]!,
    [idModification.property]: idModification.modifier()
  });

  return { [source.droppableId]: [...sourceList], [destination.droppableId]: destinationClone };
}
