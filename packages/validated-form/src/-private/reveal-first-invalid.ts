const INVALID = '[aria-invalid="true"], :invalid:not(form, fieldset)';

const FOCUSABLE = [
  'input:not([type="hidden"])',
  'textarea',
  'select',
  'button',
  '[tabindex]:not([tabindex="-1"])',
  '[contenteditable]:not([contenteditable="false"])'
].join(', ');

function canFocus(element: Element): element is HTMLElement {
  return (
    element instanceof HTMLElement &&
    element.matches(FOCUSABLE) &&
    !element.matches(':disabled') &&
    // rendered: not display: none, nor inside it
    element.getClientRects().length > 0
  );
}

/**
 * Scrolls the first invalid field of `form` into view and focuses its
 * control, as the browser does when its own constraint validation blocks a
 * submit. The first match in document order is a row's label or its
 * control; the whole row is scrolled to, and the first control in it that
 * can take focus is focused. Custom fields that report their validity
 * through a hidden stand-in input thus get their row scrolled to and their
 * visible control focused, never the stand-in (which the browser cannot
 * focus).
 */
export function revealFirstInvalid(form: HTMLElement): void {
  if (!form.isConnected) return;

  const invalid = form.querySelector(INVALID);
  if (!invalid) return;

  const row = invalid.closest('.euiFormRow') ?? invalid;
  const control = [row, ...row.querySelectorAll(FOCUSABLE)].find(canFocus);

  row.scrollIntoView({ block: 'center', behavior: 'smooth' });
  control?.focus({ preventScroll: true });
}
