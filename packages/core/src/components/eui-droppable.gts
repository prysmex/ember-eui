import Component from '@glimmer/component';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { modifier } from 'ember-modifier';

import EuiDraggable from './eui-draggable.gts';

import type EuiDragDropContext from './eui-drag-drop-context.gts';
import type { EuiDraggableSignature } from './eui-draggable';
import type { ComponentLike } from '@glint/template';

const SPACING = {
  none: undefined,
  s: 'euiDroppable--s',
  m: 'euiDroppable--m',
  l: 'euiDroppable--l'
};

/**
 * A list items can be dragged within and dropped into (yielded as
 * `Droppable` by `EuiDragDropContext`). It yields `{ Draggable }` for its
 * items.
 */
export interface EuiDroppableSignature {
  Element: HTMLDivElement;
  Args: {
    /** Unique id of the list, reported in `onDragEnd`. */
    droppableId: string;
    /**
     * Items can only move between lists of the same type. Defaults to
     * `'EUI_DEFAULT'`.
     */
    type?: string;
    /** `'vertical'` or `'horizontal'` list. Defaults to `'vertical'`. */
    direction?: 'vertical' | 'horizontal';
    /** Nothing can be dropped here. */
    isDropDisabled?: boolean;
    /**
     * Items dragged from here are copies: the list keeps its items (and
     * nothing can be dropped here).
     */
    cloneDraggables?: boolean;
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'none'`. */
    spacing?: 'none' | 's' | 'm' | 'l';
    /** Panel look (background, padding, rounded corners). */
    withPanel?: boolean;
    /** Grows to fill its flex container. */
    grow?: boolean;
    /** @private The context, set by `EuiDragDropContext`. */
    context: EuiDragDropContext;
  };
  Blocks: {
    default: [
      {
        /** An item of this list; see `EuiDraggable`. */
        Draggable: ComponentLike<{
          Element: HTMLDivElement;
          Args: Omit<EuiDraggableSignature['Args'], 'droppable'>;
          Blocks: EuiDraggableSignature['Blocks'];
        }>;
      }
    ];
  };
}

interface Slot {
  start: number;
  end: number;
  draggableId: string;
}

export default class EuiDroppable extends Component<EuiDroppableSignature> {
  element?: HTMLElement;
  // item positions, measured once per drag (before items slide)
  slots?: Slot[];
  slotsSession?: number;

  get type(): string {
    return this.args.type ?? 'EUI_DEFAULT';
  }

  get isHorizontal(): boolean {
    return this.args.direction === 'horizontal';
  }

  get isDropDisabled(): boolean {
    return Boolean(this.args.cloneDraggables || this.args.isDropDisabled);
  }

  get context(): EuiDragDropContext {
    return this.args.context;
  }

  get isDraggingOver(): boolean {
    return this.context.drag?.destination?.droppableId === this.args.droppableId;
  }

  get classes(): string {
    const drag = this.context.drag;

    return [
      'euiDroppable',
      this.isDropDisabled && 'euiDroppable--isDisabled',
      this.isDraggingOver && 'euiDroppable--isDraggingOver',
      drag?.type === this.type && 'euiDroppable--isDraggingType',
      this.args.withPanel && 'euiDroppable--withPanel',
      this.args.grow ? 'euiDroppable--grow' : 'euiDroppable--noGrow',
      SPACING[this.args.spacing ?? 'none']
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** Whether the drag in progress may be dropped here. */
  get accepts(): boolean {
    const drag = this.context.drag;

    return Boolean(drag && drag.type === this.type && !this.isDropDisabled);
  }

  /** The list's items in order. */
  items(): HTMLElement[] {
    if (!this.element) return [];

    return Array.from(this.element.children).filter(
      (el): el is HTMLElement => el instanceof HTMLElement && el.classList.contains('euiDraggable')
    );
  }

  count(): number {
    return this.items().length;
  }

  measure(): Slot[] {
    return this.items().map((item) => {
      const rect = item.getBoundingClientRect();
      const offset = new DOMMatrixReadOnly(getComputedStyle(item).transform);

      // positions without the sliding transforms
      return this.isHorizontal
        ? { start: rect.left - offset.m41, end: rect.right - offset.m41, draggableId: item.dataset['draggableId'] ?? '' }
        : { start: rect.top - offset.m42, end: rect.bottom - offset.m42, draggableId: item.dataset['draggableId'] ?? '' };
    });
  }

  /** Index in the final list for a pointer position. */
  indexAt(position: number): number {
    const drag = this.context.drag;

    if (!this.slots || this.slotsSession !== drag?.session) {
      this.slots = this.measure();
      this.slotsSession = drag?.session;
    }

    const slots = this.slots;
    const others = slots.filter((slot) => slot.draggableId !== drag?.draggableId);

    return others.filter((slot) => (slot.start + slot.end) / 2 < position).length;
  }

  @action
  onDragOver(event: DragEvent): void {
    if (!this.accepts || this.context.drag?.isKeyboard) return;

    event.preventDefault();

    const position = this.isHorizontal ? event.clientX : event.clientY;

    this.context.setDestination({ droppableId: this.args.droppableId, index: this.indexAt(position) });
  }

  @action
  onDragLeave(event: DragEvent): void {
    const next = event.relatedTarget as Node | null;

    if (!this.accepts || (next && this.element?.contains(next))) return;

    if (this.isDraggingOver) this.context.setDestination(null);
  }

  @action
  onDrop(event: DragEvent): void {
    if (!this.accepts) return;

    event.preventDefault();
    this.context.end('DROP');
  }

  register = modifier((element: HTMLElement) => {
    this.element = element;
  });

  <template>
    <div
      class={{this.classes}}
      data-test-subj="droppable"
      data-droppable-id={{@droppableId}}
      {{this.register}}
      {{on "dragover" this.onDragOver}}
      {{on "dragleave" this.onDragLeave}}
      {{on "drop" this.onDrop}}
      ...attributes
    >
      {{yield (hash Draggable=(component EuiDraggable droppable=this))}}
    </div>
  </template>
}
