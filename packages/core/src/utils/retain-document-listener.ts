const counts = new Map<string, Map<EventListener, number>>();

/**
 * Adds a shared document listener for the first holder and removes it when
 * the last holder releases it. Holders pass the same (static) handler, so a
 * grid or table adds it once however many instances are mounted. Returns the
 * release function (idempotent).
 */
export function retainDocumentListener(type: string, handler: EventListener): () => void {
  let handlers = counts.get(type);
  if (!handlers) counts.set(type, (handlers = new Map()));

  const count = handlers.get(handler) ?? 0;
  if (count === 0) document.addEventListener(type, handler);
  handlers.set(handler, count + 1);

  let released = false;
  return () => {
    if (released) return;
    released = true;
    const current = (handlers.get(handler) ?? 1) - 1;
    if (current <= 0) {
      handlers.delete(handler);
      document.removeEventListener(type, handler);
    } else {
      handlers.set(handler, current);
    }
  };
}
