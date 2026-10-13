/*
 * Ported from the pieces of `react-focus-on` / `react-remove-scroll-bar` that
 * upstream's EuiFocusTrap relies on (scroll locking with scrollbar gap
 * compensation, and isolation of the content outside the trap), as plain DOM
 * helpers for the Ember EuiFocusTrap.
 */

export type EuiFocusTrapGapMode = 'padding' | 'margin';

let scrollLocks = 0;
let savedBody: { overflow: string; gap: string; prop: string } | undefined;

/**
 * Hides the body scrollbar and keeps its width as padding (or margin) so the
 * page does not jump. Locks are counted: the last release restores the body.
 */
export function lockBodyScroll(gapMode: EuiFocusTrapGapMode = 'padding') {
  const body = document.body;
  if (scrollLocks === 0) {
    const gap = Math.max(
      0,
      window.innerWidth - document.documentElement.clientWidth
    );
    const prop = gapMode === 'margin' ? 'marginInlineEnd' : 'paddingInlineEnd';
    savedBody = { overflow: body.style.overflow, gap: body.style[prop], prop };
    const current = parseFloat(getComputedStyle(body)[prop]) || 0;
    body.style.overflow = 'hidden';
    if (gap > 0) body.style[prop] = `${current + gap}px`;
  }
  scrollLocks++;
  let released = false;
  return () => {
    if (released) return;
    released = true;
    scrollLocks--;
    if (scrollLocks === 0 && savedBody) {
      body.style.overflow = savedBody.overflow;
      (body.style as unknown as Record<string, string>)[savedBody.prop] =
        savedBody.gap;
      savedBody = undefined;
    }
  };
}

/**
 * `noIsolation={false}`: hides everything outside the trap from assistive
 * technology (`aria-hidden`) and from the pointer. Siblings along the path
 * from `body` to the trap (and its shards) are handled at call time, as
 * `aria-hidden`'s `hideOthers` does; later additions (portals) are untouched.
 */
export function isolateOutside(keep: HTMLElement[]) {
  const touched: Array<{
    element: HTMLElement;
    ariaHidden: string | null;
    pointerEvents: string;
  }> = [];
  hideSiblings(document.body, new Set(keep), touched);

  return () => {
    for (const { element, ariaHidden, pointerEvents } of touched) {
      if (ariaHidden === null) element.removeAttribute('aria-hidden');
      else element.setAttribute('aria-hidden', ariaHidden);
      element.style.pointerEvents = pointerEvents;
    }
  };
}

function hideSiblings(
  parent: HTMLElement,
  keep: Set<HTMLElement>,
  touched: Array<{
    element: HTMLElement;
    ariaHidden: string | null;
    pointerEvents: string;
  }>
) {
  if (keep.has(parent)) return;
  for (const child of Array.from(parent.children)) {
    if (!(child instanceof HTMLElement)) continue;
    if (['SCRIPT', 'STYLE', 'LINK'].includes(child.tagName)) continue;
    if (child.hasAttribute('aria-live')) continue;
    const holdsKept = [...keep].some((k) => k === child || child.contains(k));
    if (holdsKept) {
      hideSiblings(child, keep, touched);
    } else {
      touched.push({
        element: child,
        ariaHidden: child.getAttribute('aria-hidden'),
        pointerEvents: child.style.pointerEvents
      });
      child.setAttribute('aria-hidden', 'true');
      child.style.pointerEvents = 'none';
    }
  }
}
