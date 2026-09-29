/** What a draggable carries during a drag (pragmatic drag and drop data). */
export interface DraggableData extends Record<string, unknown> {
  /** Id of the `EuiDragDropContext` the item belongs to. */
  euiDragDropContext: string;
  draggableId: string;
  droppableId: string;
  index: number;
  type: string;
  size: number;
  isClone: boolean;
}

export function isDraggableData(data: Record<string, unknown>, contextId: string): data is DraggableData {
  return data['euiDragDropContext'] === contextId;
}
