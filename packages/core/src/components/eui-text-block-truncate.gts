import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiTextBlockTruncateStyles } from '../utils/eui/text-truncate.ts';

import type { ModifierLike } from '@glint/template';

const { euiTextBlockTruncate } = euiTextBlockTruncateStyles;

/** The clamp currently applied to each element (the newest one wins). */
const applied = new WeakMap<HTMLElement, { classes: string[] }>();

/**
 * Adds the line clamp (inline `-webkit-line-clamp`, like upstream's inline
 * style) and the given classes; both are removed again on teardown, so a
 * reactive change swaps them on the same element. When a new clamp replaces
 * an old one on the same element (a new cloned modifier), Glimmer may tear
 * the old one down after installing the new one, so a stale teardown leaves
 * the newer clamp alone.
 */
function applyClamp(
  element: HTMLElement,
  classes: string[],
  lines: number | undefined
): () => void {
  const previous = applied.get(element);
  if (previous) element.classList.remove(...previous.classes);
  const current = { classes };
  applied.set(element, current);
  element.classList.add(...classes);
  if (lines != null)
    element.style.setProperty('-webkit-line-clamp', String(lines));
  else element.style.removeProperty('-webkit-line-clamp');
  return () => {
    if (applied.get(element) !== current) return;
    applied.delete(element);
    element.classList.remove(...classes);
    element.style.removeProperty('-webkit-line-clamp');
  };
}

const clamp = modifier(
  (element: HTMLElement, [lines]: [number | undefined]) =>
    applyClamp(element, [], lines)
);

/** Does nothing: what the block receives when a wrapper is rendered. */
const noop = modifier((_element: HTMLElement) => {});

export type EuiTextBlockTruncateModifier = ModifierLike<{
  Element: HTMLElement;
}>;

export interface EuiTextBlockTruncateSignature {
  Element: HTMLDivElement;
  Args: {
    /** Number of lines the text is truncated to. */
    lines: number;
    /**
     * Styles the block's own element instead of rendering a wrapper `<div>`
     * (upstream's `cloneElement`): apply the modifier the block receives to
     * that single element, e.g. `<p {{clamp}}>…</p>`.
     */
    cloneElement?: boolean;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * The text. With `@cloneElement`, receives a modifier to put on the
     * element to truncate (a no-op otherwise).
     */
    default: [clamp: EuiTextBlockTruncateModifier];
  };
}

/**
 * Truncates a block of text to a number of lines with an ellipsis
 * (upstream `EuiTextBlockTruncate`, CSS line clamping).
 */
export default class EuiTextBlockTruncate extends Component<EuiTextBlockTruncateSignature> {
  @cached
  get classes(): string {
    return euiClass(
      getEuiThemeContext(this),
      euiTextBlockTruncate,
      this.args.css
    );
  }

  @cached
  get cloneClasses(): string[] {
    return ['euiTextBlockTruncate', ...this.classes.split(' ').filter(Boolean)];
  }

  /** The modifier the block applies to its own element with `@cloneElement`. */
  @cached
  get cloneModifier(): EuiTextBlockTruncateModifier {
    const classes = this.cloneClasses;
    const lines = this.args.lines;
    return modifier((element: HTMLElement) =>
      applyClamp(element, classes, lines)
    );
  }

  <template>
    {{#if @cloneElement}}
      {{yield this.cloneModifier}}
    {{else}}
      <div
        class="euiTextBlockTruncate {{this.classes}}"
        ...attributes
        {{clamp @lines}}
      >{{yield noop}}</div>
    {{/if}}
  </template>
}
