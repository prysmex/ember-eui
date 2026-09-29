import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { hash } from '@ember/helper';

import { monitorForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import {
  autoScrollForElements,
  autoScrollWindowForElements
} from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import { modifier } from 'ember-modifier';

import { randomId } from '../-private/random-id.ts';
import { isDraggableData } from '../-private/drag-drop.ts';
import EuiDroppable from './eui-droppable.gts';

import type { DraggableData } from '../-private/drag-drop.ts';
import type { DraggableLocation } from '../utils/drag-drop.ts';
import type { EuiDroppableSignature } from './eui-droppable';
import type Owner from '@ember/owner';
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
 *
 * Dragging with the pointer is handled by Atlassian's pragmatic drag and
 * drop; the keyboard (Space, arrows, Escape) by these components.
 */
export interface EuiDragDropContextSignature {
  Args: {
    /** Called with the result when an item is dropped (or the drag cancelled). */
    onDragEnd: (result: DropResult) => void;
    /** Called when a drag starts. */
    onDragStart?: (start: DragStart) => void;
    /** Called when the destination changes during a drag. */
    onDragUpdate?: (update: DropResult) => void;
    /** Scrolls the window while dragging near its edges. Defaults to `true`. */
    autoScrollWindow?: boolean;
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
        /**
         * Scrolls another container while its items are dragged near its
         * edges, e.g. a board holding several lists: `{{dnd.autoScroll}}`.
         */
        autoScroll: EuiDragDropContext['autoScroll'];
      }
    ];
  };
}

export default class EuiDragDropContext extends Component<EuiDragDropContextSignature> {
  @tracked drag: DragState | null = null;

  session = 0;

  /** Scopes the drags to this context (several can share a page). */
  contextId = `euiDragDropContext_${randomId()}`;

  constructor(owner: Owner, args: EuiDragDropContextSignature['Args']) {
    super(owner, args);

    const stopMonitoring = monitorForElements({
      canMonitor: ({ source }) => isDraggableData(source.data, this.contextId),
      onDragStart: ({ source }) => {
        const data = source.data as DraggableData;

        this.start({
          draggableId: data.draggableId,
          type: data.type,
          source: { droppableId: data.droppableId, index: data.index },
          size: data.size,
          isKeyboard: false,
          isClone: data.isClone
        });
      },
      onDrop: ({ location }) => {
        const onList = location.current.dropTargets.some(
          (target) => target.data['euiDragDropContext'] === this.contextId
        );

        this.end(onList && this.drag?.destination ? 'DROP' : 'CANCEL');
      }
    });

    const stopWindowScroll = autoScrollWindowForElements({
      canScroll: ({ source }) =>
        this.args.autoScrollWindow !== false &&
        isDraggableData(source.data, this.contextId)
    });

    registerDestructor(this, () => {
      stopMonitoring();
      stopWindowScroll();
    });
  }

  /** Scrolls the element while this context's items are dragged near its edges. */
  autoScroll = modifier((element: HTMLElement) =>
    autoScrollForElements({
      element,
      canScroll: ({ source }) => isDraggableData(source.data, this.contextId)
    })
  );

  start(drag: Omit<DragState, 'destination' | 'session'>): void {
    this.drag = {
      ...drag,
      destination: drag.isKeyboard ? drag.source : null,
      session: ++this.session
    };
    this.args.onDragStart?.({
      draggableId: drag.draggableId,
      type: drag.type,
      source: drag.source
    });
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
    {{yield
      (hash
        Droppable=(component EuiDroppable context=this)
        autoScroll=this.autoScroll
      )
    }}
  </template>
}
