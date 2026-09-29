export type PanelModeType = 'collapsible' | 'main' | 'custom';
export type PanelPosition = 'first' | 'middle' | 'last';

export interface PanelState {
  id: string;
  /** Size in percent of the container. */
  size: number;
  prevSize: number;
  getSizePx: () => number;
  /** `[the panel's @minSize, twice its padding]`, e.g. `['20%', '32px']`. */
  minSize: [string, string];
  mode?: PanelModeType;
  isCollapsed: boolean;
  position: PanelPosition;
}

export interface ResizerState {
  id: string;
  isFocused: boolean;
  isDisabled: boolean;
}

/** Padding of EuiPanel per size, in px. */
export const PANEL_PADDING = { none: 0, s: 8, m: 16, l: 24 };

export function pxToPercent(proportion: number, whole: number): number {
  if (whole < 1 || proportion < 0) return 0;

  return (proportion / whole) * 100;
}

export function sizesOnly(panels: Record<string, PanelState>): Record<string, number> {
  return Object.fromEntries(Object.values(panels).map((panel) => [panel.id, panel.size]));
}

function minSizePercent(minSize: string, containerSize: number): number {
  const value = parseInt(minSize);

  if (minSize.includes('px')) return pxToPercent(value, containerSize);
  if (minSize.includes('%')) return pxToPercent(containerSize * (value / 100), containerSize);

  return 0;
}

/** The larger of the panel's minimum size and its padding, in percent. */
export function getPanelMinSize(minSize: [string, string], containerSize: number): number {
  return Math.max(minSizePercent(minSize[0], containerSize), minSizePercent(minSize[1], containerSize));
}

export function getPointerPosition(event: MouseEvent | TouchEvent, isHorizontal: boolean): number {
  const point = 'touches' in event ? event.touches[0]! : event;

  return isHorizontal ? point.clientX : point.clientY;
}

/** The closest open panel before or after the element. */
export function getSiblingPanel(element: Element | null, adjacency: 'prev' | 'next'): Element | null {
  if (!element) return null;

  const step = (el: Element) => (adjacency === 'prev' ? el.previousElementSibling : el.nextElementSibling);
  let sibling = step(element);

  while (sibling) {
    if (sibling.matches('.euiResizablePanel:not(.euiResizablePanel-isCollapsed)')) return sibling;
    sibling = step(sibling);
  }

  return null;
}
