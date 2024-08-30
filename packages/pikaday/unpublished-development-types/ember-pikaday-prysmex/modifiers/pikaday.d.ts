declare module 'ember-pikaday/modifiers/pikaday' {
  import Modifier from 'ember-modifier';

  export interface EmberKeyboardEvent {
    stopImmediatePropagation: () => void;
    stopPropagation: () => void;
  }

  export default class PikadayModifier extends Modifier<{
    Element: Element;
    Args: {
      Positional: [...any[]];
      Named: {
        value?: Date;
        onSelect?: (date: Date) => void;
        setDefaultDate?: boolean;
        defaultDate?: Date;
        onOpen?: () => void;
        onDraw?: () => void;
        onClose?: () => void;
        format?: string;
        minDate?: Date;
        maxDate?: Date;
        theme?: string;
        yearRange?: number[];
        i18n?: {
          t: (key: string) => string;
        };
        firstDay?: number;
        container?: HTMLElement;
        bound?: boolean;
        register?: (pikaday: any) => void;
        moment?: any;
      };
    };
  }> {}
}
