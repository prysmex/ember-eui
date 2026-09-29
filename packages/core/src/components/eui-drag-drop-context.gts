import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import EuiDroppable from './eui-droppable.gts';

import type { DraggableLocation } from '../utils/drag-drop.ts';
import type { EuiDroppableSignature } from './eui-droppable';
import type { ComponentLike } from '@glint/template';

export type { DraggableLocation };

/** What `@onDragStart` gets. */
export interface DragStart {
  draggableId: string;
  type: string;
  source: DraggableLocation;
}

/** What `@onDragEnd` gets: `destination` is `null` when dropped outside a list. */
export interface DropResult extends DragStart {
  destination: DraggableLocation | null;
  /** `'DROP'` or `'CANCEL'` (Escape, or dropped outside). */
  reason: 'DROP' | 'CANCEL';
}

/** The drag in progress. */
export interface DragState extends DragStart {
  destination: DraggableLocation | null;
  /** Size of the dragged item along the list, in px. */
  size: number;
  /** Moved with the keyboard (the item itself moves). */
  isKeyboard: boolean;
  /** The source list keeps its items (`@cloneDraggables`). */
  isClone: boolean;
  /** Increases with each drag, so lists measure their items once per drag. */
  session: number;
}

/**
 * Wraps lists whose items can be dragged to reorder them or to move them
 * between lists. It yields `{ Droppable }`; each droppable yields its
 * `Draggable`. You own the lists: update them in `@onDragEnd`, e.g. with
 * `euiDragDropReorder` from `@ember-eui/core/utils/drag-drop`.
 */
export interface EuiDragDropContextSignature {
  Args: {
    /** Called with the result when an item is dropped (or the drag cancelled). */
    onDragEnd: (result: DropResult) => void;
    /** Called when a drag starts. */
    onDragStart?: (start: DragStart) => void;
    /** Called when the destination changes during a drag. */
    onDragUpdate?: (update: DropResult) => void;
  };
  Blocks: {
    default: [
      {
        /** A list items can be dropped in; see `EuiDroppable`. */
        Droppable: ComponentLike<{
          Element: HTMLDivElement;
          Args: Omit<EuiDroppableSignature['Args'], 'context'>;
          Blocks: EuiDroppableSignature['Blocks'];
        }>;
      }
    ];
  };
}

export default class EuiDragDropContext extends Component<EuiDragDropContextSignature> {
  @tracked drag: DragState | null = null;

  session = 0;

  start(drag: Omit<DragState, 'destination' | 'session'>): void {
    this.drag = {
      ...drag,
      destination: drag.isKeyboard ? drag.source : null,
      session: ++this.session
    };
    this.args.onDragStart?.({ draggableId: drag.draggableId, type: drag.type, source: drag.source });
  }

  setDestination(destination: DraggableLocation | null): void {
    const drag = this.drag;

    if (!drag) return;

    const same =
      destination?.droppableId === drag.destination?.droppableId &&
      destination?.index === drag.destination?.index;

    if (same) return;

    this.drag = { ...drag, destination };
    this.args.onDragUpdate?.(this.result(this.drag, 'DROP'));
  }

  end(reason: 'DROP' | 'CANCEL'): void {
    const drag = this.drag;

    if (!drag) return;

    this.drag = null;
    this.args.onDragEnd(this.result(drag, reason));
  }

  result(drag: DragState, reason: 'DROP' | 'CANCEL'): DropResult {
    return {
      draggableId: drag.draggableId,
      type: drag.type,
      source: drag.source,
      destination: reason === 'CANCEL' ? null : drag.destination,
      reason
    };
  }

  <template>
    {{yield (hash Droppable=(component EuiDroppable context=this))}}
  </template>
}
