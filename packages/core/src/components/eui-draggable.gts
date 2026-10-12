import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';

import { draggable } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiDraggableItemStyles,
  euiDraggableStyles
} from '../utils/eui/styles.generated.ts';

import type { DraggableData } from '../-private/drag-drop.ts';
import type EuiDroppable from './eui-droppable.gts';

/** Controls a key press inside the item must reach (not lift the item). */
const INTERACTIVE =
  'input, button, textarea, select, option, optgroup, video, audio, a[href], [contenteditable]:not([contenteditable="false"])';

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
     * on it, e.g. `<EuiIcon @type="dragVertical" {{item.dragHandle}} />`. With
     * `'custom'` the item itself is not focusable and has no role either:
     * the handle becomes the focusable `role="button"` that lifts the item
     * with the keyboard (upstream's fully custom handle).
     */
    customDragHandle?: boolean | 'custom';
    /**
     * The item holds its own controls: it becomes a `role="group"` that is
     * not focusable itself, and key presses in those controls are theirs.
     */
    hasInteractiveChildren?: boolean;
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
  element?: HTMLElement;
  handle?: HTMLElement;
  disconnect?: () => void;

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

  get isFullyCustomDragHandle(): boolean {
    return this.args.customDragHandle === 'custom';
  }

  /** `button` by default, `group` with interactive children, none for a fully custom handle. */
  get role(): string | undefined {
    if (this.isFullyCustomDragHandle) return undefined;

    return this.args.hasInteractiveChildren ? 'group' : 'button';
  }

  /** Whether the item is lifted, on the `role="button"` item only. */
  get pressed(): string | undefined {
    if (this.role !== 'button') return undefined;

    return this.isDragging ? 'true' : 'false';
  }

  get tabindex(): string | undefined {
    if (this.args.isDragDisabled || this.args.hasInteractiveChildren || this.isFullyCustomDragHandle) {
      return undefined;
    }

    return '0';
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDraggableStyles);

    return `euiDraggable ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiDraggable,
      this.isClone && !this.isDragging && styles.hasClone,
      this.isDragging && styles.isDragging,
      this.args.isRemovable && styles.isRemovable,
      styles.spacing[this.args.spacing ?? 'none']
    )}`;
  }

  @cached
  get itemClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDraggableItemStyles);

    return [
      'euiDraggable__item',
      this.args.isDragDisabled && 'euiDraggable__item-isDisabled',
      euiClass(
        context,
        styles.euiDraggable__item,
        this.args.isDragDisabled && styles.disabled,
        this.isDragging && styles.isDragging
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** How far the item slides to make room for the dragged one, in px. */
  get offset(): number {
    const drag = this.drag;

    if (!drag?.destination) return 0;

    const listId = this.droppable.args.droppableId;
    const { source, destination, size } = drag;
    const index = this.args.index;

    if (this.isDragging) {
      // with the keyboard the item itself moves, past the items between
      if (!drag.isKeyboard || source.droppableId !== listId) return 0;

      const items = this.droppable.items();
      const from = items[source.index];
      const to = items[destination.index];

      if (!from || !to) return 0;

      // layout positions, which transforms and scaling leave alone
      const [start, length] = this.droppable.isHorizontal
        ? (['offsetLeft', 'offsetWidth'] as const)
        : (['offsetTop', 'offsetHeight'] as const);

      return destination.index > source.index
        ? to[start] + to[length] - (from[start] + from[length])
        : to[start] - from[start];
    }

    const isSource = source.droppableId === listId;
    const isDestination = destination.droppableId === listId;

    if (isSource && isDestination) {
      if (
        destination.index > source.index &&
        index > source.index &&
        index <= destination.index
      )
        return -size;
      if (
        destination.index < source.index &&
        index >= destination.index &&
        index < source.index
      )
        return size;

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
      transition:
        this.drag && !(this.isDragging && !this.drag.isKeyboard)
          ? 'transform 0.2s cubic-bezier(0.2, 0, 0, 1)'
          : undefined,
      opacity: hidden ? 0 : undefined
    });
  }

  size(): number {
    if (!this.element) return 0;

    // CSS px (not scaled like getBoundingClientRect), as the transforms use
    return this.droppable.isHorizontal ? this.element.offsetWidth : this.element.offsetHeight;
  }

  start(isKeyboard: boolean): void {
    this.droppable.context.start({
      draggableId: this.args.draggableId,
      type: this.droppable.type,
      source: {
        droppableId: this.droppable.args.droppableId,
        index: this.args.index
      },
      size: this.size(),
      isKeyboard,
      isClone: this.isClone
    });
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (this.args.isDragDisabled) return;

    // keys typed in the item's own controls are theirs (not the handle's)
    const target = event.target as Element;
    const wrapper = event.currentTarget as Element;

    if (
      target !== wrapper &&
      !(this.handle && this.handle.contains(target)) &&
      target.closest(INTERACTIVE) &&
      wrapper.contains(target.closest(INTERACTIVE))
    ) {
      return;
    }

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

      // keep the moved item in view (pragmatic only auto-scrolls pointer drags)
      schedule('afterRender', () => this.scrollIntoView());
    }
  }

  /**
   * Scrolls the closest scrollable container so the item shows where it
   * moved to (`scrollIntoView` ignores the transform that moves it).
   */
  scrollIntoView(): void {
    const element = this.element;
    let container = element?.parentElement;

    while (container && container !== document.body) {
      const { overflowX, overflowY } = getComputedStyle(container);
      const scrolls =
        (/(auto|scroll)/.test(overflowY) &&
          container.scrollHeight > container.clientHeight) ||
        (/(auto|scroll)/.test(overflowX) &&
          container.scrollWidth > container.clientWidth);

      if (scrolls) break;
      container = container.parentElement;
    }

    if (!element || !container || container === document.body) return;

    // where the item is going: its place without the (animating)
    // transform, moved by its target offset
    const rect = element.getBoundingClientRect();
    const current = new DOMMatrixReadOnly(getComputedStyle(element).transform);
    const horizontal = this.droppable.isHorizontal;
    const dx = (horizontal ? this.offset : 0) - current.m41;
    const dy = (horizontal ? 0 : this.offset) - current.m42;
    const item = {
      top: rect.top + dy,
      bottom: rect.bottom + dy,
      left: rect.left + dx,
      right: rect.right + dx
    };
    const box = container.getBoundingClientRect();

    if (item.bottom > box.bottom)
      container.scrollTop += item.bottom - box.bottom;
    else if (item.top < box.top) container.scrollTop -= box.top - item.top;
    if (item.right > box.right) container.scrollLeft += item.right - box.right;
    else if (item.left < box.left) container.scrollLeft -= box.left - item.left;
  }

  /** Registers the item with pragmatic drag and drop (again when its handle appears). */
  connect(): void {
    this.disconnect?.();
    this.disconnect = undefined;

    const element = this.element;

    if (!element || this.args.isDragDisabled) return;
    // with a custom handle, wait for it
    if (this.args.customDragHandle && !this.handle) return;

    const context = this.droppable.context;

    this.disconnect = draggable({
      element,
      dragHandle: this.args.customDragHandle ? this.handle : undefined,
      // the keyboard drag in progress keeps the pointer out
      canDrag: () => !this.args.isDragDisabled && !context.drag,
      getInitialData: (): DraggableData => ({
        euiDragDropContext: context.contextId,
        draggableId: this.args.draggableId,
        droppableId: this.droppable.args.droppableId,
        index: this.args.index,
        type: this.droppable.type,
        size: this.size(),
        isClone: this.isClone
      })
    });
  }

  register = modifier(
    (element: HTMLElement, [isDragDisabled]: [boolean | undefined]) => {
      this.element = element;
      void isDragDisabled;
      this.connect();

      return () => {
        this.disconnect?.();
        this.disconnect = undefined;
      };
    }
  );

  /** For `@customDragHandle`: the element that starts a drag. */
  dragHandle = modifier((handle: HTMLElement) => {
    this.handle = handle;
    handle.setAttribute('data-drag-handle', '');

    // a fully custom handle is what the keyboard lifts
    if (this.isFullyCustomDragHandle && !this.args.isDragDisabled) {
      if (!handle.hasAttribute('tabindex')) handle.setAttribute('tabindex', '0');
      if (!handle.hasAttribute('role')) handle.setAttribute('role', 'button');
    }

    this.connect();

    return () => {
      if (this.handle === handle) this.handle = undefined;
    };
  });

  <template>
    <div
      class={{this.classes}}
      data-test-subj="draggable"
      data-draggable-id={{@draggableId}}
      tabindex={{this.tabindex}}
      role={{this.role}}
      aria-roledescription={{if this.role "Draggable item"}}
      aria-pressed={{this.pressed}}
      style={{this.style}}
      {{this.register @isDragDisabled}}
      {{on "keydown" this.onKeyDown}}
      ...attributes
    >
      <div class={{this.itemClasses}}>
        {{yield (hash isDragging=this.isDragging dragHandle=this.dragHandle)}}
      </div>
    </div>
  </template>
}
