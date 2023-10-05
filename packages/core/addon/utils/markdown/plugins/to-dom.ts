/*
This util was extracted from https://github.com/ampatspell/ember-cli-remark-static/blob/v3.0.5/addon/util/to-dom.js
*/

import { assert } from '@ember/debug';
import { RehypeNode } from '../markdown-types';

const attributes = ['src', 'alt', 'href', 'target', 'title'];

const createDocument = () => {
  return document;
};

export interface DynamicComponent {}

export const toDOM = (
  tree: RehypeNode,
  options?: {
    rootClasses?: string[];
  }
) => {
  let document = createDocument();
  let components: DynamicComponent[] = [];

  const toElements = (parent: Node, nodes: RehypeNode[] = []) => {
    nodes?.forEach((node) => {
      let el = toElement(node);
      if (el) {
        parent.appendChild(el);
      }
    });
    return parent;
  };

  const createElement = (
    name: string,
    node: RehypeNode,
    classesToAdd?: string[] | string
  ) => {
    let element = document.createElement(name);
    let properties = node.properties;
    let finalClassNames = [];
    if (properties) {
      if (properties.className) {
        finalClassNames.push(...(properties.className as string[]));
      }
      for (let key in properties) {
        if (attributes.includes(key)) {
          let value = properties[key];
          element.setAttribute(key, value as string);
        } else {
          // temporary
          if (key !== 'className') {
            console.warn('Unmapped node property', key);
          }
        }
      }
    }
    if (classesToAdd) {
      if (Array.isArray(classesToAdd)) {
        finalClassNames.push(...classesToAdd);
      } else {
        finalClassNames.push(classesToAdd);
      }
    }

    element.classList.add(...finalClassNames);
    return element;
  };

  const toElement = (node: RehypeNode) => {
    if (node) {
      let { type } = node;
      if (type === 'root') {
        let element = createElement(
          'div',
          node,
          options?.rootClasses || ['root']
        );
        return toElements(element, node.children);
      } else if (type === 'element') {
        let element = createElement(node.tagName, node);
        return toElements(element, node.children);
      } else if (type === 'text') {
        return document.createTextNode(node.value);
      } else if (type === 'component') {
        let { inline } = node.properties;
        let element = createElement(inline ? 'span' : 'div', node, [
          'component'
        ]);
        let { _children, ...properties } = node.properties;
        let content = toElements(document.createElement('span'), node.children);
        components.push({
          element,
          content,
          ...properties
        });
        return element;
      } else if (type === 'raw') {
        return document.createTextNode(node.value);
      }
      assert(`Unsupported node '${type}'`, false);
    }
    return;
  };

  let element = toElement(tree);

  return {
    element,
    components
  };
};
