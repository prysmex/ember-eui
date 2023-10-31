declare module 'ember-keyboard/modifiers/on-key' {
  import Modifier from 'ember-modifier';

  export interface EmberKeyboardEvent {
    stopImmediatePropagation: () => void;
    stopPropagation: () => void;
  }

  export default class OnKeyModifier extends Modifier<{
    Element: HTMLElement;
    Args: {
      Positional: [
        string,
        (event: KeyboardEvent, ekEvent: EmberKeyboardEvent) => unknown
      ];
      Named: {
        priority?: number;
      };
    };
  }> {}
}
