import { assert } from '@ember/debug';

const attributes = ['src', 'alt', 'href', 'target'];

const createDocument = () => {
  // if (typeof document === 'undefined') {
  //   // eslint-disable-next-line no-undef
  //   let { Document } = FastBoot.require('simple-dom');
  //   return new Document();
  // }
  return document;
};

export const toDOM = (tree) => {
  let document = createDocument();
  let components = [];

  const toElements = (parent, nodes = []) => {
    nodes?.forEach((node) => {
      let el = toElement(node);
      if (el) {
        parent.appendChild(el);
      }
    });
    return parent;
  };

  const createElement = (name: string, node, className: string) => {
    let element = document.createElement(name);
    let properties = node.properties;
    let classNames = [];
    if (properties) {
      if (properties.className) {
				console.log(properties.className)
        classNames.push(...properties.className);
      }
      for (let key in properties) {
        if (attributes.includes(key)) {
          let value = properties[key];
          element.setAttribute(key, value);
        } else {
          // temporary
          if (key !== 'className') {
            console.warn('Unmapped node property', key);
          }
        }
      }
    }
    if (className) {
      classNames.push(className);
    }
    if (classNames.length) {
      element.setAttribute('class', classNames.join(' '));
    }
    return element;
  };

  const toElement = (node) => {
    if (node) {
      let { type } = node;
      if (type === 'root') {
        let element = createElement('div', node, 'root');
        return toElements(element, node.children);
      } else if (type === 'element') {
        let element = createElement(node.tagName, node);
        return toElements(element, node.children);
      } else if (type === 'text') {
        return document.createTextNode(node.value);
      } else if (type === 'component') {
        let { inline } = node.properties;
        let element = createElement(inline ? 'span' : 'div', node, 'component');
        let { _children, ...properties } = node.properties;
        let content = toElements(document.createElement('span'), node.children);
        components.push({
          element,
          content,
          ...properties
        });
        return element;
      }
      assert(`Unsupported node '${type}'`, false);
    }
  };

  let element = toElement(tree);

  return {
    element,
    components
  };
};
