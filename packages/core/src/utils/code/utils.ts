/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { highlight } from 'refractor/core';

import { isSupportedLanguage, SUPPORTED_LANGUAGES } from '../../-private/language-loader.ts';

import type { CommonArgs } from '../../components/common.ts';
import type { AST, RefractorNode } from 'refractor/core';

/**
 * Utils shared between EuiCode and EuiCodeBlock
 */

export type EuiCodeSharedProps = CommonArgs & {
  /**
   * Sets the syntax highlighting for a specific language, e.g. `'js'`,
   * `'ts'`, `'html'`, `'css'`, `'json'`, `'bash'` or `'hbs'`. Unsupported
   * languages fall back to `'text'` (no highlighting).
   * @see [https://prismjs.com/#supported-languages](https://prismjs.com/#supported-languages) for options
   */
  language?: string;
  /** Removes the background color. Defaults to `false`. */
  transparentBackground?: boolean;
};

export { SUPPORTED_LANGUAGES };
export const DEFAULT_LANGUAGE = 'text';

export const checkSupportedLanguage = (language: string): string => {
  return isSupportedLanguage(language) ? language : DEFAULT_LANGUAGE;
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
  'data-annotation-line',
  'aria-hidden',
  'style'
];

export interface DynamicComponent {}

export const getHtmlContent = (nodes: RefractorNode[]) => {
  const document = createDocument();
  const components: DynamicComponent[] = [];

  const toElements = (parent: HTMLElement, nodes: RefractorNode[] = []) => {
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
    node: RefractorNode,
    className?: string
  ) => {
    const element = document.createElement(name);

    if (isAstElement(node)) {
      const properties = node.properties;
      const classNames = [];

      if (properties) {
        if (properties.className) {
          classNames.push(...properties.className);
        }

        for (const key in properties) {
          if (attributes.includes(key)) {
            const value = properties[key];

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
      // widened on purpose: refractor nodes also carry custom 'component' types
      const type: string = node.type;

      if (type === 'element') {
        const element = createElement(node.tagName, node);

        return toElements(element, node.children);
      } else if (type === 'text') {
        //@ts-ignore
        return document.createTextNode(node.value);
      } else if (type === 'component') {
        const { inline } = node.properties;
        const element = createElement(inline ? 'span' : 'div', node, 'component');
        const { _children, ...properties } = node.properties;
        const content = toElements(document.createElement('span'), node.children);

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

export interface LineNumbersConfig {
  start: number;
  show: boolean;
  highlight?: string;
  annotations?: Record<number, unknown>;
}

/**
 * Class names given to the line nodes. Like upstream's `cx`, each variant is
 * one composed class (`lineWithNumbers` = line + hasLineNumbers,
 * `lineTextHighlighted` = lineText + isHighlighted).
 */
export interface LineClasses {
  line?: string;
  lineWithNumbers?: string;
  lineText?: string;
  lineTextHighlighted?: string;
  lineNumberWrapper?: string;
  lineNumber?: string;
}

// Approximate width of a single digit/character
const CHAR_SIZE = 8;

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

const cls = (...names: (string | undefined | false)[]) =>
  names.filter(Boolean).join(' ').split(' ').filter(Boolean);

/**
 * Upstream `wrapLines`: one `span.euiCodeBlock__line` per line; with line
 * numbers, a `span.euiCodeBlock__lineNumberWrapper` (sized to the widest
 * number, holding the `aria-hidden` number drawn from `data-line-number` and
 * an optional annotation placeholder) and a `span.euiCodeBlock__lineText`.
 */
function wrapLines(
  nodes: ExtendedRefractorNode[],
  options: {
    showLineNumbers: boolean;
    highlight?: string;
    annotations?: Record<number, unknown>;
  },
  classes: LineClasses = {}
) {
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
  const highlights = options.highlight
    ? parseLineRanges(options.highlight)
    : [];
  const digits = grouped.length.toString().length;
  const width = digits * CHAR_SIZE;

  grouped.forEach((node, i) => {
    let children: RefractorNode[] = node;

    if (options.showLineNumbers) {
      // `grouped` is indexed from `start` (earlier slots are holes)
      const lineNumber = i + 1;
      const lineNumberWrapper: AST.Element = {
        type: 'element',
        tagName: 'span',
        properties: {
          style: { inlineSize: `${width}px` },
          className: cls(
            'euiCodeBlock__lineNumberWrapper',
            classes.lineNumberWrapper
          )
        },
        children: [
          {
            type: 'element',
            tagName: 'span',
            properties: {
              className: cls('euiCodeBlock__lineNumber', classes.lineNumber),
              ['data-line-number']: lineNumber,
              ['aria-hidden']: true
            },
            children: []
          }
        ]
      };

      if (options.annotations?.hasOwnProperty(lineNumber)) {
        lineNumberWrapper.children.push({
          type: 'element',
          tagName: 'span',
          properties: {
            className: ['euiCodeBlock__lineAnnotation'],
            ['data-annotation-line']: lineNumber
          },
          children: []
        });
      }

      children = [
        lineNumberWrapper,
        {
          type: 'element',
          tagName: 'span',
          properties: {
            className: cls(
              'euiCodeBlock__lineText',
              highlights.includes(lineNumber)
                ? classes.lineTextHighlighted
                : classes.lineText
            )
          },
          children: node
        }
      ];
    }

    wrapped.push({
      type: 'element',
      tagName: 'span',
      properties: {
        className: cls(
          'euiCodeBlock__line',
          options.showLineNumbers ? classes.lineWithNumbers : classes.line
        )
      },
      children
    });
  });

  return wrapped;
}

export const highlightByLine = (
  children: string,
  language: string,
  data: LineNumbersConfig,
  classes?: LineClasses
) => {
  return wrapLines(
    addLineData(highlight(children, language), { lineNumber: data.start }),
    {
      showLineNumbers: data.show,
      highlight: data.highlight,
      annotations: data.annotations
    },
    classes
  );
};
