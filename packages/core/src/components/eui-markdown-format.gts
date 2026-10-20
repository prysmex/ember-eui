import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { isArray } from '@ember/array';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import style from 'ember-style-modifier/modifiers/style';

import { markdownEngine } from '../-private/markdown-engine-loader.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiMarkdownFormatStyles,
  euiTextStyles
} from '../utils/eui/styles.generated.ts';
import { euiTextAlignCss } from './eui-text-align.gts';
import {
  TEXT_COLORS,
  euiTextColorCss,
  euiTextColorInlineStyle
} from './eui-text-color.gts';
import { euiTextReset } from './eui-text.gts';

import type {
  EuiMarkdownAstNodePosition,
  RehypeNode
} from '../utils/markdown/markdown-types';
import type {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../utils/markdown/plugins/markdown-default-plugins/index.ts';
import type { EuiTextAlignment } from './eui-text-align.gts';
import type { EuiTextColorValue } from './eui-text-color.gts';
import type { EuiTextSignature } from './eui-text.gts';
import type { CSSObject } from '@emotion/css/create-instance';
import type { Processor } from 'unified';

export type Replacer = (
  position: EuiMarkdownAstNodePosition,
  str: string
) => void;

/** React's global table reset, which EuiText's scoped reset leaves out. */
const TABLE_RESET: CSSObject = {
  '& :where(table)': { borderCollapse: 'collapse', borderSpacing: 0 }
};

/**
 * Ember-only structure: plugin components render inside `<span|div
 * class="component">` wrappers, so upstream's task list rule
 * (`.euiCheckbox:has(+ :not(.euiCheckbox))`, see `utils/eui/markdown.ts`)
 * moves to the checkbox wrappers, which become blocks like upstream's
 * `EuiCheckbox` root.
 */
const markdownFormatEmberCss: CSSObject = {
  '& .euiMarkdownFormat__checkbox': { display: 'block' },
  '& .euiMarkdownFormat__checkbox:has(+ :not(.euiMarkdownFormat__checkbox))':
    { marginBlockEnd: '1em' }
};

type MarkdownFormatColor = keyof ReturnType<
  typeof euiMarkdownFormatStyles
>['colors'];

/**
 * Renders markdown as EUI-styled content (headings, lists, code blocks,
 * tables, checkboxes, tooltips and emoji):
 * `<EuiMarkdownFormat @value={{this.markdown}} />`. Attributes go to the
 * root `<div class="euiMarkdownFormat">`. The markdown parser and
 * highlighter load with the first one rendered, which renders its content
 * once they have (`settled()` waits for them).
 */
export interface EuiMarkdownFormatSignature {
  Element: HTMLDivElement;
  Args: {
    /** remark parsing plugins. Defaults to `getDefaultEuiMarkdownParsingPlugins()`. */
    parsingPluginList?: typeof defaultParsingPlugins;
    /** Processing plugins. Defaults to `getDefaultEuiMarkdownProcessingPlugins()`. */
    processingPluginList?: typeof defaultProcessingPlugins;
    /**
     * Called when rendered content edits the markdown, e.g. clicking a
     * task list checkbox (`- [ ] todo`), with the node's position in the
     * source and its new text. Splice it into your value to make checkboxes
     * interactive; EuiMarkdownEditor does this for you.
     */
    replaceNode?: Replacer;
    /** Renders interactive plugin content (task list checkboxes) read-only. */
    readOnly?: boolean;
    /** The markdown to render. */
    value: string;
    /** Extra class(es) for the root element: a string or an array of strings. */
    rootClasses?: string | string[];
    /**
     * Text size, any `EuiText` size; `'relative'` scales with the parent's
     * font size. Defaults to `'m'`.
     */
    textSize?: EuiTextSignature['Args']['size'];
    /**
     * Any EuiText color: a named color (`'subdued'`, `'danger'`…) or a CSS
     * color. Also tints blockquote, rule and table borders. Defaults to
     * `'default'`.
     */
    color?: EuiTextColorValue;
    /**
     * Applies EuiText typography (and the `euiText` class) to the content.
     * Defaults to `true`; `false` keeps only the markdown-specific styles.
     */
    shouldIncludeDefaultRootClasses?: boolean;
    /**
     * The root element: `'div'` (default), `'span'` or `'p'` (upstream
     * EuiText's `component`). Only `'div'` can hold block content such as
     * headings, lists and tables.
     */
    component?: 'div' | 'span' | 'p';
    /**
     * `true` (default) lets the text span the container's full width;
     * `false` caps lines at a readable width (EuiText's `grow`).
     */
    grow?: boolean;
    /** `'left'`, `'center'` or `'right'` (logical, so they flip in RTL). */
    textAlign?: EuiTextAlignment;
  };
}

/**
 * The root tag. Typed as `'div'` so callers keep `HTMLDivElement`
 * attributes; `@component` may be `'span'` or `'p'` too.
 */
function tagName(component: string | undefined): 'div' {
  return (component || 'div') as 'div';
}

export default class EuiMarkdownFormat extends Component<EuiMarkdownFormatSignature> {
  /** unified, the default plugins and toDOM, once loaded. */
  get engine() {
    return markdownEngine();
  }

  get parsingPluginList() {
    return this.args.parsingPluginList || this.engine?.defaultParsingPlugins;
  }

  get processingPluginList() {
    return (
      this.args.processingPluginList || this.engine?.defaultProcessingPlugins
    );
  }

  @cached
  get processor() {
    const engine = this.engine;

    if (!engine) return undefined;

    const Compiler = (tree: any) => {
      return tree;
    };

    function identityCompiler(this: Processor) {
      //eslint-disable-next-line
      this.Compiler = Compiler;
    }

    return engine
      .unified()
      .use(this.args.parsingPluginList || engine.defaultParsingPlugins)
      .use(this.args.processingPluginList || engine.defaultProcessingPlugins)
      .use(identityCompiler);
  }

  get shouldIncludeDefaultRootClasses() {
    return this.args.shouldIncludeDefaultRootClasses ?? true;
  }

  get textSize() {
    return this.args.textSize || 'm';
  }

  get color(): EuiTextColorValue {
    return this.args.color ?? 'default';
  }

  @cached
  get extraRootClasses(): string[] {
    const { rootClasses } = this.args;

    if (!rootClasses) return [];

    return isArray(rootClasses)
      ? (rootClasses as string[])
      : (rootClasses as string).trim().split(/\s+/);
  }

  /** A custom text color, inline (only with the default EuiText classes). */
  get inlineStyle(): Record<string, string> {
    return this.shouldIncludeDefaultRootClasses
      ? euiTextColorInlineStyle(this.color)
      : {};
  }

  /** Upstream: EuiText (size, color) with the markdown css composed last. */
  @cached
  get styleClass() {
    const context = getEuiThemeContext(this);
    const markdown = useEuiBorealisStyles(context, euiMarkdownFormatStyles);
    const size = this.textSize;
    const color = this.color;
    const { grow, textAlign } = this.args;
    // Upstream EuiText: `constrainedWidth` unless it grows, and the
    // alignment last (EuiTextAlign clones the element).
    const align = textAlign ? euiTextAlignCss(textAlign) : undefined;
    const borderColor: MarkdownFormatColor = (
      TEXT_COLORS as readonly string[]
    ).includes(color)
      ? (color as MarkdownFormatColor)
      : 'custom';

    if (!this.shouldIncludeDefaultRootClasses) {
      return euiClass(
        context,
        markdown.euiMarkdownFormat,
        markdown[size],
        markdown.colors[borderColor],
        markdownFormatEmberCss,
        align
      );
    }

    const text = useEuiBorealisStyles(context, euiTextStyles);

    return euiClass(
      context,
      euiTextReset(context.upstream),
      TABLE_RESET,
      text.euiText,
      grow === false ? text.constrainedWidth : undefined,
      text[size],
      euiTextColorCss(context, color),
      markdown.euiMarkdownFormat,
      markdown[size],
      markdown.colors[borderColor],
      markdownFormatEmberCss,
      align
    );
  }

  @cached
  get rootClassName() {
    return [
      'euiMarkdownFormat',
      this.shouldIncludeDefaultRootClasses ? 'euiText' : undefined,
      this.styleClass,
      ...this.extraRootClasses
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get result() {
    const { engine, processor } = this;

    if (!engine || !processor) return null;

    try {
      const processed = processor.processSync(this.args.value);
      const { element, components } = engine.toDOM(
        processed['result'] as RehypeNode
      );

      return {
        nodes: element ? Array.from(element.childNodes) : [],
        components
      };
    } catch (e) {
      console.warn(e);
    }

    return null;
  }

  <template>
    {{! This hbs was inspired by https://github.com/ampatspell/ember-cli-remark-static/blob/v3.0.5/addon/components/remark.hbs }}
    {{#let (element (tagName @component)) as |Tag|}}
      <Tag class={{this.rootClassName}} ...attributes {{style this.inlineStyle}}>
        {{#if this.result}}
          {{#each this.result.nodes as |node|}}{{node}}{{/each}}
        {{/if}}
      </Tag>
    {{/let}}
    {{#if this.result}}
      {{#each this.result.components as |CompNode|}}
        {{#in-element CompNode.element}}
          {{#if CompNode.componentName}}
            {{#let
              (component CompNode.componentName)
              as |DynamicComponent|
            }}
              <DynamicComponent
                @replaceNode={{optional @replaceNode}}
                @readOnly={{@readOnly}}
                @node={{CompNode}}
              />
            {{/let}}
          {{/if}}
        {{/in-element}}
      {{/each}}
    {{/if}}
  </template>
}
