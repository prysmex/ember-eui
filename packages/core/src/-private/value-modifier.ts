import { registerDestructor } from '@ember/destroyable';

import Modifier from 'ember-modifier';

import type Owner from '@ember/owner';
import type { ModifierLike } from '@glint/template';
import type { ArgsFor } from 'ember-modifier';

type Setup<P extends unknown[]> = (
  element: Element,
  positional: P
) => void | (() => void);

export interface ValueModifierSignature<P extends unknown[]> {
  Element: Element;
  Args: { Positional: P };
}

/**
 * Like a function modifier, but `setup` re-runs (after its teardown) only
 * when a positional argument changes value (`===`), not whenever a tracked
 * value it was derived from changes. Effects derived from the flyout
 * manager's state use it, so unrelated dispatches do not re-run them.
 */
export function valueModifier<P extends unknown[]>(
  setup: Setup<P>
): ModifierLike<ValueModifierSignature<P>> {
  return class ValueModifier extends Modifier<ValueModifierSignature<P>> {
    #previous?: P;
    #teardown?: () => void;

    constructor(owner: Owner, args: ArgsFor<ValueModifierSignature<P>>) {
      super(owner, args);
      registerDestructor(this, () => this.#teardown?.());
    }

    modify(element: Element, positional: P): void {
      const previous = this.#previous;
      if (
        previous &&
        previous.length === positional.length &&
        previous.every((value, index) => value === positional[index])
      ) {
        return;
      }

      this.#previous = [...positional] as P;
      this.#teardown?.();
      this.#teardown = setup(element, positional) || undefined;
    }
  };
}
