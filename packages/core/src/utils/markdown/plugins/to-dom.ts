/*
This util was extracted from https://github.com/ampatspell/ember-cli-remark-static/blob/v3.0.5/addon/util/to-dom.js
*/

import { assert } from '@ember/debug';

import type { Replacer } from '../../../components/eui-markdown-format';
import type { RehypeNode } from '../markdown-types';
import type { ComponentLike } from '@glint/template';

const attributes = ['src', 'alt', 'href', 'target', 'title'];

const createDocument = () => {
  return document;
};

export interface DynamicComponent {
  element: HTMLElement;
  content: Node;
  componentName?: ComponentLike<{
    Args: {
      node: DynamicComponent;
      replaceNode?: Replacer;
    };
  }>;
}

export const toDOM = (
  tree: RehypeNode,
  options?: {
    rootClasses?: string[];
  }
) => {
  const document = createDocument();
  const components: DynamicComponent[] = [];

  const toElements = (parent: Node, nodes: RehypeNode[] = []) => {
    nodes?.forEach((node) => {
      const el = toElement(node);

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
    const element = document.createElement(name);
    const properties = node.properties;
    const finalClassNames = [];

    if (properties) {
      if (properties['className']) {
        finalClassNames.push(...(properties['className'] as string[]));
      }

      for (const key in properties) {
        if (attributes.includes(key)) {
          const value = properties[key];

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
      const { type } = node;

      if (type === 'root') {
        const element = createElement(
          'div',
          node,
          options?.rootClasses || ['root']
        );

        return toElements(element, node.children);
      } else if (type === 'element') {
        const element = createElement(node.tagName, node);

        return toElements(element, node.children);
      } else if (type === 'text') {
        return document.createTextNode(node.value);
      } else if (type === 'component') {
        const { inline } = node.properties;
        const element = createElement(inline ? 'span' : 'div', node, [
          'component'
        ]);
        const { _children, ...properties } = node.properties;
        const content = toElements(document.createElement('span'), node.children);

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

  const element = toElement(tree);

  return {
    element,
    components
  };
};
