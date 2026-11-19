declare module 'ember-style-modifier/modifiers/style' {
  import Modifier from 'ember-modifier';

  type Styles = { [key: string]: any } | undefined;

  export default class StyleModifier extends Modifier<{
    Element: Element;
    Args: {
      Positional: [...Styles[]];
      Named: {};
    };
  }> {}
}
