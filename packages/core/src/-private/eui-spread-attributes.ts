import { modifier } from 'ember-modifier';

/** Keys of a `*Props` object that are args or handled elsewhere, never attributes. */
const RESERVED = new Set(['className', 'class', 'css', 'children', 'key', 'ref']);

/**
 * @private Applies the extra props of a React-style `xxxProps` object as
 * attributes of the element (`aria-label`, `data-test-subj`, `id`, …), like
 * upstream's `{...props}` spread. Keys in `exclude` are args of the
 * component the object is meant for and are skipped, as are functions,
 * `null`/`undefined`/`false`. `true` sets an empty attribute (`disabled`).
 * Attributes it set are put back when the object changes or on teardown.
 */
export default modifier(
  (
    element: Element,
    [props, exclude]: [
      Record<string, unknown> | undefined,
      readonly string[] | undefined
    ]
  ) => {
    if (!props) return;
    const skip = new Set(exclude);
    const restore: Array<[string, string | null]> = [];
    for (const [name, value] of Object.entries(props)) {
      if (RESERVED.has(name) || skip.has(name)) continue;
      if (value == null || value === false || typeof value === 'function') {
        continue;
      }
      if (typeof value === 'object' || typeof value === 'symbol') continue;
      restore.push([name, element.getAttribute(name)]);
      element.setAttribute(name, value === true ? '' : String(value as string | number | bigint));
    }
    return () => {
      for (const [name, previous] of restore) {
        if (previous === null) element.removeAttribute(name);
        else element.setAttribute(name, previous);
      }
    };
  }
);
