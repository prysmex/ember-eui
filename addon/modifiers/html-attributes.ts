import { modifier } from 'ember-modifier';

type Attribute = {
  name: string;
  value: string;
};

export default modifier(function htmlAttributes(element: HTMLElement, [attributes]: [Attribute[]]) {
  if (attributes) {
    attributes.forEach(({ name, value }) => {
      element.setAttribute(name, `${element.getAttribute(name)} ${value}`);
    });
  }
});
