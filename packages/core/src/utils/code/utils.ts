/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { highlight,listLanguages } from 'refractor';

import type { CommonArgs } from '../../components/common';
import type { AST, RefractorNode } from 'refractor';

/**
 * Utils shared between EuiCode and EuiCodeBlock
 */

export type EuiCodeSharedProps = CommonArgs & {
  /**
   * Sets the syntax highlighting for a specific language
   * @see [https://prismjs.com/#supported-languages](https://prismjs.com/#supported-languages) for options
   */
  language?: string;
  transparentBackground?: boolean;
};

export const SUPPORTED_LANGUAGES = listLanguages();
export const DEFAULT_LANGUAGE = 'text';

export const checkSupportedLanguage = (language: string): string => {
  return SUPPORTED_LANGUAGES.includes(language) ? language : DEFAULT_LANGUAGE;
};

const createDocument = () => {
  return document;
};

const attributes = [
  'src',
  'alt',
  'href',
  'target',
  'title',
  'data-line-number',
  'aria-hidden',
  'style'
];

export interface DynamicComponent {}

export const getHtmlContent = (nodes: RefractorNode[]) => {
  const document = createDocument();
  let components: DynamicComponent[] = [];

  const toElements = (parent: HTMLElement, nodes: RefractorNode[] = []) => {
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
    node: RefractorNode,
    className?: string
  ) => {
    let element = document.createElement(name);

    if (isAstElement(node)) {
      let properties = node.properties;
      let classNames = [];

      if (properties) {
        if (properties.className) {
          classNames.push(...properties.className);
        }

        for (let key in properties) {
          if (attributes.includes(key)) {
            let value = properties[key];

            if (key === 'style') {
              Object.keys(value).forEach((k: string) => {
                //@ts-ignore
                element.style[k] = `${value[k]}`;
              });
            } else {
              element.setAttribute(key, value as string);
            }
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
    }

    return element;
  };

  const toElement = (node: RefractorNode) => {
    if (isAstElement(node)) {
      let { type } = node;

      if (type === 'element') {
        let element = createElement(node.tagName, node);

        return toElements(element, node.children);
      } else if (type === 'text') {
        //@ts-ignore
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
    }

    return;
  };

  const element = toElements(document.createElement('div'), nodes);

  return {
    element: element,
    components
  };
};

export const isAstElement = (node: RefractorNode): node is AST.Element =>
  node.hasOwnProperty('type') &&
  (node.type === 'element' || node.type === 'text');

/**
 * Line utils specific to EuiCodeBlock
 */

type ExtendedRefractorNode = RefractorNode & {
  lineStart?: number;
  lineEnd?: number;
};

interface LineNumbersConfig {
  start: number;
  show: boolean;
  highlight?: string;
}

// Approximate width of a single digit/character
const CHAR_SIZE = 8;
const $euiSizeS = 8;

// Creates an array of numbers from comma-separeated
// string of numbers or number ranges using `-`
// (e.g., "1, 3-10, 15")
export const parseLineRanges = (ranges: string) => {
  const highlights: number[] = [];

  ranges
    .replace(/\s/g, '')
    .split(',')
    .forEach((line: string) => {
      if (line.includes('-')) {
        const range = line.split('-').map(Number);

        for (let i = range[0]!; i <= range[1]!; i++) {
          highlights.push(i);
        }
      } else {
        highlights.push(Number(line));
      }
    });

  return highlights;
};

const addLineData = (
  nodes: ExtendedRefractorNode[],
  data: { lineNumber: number }
): ExtendedRefractorNode[] => {
  return nodes.reduce<ExtendedRefractorNode[]>((result, node) => {
    const lineStart = data.lineNumber;

    if (node.type === 'text') {
      if (!node.value.match(/\r\n?|\n/)) {
        node.lineStart = lineStart;
        node.lineEnd = lineStart;
        result.push(node);
      } else {
        const lines = node.value.split(/\r\n?|\n/);

        lines.forEach((line, i) => {
          const num = i === 0 ? data.lineNumber : ++data.lineNumber;

          result.push({
            type: 'text',
            value: i === lines.length - 1 ? line : `${line}\n`,
            lineStart: num,
            lineEnd: num
          });
        });
      }

      return result;
    }

    if (node.children && node.children.length) {
      const children = addLineData(node.children, data);
      const first = children[0];
      const last = children[children.length - 1];
      const start = first?.lineStart ?? lineStart;
      const end = last?.lineEnd ?? lineStart;

      if (start !== end) {
        children.forEach((node) => {
          result.push(node);
        });
      } else {
        node.lineStart = start;
        node.lineEnd = end;
        node.children = children;
        result.push(node);
      }

      return result;
    }

    result.push(node);

    return result;
  }, []);
};

function wrapLines(
  nodes: ExtendedRefractorNode[],
  options: { showLineNumbers: boolean; highlight?: string }
) {
  const highlights = options.highlight
    ? parseLineRanges(options.highlight)
    : [];
  const grouped: ExtendedRefractorNode[][] = [];

  nodes.forEach((node) => {
    const lineStart = node.lineStart! - 1;

    if (grouped[lineStart]) {
      grouped[lineStart]?.push(node);
    } else {
      grouped[lineStart] = [node];
    }
  });

  const wrapped: RefractorNode[] = [];
  const digits = grouped.length.toString().length;
  const width = digits * CHAR_SIZE;

  grouped.forEach((node, i) => {
    const lineNumber = i + 1;
    const classes = ['euiCodeBlock__line'];

    if (highlights.includes(lineNumber)) {
      classes.push('euiCodeBlock__line--isHighlighted');
    }

    const children: RefractorNode[] = options.showLineNumbers
      ? [
          {
            type: 'element',
            tagName: 'span',
            properties: {
              style: { width: `${width}px` },
              ['data-line-number']: lineNumber,
              ['aria-hidden']: true,
              className: ['euiCodeBlock__lineNumber']
            },
            children: []
          },
          {
            type: 'element',
            tagName: 'span',
            properties: {
              style: {
                marginLeft: `${width + $euiSizeS}px`,
                width: `calc(100% - ${width}px)`
              },
              className: ['euiCodeBlock__lineText']
            },
            children: node
          }
        ]
      : node;

    wrapped.push({
      type: 'element',
      tagName: 'span',
      properties: {
        className: [classes.join(' ')]
      },
      children
    });
  });

  return wrapped;
}

export const highlightByLine = (
  children: string,
  language: string,
  data: LineNumbersConfig
) => {
  return wrapLines(
    addLineData(highlight(children, language), { lineNumber: data.start }),
    { showLineNumbers: data.show, highlight: data.highlight }
  );
};
