declare module 'ember-focus-trap/modifiers/focus-trap' {
  import Modifier from 'ember-modifier';

  export default class FocusTrapModifier extends Modifier<{
    Element: HTMLElement;
    Args: {
      Positional: [];
      Named: {
        isActive?: boolean;
        isPaused?: boolean;
        shouldSelfFocus?: boolean;
        focusTrapOptions?: any;
        additionalElements?: HTMLElement[];
        _createFocusTrap?: () => void;
      };
    };
  }> {}
}
