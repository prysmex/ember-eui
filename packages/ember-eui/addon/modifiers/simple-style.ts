import { modifier } from 'ember-modifier';
type CssProperties = {
  [key: string]: string;
};

export default modifier(function simpleStyle(
  element: HTMLDivElement,
  [properties]: [CssProperties]
): void | (() => unknown) {
  for (let ele in properties) {
    properties[ele] && (element.style[ele as any] = properties[ele]);
  }
});
