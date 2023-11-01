import { modifier } from 'ember-modifier';
type CssProperties = {
  [key: string]: string | number | undefined;
};

export default modifier(function simpleStyle(
  element: HTMLElement,
  [properties]: [CssProperties]
): void | (() => unknown) {
  for (let ele in properties) {
    if (properties[ele]) {
      //@ts-expect-error
      element.style[ele as string] = properties[ele] as any;
    }
  }
});
