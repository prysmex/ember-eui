import '@glint/environment-ember-loose';

import Modifier from 'ember-modifier';

import type SvgJar from 'ember-svg-jar/types';

declare class RenderModifier<
  Args extends unknown[] = unknown[]
> extends Modifier<{
  Element: HTMLElement;
  Args: { Positional: [(element: Element, args: Args) => void, ...Args] };
}> {}

declare module '@glint/environment-ember-loose/registry' {
  export default interface Registry {
    'did-insert': typeof RenderModifier;
    'will-destroy': typeof RenderModifier;
    'svg-jar': typeof SvgJar;
  }
}

declare module '@glimmer/tracking' {
  /**
   * @decorator
   *
   * Memoizes the result of a getter based on autotracking.
   *
   * The `@cached` decorator can be used on native getters to memoize their return
   * values based on the tracked state they consume while being calculated.
   *
   * By default a getter is always re-computed every time it is accessed. On
   * average this is faster than caching every getter result by default.
   *
   * However, there are absolutely cases where getters are expensive, and their
   * values are used repeatedly, so memoization would be very helpful.
   * Strategic, opt-in memoization is a useful tool that helps developers
   * optimize their apps when relevant, without adding extra overhead unless
   * necessary.
   *
   * @example
   *
   * ```ts
   * import { tracked, cached } from '@glimmer/tracking';
   *
   * class Person {
   *   @tracked firstName = 'Jen';
   *   @tracked lastName = 'Weber';
   *
   *   @cached
   *   get fullName() {
   *     return `${this.firstName} ${this.lastName}`;
   *   }
   * }
   * ```
   */
  export let cached: PropertyDecorator;
}
