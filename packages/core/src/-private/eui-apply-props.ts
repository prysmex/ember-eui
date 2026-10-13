import { modifier } from 'ember-modifier';

/**
 * Props objects (`@contentProps`, `@textProps`) hold HTML attributes plus the
 * keys the owning component consumes itself.
 */
export interface EuiElementProps {
  /** Extra classes (`className` works too). */
  class?: string;
  className?: string;
  /** Extra styles composed into the element's class. */
  css?: import('../utils/eui/styles.ts').EuiCss;
  [attribute: string]: unknown;
}

const RESERVED = new Set(['class', 'className', 'css', 'children']);

/** The classes of a props object, from `class` and `className`. */
export function propsClasses(props?: EuiElementProps | false): string {
  if (!props) return '';
  return [props.class, props.className].filter(Boolean).join(' ');
}

/**
 * Applies the HTML attributes of a props hash (everything but `class`,
 * `className` and `css`) to the element, e.g. `data-test-subj` or
 * `aria-label`. `true` sets an empty attribute; `false`, `null` and
 * `undefined` leave it off. Attributes it set are removed again on update.
 */
export default modifier(
  (element: Element, [props]: [EuiElementProps | false | undefined]) => {
    const applied: string[] = [];
    if (props) {
      for (const [key, value] of Object.entries(props)) {
        if (
          RESERVED.has(key) ||
          value === undefined ||
          value === null ||
          value === false
        )
          continue;
        if (
          typeof value !== 'string' &&
          typeof value !== 'number' &&
          value !== true
        )
          continue;
        element.setAttribute(key, value === true ? '' : String(value));
        applied.push(key);
      }
    }
    return () => {
      for (const key of applied) element.removeAttribute(key);
    };
  }
);

/** Sets `min-inline-size` inline (upstream's `minWidth`): a CSS length or pixels. */
export const euiMinInlineSize = modifier(
  (element: Element, [value]: [string | number | false | undefined]) => {
    const target = element as HTMLElement;
    if (!value) return;
    target.style.minInlineSize =
      typeof value === 'number' ? `${value}px` : value;
    return () => target.style.removeProperty('min-inline-size');
  }
);
