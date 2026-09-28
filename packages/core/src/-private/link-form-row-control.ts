import { modifier } from 'ember-modifier';

/**
 * Links an EuiFormRow to the form control rendered in it, like EUI React
 * does by cloning its child with the row's ids:
 *
 * 1. The row's `<label for>` names the control. Nothing changes when the
 *    label already points to an existing element, e.g. when the same id is
 *    passed to the row and the field (`{{#let (randomId) as |id|}}
 *    <EuiFormRow @id={{id}}><EuiFieldText @id={{id}} />`). Otherwise, for
 *    the first text-like control in the row:
 *    - if it has an id (every Eui field renders one), the label's `for`
 *      points to it, so the control is left untouched
 *    - if it has none (e.g. a plain <input>), it gets the row's id
 * 2. The control's `aria-describedby` lists the row's help text and the
 *    errors shown, so screen readers read them with the control. Ids the
 *    control already had (e.g. passed by the app) are kept.
 *
 * Checkboxes, radios and switches are never used: they have their own
 * labels, and pointing the row label at one would make clicking the row
 * label toggle it (e.g. the first checkbox of an EuiCheckboxGroup). A
 * `<fieldset>` row (`@legendType="legend"`) without such a control is
 * described itself.
 *
 * The modifier runs again when the row id, help text or errors change. A
 * MutationObserver is only created when the control may still change: when
 * the label is not associated yet (the control may render later), or when
 * the control is described (it may be replaced). A row whose label already
 * points to its field and that shows no help text or errors has none.
 */
const CONTROL = [
  'input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]):not(.fake-input-for-html-form-validity)',
  'select',
  'textarea'
].join(', ');

interface LinkFormRowControlSignature {
  Element: HTMLElement;
  Args: {
    Positional: [rowId: string];
    Named: {
      /**
       * The row's help text and number of errors shown: only passed so the
       * modifier runs again when they change (their ids are read from the
       * DOM).
       */
      helpText?: unknown;
      errorCount?: number;
    };
  };
}

/** The ids this modifier added to each element's aria-describedby. */
const added = new WeakMap<Element, string[]>();

/**
 * Associates the row label with its control and returns the element to
 * describe, if any. `linked` tells whether the label already pointed to an
 * existing element.
 */
function associate(row: HTMLElement): { target: HTMLElement | null; linked: boolean } {
  const label = row.querySelector<HTMLLabelElement>(
    ':scope > .euiFormRow__labelWrapper > label.euiFormRow__label[for]'
  );
  const control = row.querySelector<HTMLElement>(
    `:scope > .euiFormRow__fieldWrapper :is(${CONTROL})`
  );
  const fallback = control ?? (row instanceof HTMLFieldSetElement ? row : null);

  if (!label?.htmlFor) return { target: fallback, linked: false };

  // already associated, e.g. the same @id was passed to the row and field
  const existing = row.ownerDocument.getElementById(label.htmlFor);
  if (existing) return { target: existing, linked: true };

  if (control) {
    if (!control.id) {
      control.id = label.htmlFor;
    } else {
      label.htmlFor = control.id;
    }
  }

  return { target: fallback, linked: false };
}

/** Ids of the errors and help text shown in the row, in order. */
function describedByIds(row: HTMLElement): string[] {
  return Array.from(
    row.querySelectorAll<HTMLElement>(
      ':scope > .euiFormRow__fieldWrapper > .euiFormErrorText[id], :scope > .euiFormRow__fieldWrapper > .euiFormHelpText[id]'
    ),
    (element) => element.id
  );
}

/** Sets the ids (those rendered) in the element's aria-describedby. */
function describe(element: HTMLElement, ids: string[]): void {
  const previous = added.get(element) ?? [];
  const own = (element.getAttribute('aria-describedby') ?? '')
    .split(/\s+/)
    .filter((id) => id && !previous.includes(id));
  const rendered = ids.filter(
    (id) => !own.includes(id) && element.ownerDocument.getElementById(id)
  );
  const value = [...own, ...rendered].join(' ');

  added.set(element, rendered);

  if (value === (element.getAttribute('aria-describedby') ?? '')) return;

  if (value) {
    element.setAttribute('aria-describedby', value);
  } else {
    element.removeAttribute('aria-describedby');
  }
}

export default modifier<LinkFormRowControlSignature>(function linkFormRowControl(
  row,
  // the row id is read so that a new id re-runs the association
  [_rowId],
  // the named args are only read so that changes re-run the modifier
  { helpText: _helpText, errorCount: _errorCount }
) {
  const ids = describedByIds(row);

  const initial = associate(row);
  const linked = initial.linked;
  let target = initial.target;

  if (target) describe(target, ids);

  const cleanUp = () => {
    if (target) describe(target, []);
  };

  const hasLabelFor = row.querySelector(
    ':scope > .euiFormRow__labelWrapper > label.euiFormRow__label[for]'
  );
  const mayChange =
    (hasLabelFor && !linked) || (ids.length > 0 && target !== row);
  const fieldWrapper = row.querySelector(':scope > .euiFormRow__fieldWrapper');

  if (!mayChange || !fieldWrapper) return cleanUp;

  const observer = new MutationObserver(() => {
    const next = associate(row).target;

    if (next !== target && target) describe(target, []);
    target = next;
    if (target) describe(target, ids);
  });

  observer.observe(fieldWrapper, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['id']
  });

  return () => {
    observer.disconnect();
    cleanUp();
  };
});
