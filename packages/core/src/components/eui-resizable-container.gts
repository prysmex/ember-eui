import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { modifier } from 'ember-modifier';

import {
  getPanelMinSize,
  getPointerPosition,
  getSiblingPanel,
  pxToPercent,
  sizesOnly
} from '../-private/resizable.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import EuiResizableButton from './eui-resizable-container/button.gts';
import EuiResizablePanel from './eui-resizable-container/panel.gts';

import type { PanelState, ResizerState } from '../-private/resizable.ts';
import type { EuiResizableButtonSignature } from './eui-resizable-container/button';
import type { EuiResizablePanelSignature } from './eui-resizable-container/panel';
import type { ComponentLike } from '@glint/template';

export interface ToggleOptions {
  /** Which way the panel collapses: toward the `'left'` or the `'right'`. */
  direction: 'left' | 'right';
}

/**
 * Panels separated by draggable resize buttons, side by side
 * (`'horizontal'`) or stacked (`'vertical'`), like an IDE's sidebar and
 * editor. It yields `{ Panel, Button, togglePanel }`: alternate
 * `<c.Panel>`s and `<c.Button />`s as its direct children. Panels can be
 * collapsible (`@mode="collapsible"` next to a `@mode="main"` one).
 */
export interface EuiResizableContainerSignature {
  Element: HTMLDivElement;
  Args: {
    /** `'horizontal'` (side by side) or `'vertical'` (stacked). Defaults to `'horizontal'`. */
    direction?: 'horizontal' | 'vertical';
    /** Called with every panel's size (`{ [panelId]: percent }`) after a change. */
    onPanelWidthChange?: (sizes: Record<string, number>) => void;
    /** Called when a panel is collapsed or expanded. */
    onToggleCollapsed?: (panelId: string, options: ToggleOptions) => void;
  };
  Blocks: {
    default: [
      {
        /** A panel; see `EuiResizablePanel`'s arguments. */
        Panel: ComponentLike<{
          Element: HTMLDivElement;
          Args: Omit<EuiResizablePanelSignature['Args'], 'container'>;
          Blocks: EuiResizablePanelSignature['Blocks'];
        }>;
        /** The draggable separator between two panels. */
        Button: ComponentLike<{
          Element: HTMLButtonElement;
          Args: Omit<EuiResizableButtonSignature['Args'], 'container'>;
        }>;
        /** Collapses or expands a panel by id, e.g. from a button elsewhere. */
        togglePanel: (panelId: string, options: ToggleOptions) => void;
      }
    ];
  };
}

export default class EuiResizableContainer extends Component<EuiResizableContainerSignature> {
  @tracked panels: Record<string, PanelState> = {};
  @tracked resizers: Record<string, ResizerState> = {};
  @tracked isDragging = false;

  currentResizerPos = -1;
  prevPanelId: string | null = null;
  nextPanelId: string | null = null;
  containerSize = 1;
  registeredElement?: HTMLElement;

  get isHorizontal(): boolean {
    return (this.args.direction ?? 'horizontal') === 'horizontal';
  }

  get classes(): string {
    return `euiResizableContainer euiResizableContainer--${this.isHorizontal ? 'horizontal' : 'vertical'}`;
  }

  measure(): void {
    if (!this.registeredElement) return;

    const { width, height } = this.registeredElement.getBoundingClientRect();

    this.containerSize = this.isHorizontal ? width : height;
  }

  changed(): void {
    this.args.onPanelWidthChange?.(sizesOnly(this.panels));
  }

  /* registration ---------------------------------------------------------- */

  registerPanel = (panel: PanelState): void => {
    this.panels = { ...this.panels, [panel.id]: panel };
  };

  deregisterPanel = (panelId: string): void => {
    const { [panelId]: _removed, ...panels } = this.panels;

    this.panels = panels;
  };

  registerResizer = (resizer: ResizerState): void => {
    this.resizers = { ...this.resizers, [resizer.id]: resizer };
  };

  deregisterResizer = (resizerId: string): void => {
    const { [resizerId]: _removed, ...resizers } = this.resizers;

    this.resizers = resizers;
  };

  /* resizing -------------------------------------------------------------- */

  resize(prevPanelId: string, nextPanelId: string, deltaPx: number): boolean {
    const prevPanel = this.panels[prevPanelId];
    const nextPanel = this.panels[nextPanelId];

    if (!prevPanel || !nextPanel) return false;

    this.measure();

    const prevSize = pxToPercent(prevPanel.getSizePx() + deltaPx, this.containerSize);
    const nextSize = pxToPercent(nextPanel.getSizePx() - deltaPx, this.containerSize);

    if (
      prevSize < getPanelMinSize(prevPanel.minSize, this.containerSize) ||
      nextSize < getPanelMinSize(nextPanel.minSize, this.containerSize)
    ) {
      return false;
    }

    this.panels = {
      ...this.panels,
      [prevPanelId]: { ...prevPanel, size: prevSize },
      [nextPanelId]: { ...nextPanel, size: nextSize }
    };
    this.changed();

    return true;
  }

  @action
  onResizerMouseDown(event: MouseEvent | TouchEvent): void {
    const button = event.currentTarget as HTMLElement;
    const prevPanel = button.previousElementSibling;
    const nextPanel = button.nextElementSibling;

    if (!prevPanel || !nextPanel) return;

    this.isDragging = true;
    this.currentResizerPos = getPointerPosition(event, this.isHorizontal);
    this.prevPanelId = prevPanel.id;
    this.nextPanelId = nextPanel.id;
  }

  @action
  onMouseMove(event: MouseEvent | TouchEvent): void {
    if (!this.isDragging || !this.prevPanelId || !this.nextPanelId) return;

    const position = getPointerPosition(event, this.isHorizontal);

    if (this.resize(this.prevPanelId, this.nextPanelId, position - this.currentResizerPos)) {
      this.currentResizerPos = position;
    }
  }

  @action
  onMouseUp(): void {
    this.isDragging = false;
    this.currentResizerPos = -1;
    this.prevPanelId = null;
    this.nextPanelId = null;
  }

  @action
  onResizerKeyDown(event: KeyboardEvent): void {
    const button = event.currentTarget as HTMLElement;
    const { key } = event;
    const forward = key === 'ArrowDown' || key === 'ArrowRight';
    const backward = key === 'ArrowUp' || key === 'ArrowLeft';
    const matchesDirection = this.isHorizontal
      ? key === 'ArrowLeft' || key === 'ArrowRight'
      : key === 'ArrowUp' || key === 'ArrowDown';
    const prevPanelId = button.previousElementSibling?.id;
    const nextPanelId = button.nextElementSibling?.id;

    if (!(forward || backward) || !matchesDirection || !prevPanelId || !nextPanelId) return;

    event.preventDefault();
    this.resize(prevPanelId, nextPanelId, forward ? 10 : -10);
  }

  @action
  onResizerFocus(resizerId: string): void {
    this.resizers = Object.fromEntries(
      Object.values(this.resizers).map((resizer) => [
        resizer.id,
        { ...resizer, isFocused: resizer.id === resizerId }
      ])
    );
  }

  @action
  onResizerBlur(): void {
    this.resizers = Object.fromEntries(
      Object.values(this.resizers).map((resizer) => [resizer.id, { ...resizer, isFocused: false }])
    );
  }

  @action
  onContainerResize(): void {
    this.measure();
  }

  /* collapsing ------------------------------------------------------------ */

  @action
  togglePanel(panelId: string, options: ToggleOptions): void {
    const current = this.panels[panelId];
    const element = document.getElementById(panelId);

    if (!current || !element) return;

    this.measure();

    const panels = this.panels;
    const shouldCollapse = !current.isCollapsed;
    const prevResizer = element.previousElementSibling;
    const prevPanel = prevResizer?.previousElementSibling;
    const nextResizer = element.nextElementSibling;
    const nextPanel = nextResizer?.nextElementSibling;
    const resizersToDisable: Record<string, boolean> = {};

    if (prevResizer && prevPanel && panels[prevPanel.id]) {
      resizersToDisable[prevResizer.id] = panels[prevPanel.id]!.isCollapsed ? true : shouldCollapse;
    }
    if (nextResizer && nextPanel && panels[nextPanel.id]) {
      resizersToDisable[nextResizer.id] = panels[nextPanel.id]!.isCollapsed ? true : shouldCollapse;
    }

    let others: Record<string, PanelState> = {};

    if (prevPanel && panels[prevPanel.id] && !panels[prevPanel.id]!.isCollapsed && options.direction === 'right') {
      others[prevPanel.id] = panels[prevPanel.id]!;
    }
    if (nextPanel && panels[nextPanel.id] && !panels[nextPanel.id]!.isCollapsed && options.direction === 'left') {
      others[nextPanel.id] = panels[nextPanel.id]!;
    }

    let siblings = Object.keys(others).length;

    // several neighbours are collapsed: look further for an open panel
    if (!siblings) {
      const maybePrev = getSiblingPanel(element, 'prev');
      const maybeNext = getSiblingPanel(element, 'next');
      const validPrev = maybePrev ? panels[maybePrev.id] : undefined;
      const validNext = maybeNext ? panels[maybeNext.id] : undefined;

      if (validPrev && options.direction === 'right') {
        others[validPrev.id] = validPrev;
      } else if (validNext && options.direction === 'left') {
        others[validNext.id] = validNext;
      } else {
        if (validPrev) others[validPrev.id] = validPrev;
        if (validNext) others[validNext.id] = validNext;
      }

      siblings = Object.keys(others).length;
    }

    // collapsed panels keep room for the toggle button (24px)
    let newSize = shouldCollapse
      ? pxToPercent(current.mode ? 24 : 0, this.containerSize)
      : current.prevSize;
    const delta = shouldCollapse
      ? (current.size - newSize) / siblings
      : ((newSize - current.size) / siblings) * -1;
    const collapsedSize = Object.values(panels).reduce(
      (sum, panel) => (panel.id !== panelId && panel.isCollapsed ? sum + panel.size : sum),
      0
    );

    // reopening the only open panel: give it all the room left
    if (!shouldCollapse && !siblings) newSize = 100 - collapsedSize;

    let updated: Record<string, PanelState>;

    if (
      delta < 0 &&
      Object.values(others).some(
        (panel) => panel.size + delta < getPanelMinSize(panel.minSize, this.containerSize)
      )
    ) {
      // not enough room next to it: share the space evenly between open panels
      others = Object.fromEntries(
        Object.values(panels)
          .filter((panel) => panel.id !== panelId && !panel.isCollapsed)
          .map((panel) => [panel.id, panel])
      );
      newSize = (100 - collapsedSize) / (Object.keys(others).length + 1);
      updated = Object.fromEntries(
        Object.values(others).map((panel) => [panel.id, { ...panel, size: newSize }])
      );
    } else {
      updated = Object.fromEntries(
        Object.values(others).map((panel) => [panel.id, { ...panel, size: panel.size + delta }])
      );
    }

    this.panels = {
      ...panels,
      ...updated,
      [panelId]: {
        ...current,
        size: newSize,
        isCollapsed: shouldCollapse,
        prevSize: shouldCollapse ? current.size : newSize
      }
    };
    this.resizers = Object.fromEntries(
      Object.values(this.resizers).map((resizer) => [
        resizer.id,
        {
          ...resizer,
          isFocused: false,
          isDisabled: resizersToDisable[resizer.id] ?? resizer.isDisabled
        }
      ])
    );
    this.changed();
  }

  @action
  onPanelToggle(panelId: string, options: ToggleOptions): void {
    this.togglePanel(panelId, options);
    this.args.onToggleCollapsed?.(panelId, options);
  }

  registerElement = modifier((element: HTMLElement) => {
    this.registeredElement = element;
    this.measure();
  });

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class={{this.classes}}
      {{on "mousemove" this.onMouseMove}}
      {{on "mouseup" this.onMouseUp}}
      {{on "mouseleave" this.onMouseUp}}
      {{on "touchmove" this.onMouseMove}}
      {{on "touchend" this.onMouseUp}}
      {{resizeObserver onResize=this.onContainerResize}}
      {{this.registerElement}}
      ...attributes
    >
      {{yield
        (hash
          Panel=(component EuiResizablePanel container=this)
          Button=(component EuiResizableButton container=this)
          togglePanel=this.togglePanel
        )
      }}
    </div>
  </template>
}
