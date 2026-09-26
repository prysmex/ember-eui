import { modifier } from 'ember-modifier';

/**
 * Associates an EuiFormRow's <label> with the form control rendered in
 * the row, like EUI React does by cloning its child with the row's id.
 *
 * Nothing changes when the label already points to an existing element,
 * e.g. when the same id is passed to the row and the field
 * (`{{#let (randomId) as |id|}}<EuiFormRow @id={{id}}><EuiFieldText
 * @id={{id}} />`). Otherwise, for the first text-like control in the row:
 * - if it has an id (every Eui field renders one), the label's `for`
 *   points to it, so the control is left untouched
 * - if it has none (e.g. a plain <input>), it gets the row's id
 *
 * Checkboxes, radios and switches are never used: they have their own
 * labels, and pointing the row label at one would make clicking the row
 * label toggle it (e.g. the first checkbox of an EuiCheckboxGroup).
 *
 * Only labels rendered with a `for` are handled (not legends, not rows
 * with @hasChildLabel={{false}}). Controls rendered later (conditionally,
 * asynchronously) are picked up through a MutationObserver.
 */
const CONTROL = [
  'input:not([type="hidden"]):not([type="checkbox"]):not([type="radio"]):not(.fake-input-for-html-form-validity)',
  'select',
  'textarea'
].join(', ');

function associate(row: HTMLElement) {
  const label = row.querySelector<HTMLLabelElement>(
    ':scope > .euiFormRow__labelWrapper > label.euiFormRow__label[for]'
  );
  const control = row.querySelector<HTMLElement>(
    `:scope > .euiFormRow__fieldWrapper :is(${CONTROL})`
  );

  if (!label || !control) return;

  // already associated, e.g. the same @id was passed to the row and field
  if (label.htmlFor && row.ownerDocument.getElementById(label.htmlFor)) return;

  if (!control.id) {
    control.id = label.htmlFor;
  } else if (label.htmlFor !== control.id) {
    label.htmlFor = control.id;
  }
}

export default modifier(function associateFormRowLabel(
  row: HTMLElement,
  // the row id is passed so the association is redone when it changes
  _positional: [rowId: string]
) {
  associate(row);

  const fieldWrapper = row.querySelector(':scope > .euiFormRow__fieldWrapper');

  if (!fieldWrapper) return;

  const observer = new MutationObserver(() => associate(row));

  observer.observe(fieldWrapper, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['id']
  });

  return () => observer.disconnect();
});
