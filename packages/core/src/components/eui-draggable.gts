import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { next } from '@ember/runloop';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';

import type EuiDroppable from './eui-droppable.gts';

const SPACING = {
  none: undefined,
  s: 'euiDraggable--s',
  m: 'euiDraggable--m',
  l: 'euiDraggable--l'
};

/**
 * An item of an `EuiDroppable` list (yielded as `Draggable`). Drag it with
 * the mouse, or focus it and press Space to lift it, the arrow keys to
 * move it and Space again to drop it (Escape cancels).
 */
export interface EuiDraggableSignature {
  Element: HTMLDivElement;
  Args: {
    /** Unique id of the item, reported in `onDragEnd`. */
    draggableId: string;
    /** Position of the item in its list. */
    index: number;
    /** The item cannot be dragged. */
    isDragDisabled?: boolean;
    /**
     * Only a handle drags the item: put the yielded `dragHandle` modifier
     * on it, e.g. `<EuiIcon @type="grab" {{item.dragHandle}} />`.
     */
    customDragHandle?: boolean;
    /** Skips the drop animation, e.g. for items removed on drop. */
    isRemovable?: boolean;
    /** Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'none'`. */
    spacing?: 'none' | 's' | 'm' | 'l';
    /** @private The list, set by `EuiDroppable`. */
    droppable: EuiDroppable;
  };
  Blocks: {
    /**
     * The item's content (one element, which gets the item classes);
     * yields `{ isDragging, dragHandle }`.
     */
    default: [
      {
        isDragging: boolean;
        dragHandle: EuiDraggable['dragHandle'];
      }
    ];
  };
}

export default class EuiDraggable extends Component<EuiDraggableSignature> {
  @tracked handleActive = false;

  registeredElement?: HTMLElement;

  get droppable(): EuiDroppable {
    return this.args.droppable;
  }

  get drag() {
    return this.droppable.context.drag;
  }

  get isDragging(): boolean {
    return this.drag?.draggableId === this.args.draggableId;
  }

  get isClone(): boolean {
    return Boolean(this.droppable.args.cloneDraggables);
  }

  get classes(): string {
    return [
      'euiDraggable',
      this.isClone && 'euiDraggable--hasClone',
      this.args.customDragHandle && 'euiDraggable--hasCustomDragHandle',
      this.isDragging && 'euiDraggable--isDragging',
      this.args.isRemovable && 'euiDraggable--withoutDropAnimation',
      SPACING[this.args.spacing ?? 'none']
    ]
      .filter(Boolean)
      .join(' ');
  }

  get itemClasses(): string {
    return [
      'euiDraggable__item',
      this.args.customDragHandle && 'euiDraggable__item--hasCustomDragHandle',
      this.args.isDragDisabled && 'euiDraggable__item--isDisabled',
      this.isDragging && 'euiDraggable__item--isDragging'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get isDraggable(): boolean {
    return !this.args.isDragDisabled && (!this.args.customDragHandle || this.handleActive);
  }

  /** How far the item slides to make room for the dragged one, in px. */
  get offset(): number {
    const drag = this.drag;

    if (!drag?.destination) return 0;

    const listId = this.droppable.args.droppableId;
    const { source, destination, size } = drag;
    const index = this.args.index;

    if (this.isDragging) {
      // with the keyboard the item itself moves (assuming items of its size)
      return drag.isKeyboard && source.droppableId === listId
        ? (destination.index - source.index) * size
        : 0;
    }

    const isSource = source.droppableId === listId;
    const isDestination = destination.droppableId === listId;

    if (isSource && isDestination) {
      if (destination.index > source.index && index > source.index && index <= destination.index) return -size;
      if (destination.index < source.index && index >= destination.index && index < source.index) return size;

      return 0;
    }

    if (isSource && !drag.isClone && index > source.index) return -size;
    if (isDestination && index >= destination.index) return size;

    return 0;
  }

  get style() {
    const offset = this.offset;
    // the dragged item stays in place, invisible, while its ghost follows the pointer
    const hidden = this.isDragging && !this.drag?.isKeyboard && !this.isClone;

    return cssStyle({
      transform: offset
        ? this.droppable.isHorizontal
          ? `translateX(${offset}px)`
          : `translateY(${offset}px)`
        : undefined,
      transition: this.drag && !(this.isDragging && !this.drag.isKeyboard) ? 'transform 0.2s cubic-bezier(0.2, 0, 0, 1)' : undefined,
      opacity: hidden ? 0 : undefined
    });
  }

  size(): number {
    if (!this.registeredElement) return 0;

    const rect = this.registeredElement.getBoundingClientRect();

    return this.droppable.isHorizontal ? rect.width : rect.height;
  }

  start(isKeyboard: boolean): void {
    this.droppable.context.start({
      draggableId: this.args.draggableId,
      type: this.droppable.type,
      source: { droppableId: this.droppable.args.droppableId, index: this.args.index },
      size: this.size(),
      isKeyboard,
      isClone: this.isClone
    });
  }

  @action
  onDragStart(event: DragEvent): void {
    if (!this.isDraggable) {
      event.preventDefault();

      return;
    }

    event.dataTransfer?.setData('text/plain', this.args.draggableId);
    if (event.dataTransfer) event.dataTransfer.effectAllowed = 'move';

    // after the browser took its snapshot of the item for the drag image
    next(() => this.start(false));
  }

  @action
  onDragEnd(): void {
    this.handleActive = false;

    // dropped outside a list (a drop in one ends the drag first)
    if (this.drag && this.isDragging) this.droppable.context.end('CANCEL');
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (this.args.isDragDisabled) return;

    const drag = this.drag;
    const lifted = drag?.isKeyboard && this.isDragging;
    const backward = this.droppable.isHorizontal ? 'ArrowLeft' : 'ArrowUp';
    const forward = this.droppable.isHorizontal ? 'ArrowRight' : 'ArrowDown';

    if (event.key === ' ' || event.key === 'Enter') {
      event.preventDefault();

      if (lifted) this.droppable.context.end('DROP');
      else if (!drag) this.start(true);

      return;
    }

    if (!lifted || !drag?.destination) return;

    if (event.key === 'Escape') {
      event.preventDefault();
      this.droppable.context.end('CANCEL');
    } else if (event.key === backward || event.key === forward) {
      event.preventDefault();

      const last = this.droppable.count() - 1;
      const index = drag.destination.index + (event.key === forward ? 1 : -1);

      this.droppable.context.setDestination({
        droppableId: drag.destination.droppableId,
        index: Math.min(Math.max(index, 0), last)
      });
    }
  }

  register = modifier((element: HTMLElement) => {
    this.registeredElement = element;
  });

  /** For `@customDragHandle`: only a press on the handle makes the item draggable. */
  dragHandle = modifier((handle: HTMLElement) => {
    const activate = () => (this.handleActive = true);

    handle.setAttribute('data-drag-handle', '');
    handle.addEventListener('mousedown', activate);
    handle.addEventListener('touchstart', activate);

    return () => {
      handle.removeEventListener('mousedown', activate);
      handle.removeEventListener('touchstart', activate);
    };
  });

  <template>
    <div
      class={{this.classes}}
      data-test-subj="draggable"
      data-draggable-id={{@draggableId}}
      draggable={{this.isDraggable}}
      tabindex={{unless @isDragDisabled "0"}}
      role="button"
      aria-roledescription="Draggable item"
      aria-pressed={{if this.isDragging "true" "false"}}
      style={{this.style}}
      {{this.register}}
      {{on "dragstart" this.onDragStart}}
      {{on "dragend" this.onDragEnd}}
      {{on "keydown" this.onKeyDown}}
      ...attributes
    >
      <div class={{this.itemClasses}}>
        {{yield (hash isDragging=this.isDragging dragHandle=this.dragHandle)}}
      </div>
    </div>
  </template>
}
