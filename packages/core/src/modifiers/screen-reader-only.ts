import { getOwner } from '@ember/owner';
import Modifier from 'ember-modifier';

import { euiScreenReaderOnlyClass } from '../components/eui-screen-reader-only.gts';

import type EuiEmotionService from '../services/eui-emotion.ts';
import type Owner from '@ember/owner';
import type { ArgsFor, NamedArgs, PositionalArgs } from 'ember-modifier';

interface ScreenReaderOnlySignature {
  Element: Element;
  Args: { Positional: [showOnFocus?: boolean] };
}

/**
 * Hides one element visually but keeps it for screen readers, with the
 * upstream `euiScreenReaderOnly` styles (`{{screenReaderOnly true}}` shows
 * it while it has focus). Modifiers have no provider context, so the styles
 * go into the owner's default Emotion cache; they do not depend on the theme.
 */
export default class ScreenReaderOnlyModifier extends Modifier<ScreenReaderOnlySignature> {
  #classes: string[] = [];
  #owner: Owner | undefined;

  constructor(owner: Owner, args: ArgsFor<ScreenReaderOnlySignature>) {
    super(owner, args);
    this.#owner = owner;
  }

  modify(
    element: Element,
    [showOnFocus = false]: PositionalArgs<ScreenReaderOnlySignature>,
    _named: NamedArgs<ScreenReaderOnlySignature>
  ) {
    const service = (this.#owner ?? getOwner(this))?.lookup(
      'service:eui-emotion'
    ) as EuiEmotionService | undefined;
    const next = service
      ? euiScreenReaderOnlyClass(service.context, showOnFocus).split(' ')
      : [showOnFocus ? 'euiScreenReaderOnly-showOnFocus' : 'euiScreenReaderOnly'];
    element.classList.remove(...this.#classes);
    element.classList.add(...next);
    this.#classes = next;
  }
}
