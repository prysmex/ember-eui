declare module "ember-style-modifier/modifiers/style" {
  import Modifier from "ember-modifier";

  export default class StyleModifier extends Modifier<{
    Element: HTMLElement;
    Args: {
      Positional: [{ [key: string]: any }];
      Named: {};
    };
  }> {}
}
