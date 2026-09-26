/**
 * Scrolls to the element with the given id (with or without a leading `#`)
 * once it is rendered. Docs pages render after the route transition
 * resolves, so retry for a few frames before giving up.
 */
export function scrollToHash(hash: string, attempts = 30): void {
  const id = decodeURIComponent(hash.replace(/^#/, ''));

  if (!id) {
    return;
  }

  const element = document.getElementById(id);

  if (element) {
    element.scrollIntoView();
  } else if (attempts > 0) {
    requestAnimationFrame(() => scrollToHash(id, attempts - 1));
  }
}
