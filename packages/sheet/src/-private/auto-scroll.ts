/**
 * Auto-scroll while a drag (select or fill) holds the pointer near an edge
 * of the grid's scroll area, or past it (V02-DESIGN.md 8.4): a frame loop
 * that scrolls by a speed growing with the distance (at most `MAX_SPEED`
 * px per frame) and then reports the pointer clamped inside the area, so
 * the drag's head follows rows rendered under a pointer that does not
 * move. A plain class: `update` with each pointer position, `stop` on
 * release and on destroy. It also stops when it cannot scroll further.
 */

/** Distance from an edge, in px, where scrolling starts. */
export const EDGE = 24;
/** The fastest scroll, in px per frame. */
export const MAX_SPEED = 20;

/** The area the pointer is measured against, in viewport px. */
export interface ScrollBounds {
  top: number;
  bottom: number;
  left: number;
  right: number;
  /** The frozen columns' right edge: scrolling left starts there (the pointer is still clamped to `left`). */
  frozenRight?: number;
}

export interface AutoScrollHooks {
  /** The scroll area now (the grid body without its header, footer and scroll bars); null: gone. */
  bounds(): ScrollBounds | null;
  /** Scrolls by `dx`, `dy`; returns whether anything moved. */
  scrollBy(dx: number, dy: number): boolean;
  /** After a frame's scroll: the pointer, clamped inside the area. */
  onFrame(x: number, y: number): void;
}

/** Frame scheduling, replaceable by tests (P8, P9) without touching `window.requestAnimationFrame`. */
export const frames = {
  request: (callback: FrameRequestCallback): number =>
    window.requestAnimationFrame(callback),
  cancel: (id: number): void => window.cancelAnimationFrame(id)
};

/** Speed on one axis: negative towards the start edge, 0 outside both zones. */
function speed(position: number, start: number, end: number): number {
  const fromStart = start + EDGE - position;
  const fromEnd = position - (end - EDGE);
  // a scroll area smaller than both zones scrolls towards the nearer edge
  const d =
    fromStart > 0 && fromStart >= fromEnd
      ? -fromStart
      : fromEnd > 0
        ? fromEnd
        : 0;
  if (d === 0) return 0;
  const magnitude = Math.min(
    MAX_SPEED,
    Math.max(1, Math.ceil(Math.abs(d) / 3))
  );
  return Math.sign(d) * magnitude;
}

export default class AutoScroll {
  private frame: number | null = null;
  private x = 0;
  private y = 0;

  constructor(private hooks: AutoScrollHooks) {}

  get running(): boolean {
    return this.frame !== null;
  }

  /** The pointer moved: starts the loop when it is in an edge zone or past an edge. */
  update(x: number, y: number): void {
    this.x = x;
    this.y = y;
    if (this.frame === null && this.velocity()) this.schedule();
  }

  stop(): void {
    if (this.frame !== null) frames.cancel(this.frame);
    this.frame = null;
  }

  private velocity(): { dx: number; dy: number } | null {
    const bounds = this.hooks.bounds();
    if (!bounds) return null;
    const dx = speed(
      this.x,
      Math.max(bounds.left, bounds.frozenRight ?? bounds.left),
      bounds.right
    );
    const dy = speed(this.y, bounds.top, bounds.bottom);
    return dx || dy ? { dx, dy } : null;
  }

  private schedule(): void {
    this.frame = frames.request(() => this.tick());
  }

  private tick(): void {
    this.frame = null;
    const velocity = this.velocity();
    const bounds = this.hooks.bounds();
    if (!velocity || !bounds) return;
    const moved = this.hooks.scrollBy(velocity.dx, velocity.dy);
    this.hooks.onFrame(
      Math.min(Math.max(this.x, bounds.left + 1), bounds.right - 1),
      Math.min(Math.max(this.y, bounds.top + 1), bounds.bottom - 1)
    );
    // the edge is reached: nothing left to scroll that way
    if (moved) this.schedule();
  }
}
