import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import { combine } from '@atlaskit/pragmatic-drag-and-drop/combine';
import { dropTargetForElements } from '@atlaskit/pragmatic-drag-and-drop/element/adapter';
import { autoScrollForElements } from '@atlaskit/pragmatic-drag-and-drop-auto-scroll/element';
import { modifier } from 'ember-modifier';

import { isDraggableData } from '../-private/drag-drop.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDroppableStyles } from '../utils/eui/styles.generated.ts';
import EuiDraggable from './eui-draggable.gts';
import EuiPanel from './eui-panel.gts';

import type EuiDragDropContext from './eui-drag-drop-context.gts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiDraggableSignature } from './eui-draggable';
import type { ComponentLike } from '@glint/template';

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
    /**
     * Renders the list as an `EuiPanel` (plain background, shadow, rounded
     * corners, no padding of its own: use `@spacing`).
     */
    withPanel?: boolean;
    /** Grows to fill its flex container. Defaults to `false`. */
    grow?: boolean;
    /**
     * Scrolls the list while an item is dragged near its edges (when the
     * list itself scrolls, e.g. with a max height). Defaults to `true`.
     */
    autoScroll?: boolean;
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
    return (
      this.context.drag?.destination?.droppableId === this.args.droppableId
    );
  }

  /** An item of this list's type is being dragged (and could land here). */
  get isDraggingType(): boolean {
    return this.context.drag?.type === this.type && !this.isDropDisabled;
  }

  /** Upstream's list styles; composed into the panel's own class with `@withPanel`. */
  @cached
  get css(): EuiCss {
    const styles = useEuiBorealisStyles(getEuiThemeContext(this), euiDroppableStyles);

    return [
      { boxSizing: 'border-box' },
      styles.euiDroppable,
      this.isDraggingType && styles.isDragging,
      this.isDraggingOver && styles.isDraggingOver,
      this.args.grow ? styles.grow : styles.noGrow,
      styles.spacing[this.args.spacing ?? 'none']
    ];
  }

  get stateClass(): string {
    return this.isDropDisabled ? 'euiDroppable euiDroppable-isDisabled' : 'euiDroppable';
  }

  @cached
  get classes(): string {
    return `${this.stateClass} ${euiClass(getEuiThemeContext(this), this.css)}`;
  }

  /** The list's items in order. */
  items(): HTMLElement[] {
    if (!this.element) return [];

    return Array.from(this.element.children).filter(
      (el): el is HTMLElement =>
        el instanceof HTMLElement && el.classList.contains('euiDraggable')
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
        ? {
            start: rect.left - offset.m41,
            end: rect.right - offset.m41,
            draggableId: item.dataset['draggableId'] ?? ''
          }
        : {
            start: rect.top - offset.m42,
            end: rect.bottom - offset.m42,
            draggableId: item.dataset['draggableId'] ?? ''
          };
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
    const others = slots.filter(
      (slot) => slot.draggableId !== drag?.draggableId
    );

    return others.filter((slot) => (slot.start + slot.end) / 2 < position)
      .length;
  }

  /** The list as a pragmatic drag and drop target. */
  register = modifier((element: HTMLElement) => {
    this.element = element;

    const context = this.context;

    return combine(
      autoScrollForElements({
        element,
        canScroll: ({ source }) =>
          this.args.autoScroll !== false &&
          isDraggableData(source.data, context.contextId)
      }),
      dropTargetForElements({
        element,
        getData: () => ({
          euiDragDropContext: context.contextId,
          droppableId: this.args.droppableId
        }),
        canDrop: ({ source }) =>
          isDraggableData(source.data, context.contextId) &&
          source.data.type === this.type &&
          !this.isDropDisabled,
        onDrag: ({ location, self }) => {
          // only the innermost list under the pointer takes the item
          if (location.current.dropTargets[0]?.element !== self.element) return;

          const { clientX, clientY } = location.current.input;

          context.setDestination({
            droppableId: this.args.droppableId,
            index: this.indexAt(this.isHorizontal ? clientX : clientY)
          });
        },
        onDragLeave: () => {
          if (this.isDraggingOver) context.setDestination(null);
        }
      })
    );
  });

  <template>
    {{#if @withPanel}}
      <EuiPanel
        class={{this.stateClass}}
        @hasShadow={{true}}
        @hasBorder={{false}}
        @paddingSize="none"
        @css={{this.css}}
        data-test-subj="droppable"
        data-droppable-id={{@droppableId}}
        {{this.register}}
        ...attributes
      >
        {{yield (hash Draggable=(component EuiDraggable droppable=this))}}
      </EuiPanel>
    {{else}}
      <div
        class={{this.classes}}
        data-test-subj="droppable"
        data-droppable-id={{@droppableId}}
        {{this.register}}
        ...attributes
      >
        {{yield (hash Draggable=(component EuiDraggable droppable=this))}}
      </div>
    {{/if}}
  </template>
}
