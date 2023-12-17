import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { scheduleOnce } from '@ember/runloop';

import pick from 'ember-composable-helpers/helpers/pick';
import { modifier } from 'ember-modifier';
import set from 'ember-set-helper/helpers/set';
import style from 'ember-style-modifier/modifiers/style';
import { eq, not } from 'ember-truth-helpers';
import unified from 'unified';

import { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import resizeObserver from '../modifiers/resize-observer';
import validatableControl from '../modifiers/validatable-control';
import MarkdownActions from '../utils/markdown/markdown-actions';
import { MODE_EDITING, MODE_VIEWING } from '../utils/markdown/markdown-modes';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../utils/markdown/plugins/markdown-default-plugins';
import * as MarkdownTooltipPlugin from '../utils/markdown/plugins/markdown-tooltip';
import EuiMarkdownEditorDropZone from './eui-markdown-editor-drop-zone.gts';
import EuiMarkdownEditorTextArea from './eui-markdown-editor-text-area.gts';
import EuiMarkdownEditorToolbar from './eui-markdown-editor-toolbar.gts';
import EuiMarkdownFormat from './eui-markdown-format.gts';

import type {
  EuiMarkdownAstNode,
  EuiMarkdownAstNodePosition,
  EuiMarkdownEditorUiPlugin
} from '../utils/markdown/markdown-types';
import type { EuiMarkdownEditorTextAreaSignature } from './eui-markdown-editor-text-area';
import type { EuiMarkdownEditorToolbarSignature } from './eui-markdown-editor-toolbar';
import type { Processor } from 'unified';

export interface EuiMarkdownEditorArgs {
  initialViewMode?: string;
  editorId?: string;
  uiPlugins: EuiMarkdownEditorUiPlugin[];
  parsingPluginList?: typeof defaultParsingPlugins;
  processingPluginList?: typeof defaultProcessingPlugins;
  value: string;
  onChange: (str: string) => void;
  onParse?: (
    parseError: unknown | null,
    parsed: { messages: any[]; ast: any }
  ) => void;
  height?: number | string;
  maxHeight?: number | string;
  autoExpandPreview?: boolean;
  disabled?: boolean;
  isInvalid?: boolean;
  ariaLabel?: string;
  ariaLabelledBy?: string;
  ariaDescribedBy?: string;
}

export interface EuiMarkdownEditorSignature {
  Element: EuiMarkdownEditorTextAreaSignature['Element'];
  Args: EuiMarkdownEditorArgs;
  Blocks: {
    default: [];
  };
}

export const getCursorNode = (
  textareaRef: HTMLInputElement,
  parsed: any
): EuiMarkdownAstNode => {
  const { selectionStart } = textareaRef;

  let node: EuiMarkdownAstNode = parsed.result ?? parsed.contents;

  //eslint-disable-next-line
  outer: while (true) {
    if (node.children) {
      for (let i = 0; i < node.children.length; i++) {
        const child = node.children[i];

        if (
          child &&
          child.position.start.offset < (selectionStart as number) &&
          (selectionStart as number) < child.position.end.offset
        ) {
          if (child.type === 'text') break outer; // don't dive into `text` nodes
          node = child;
          continue outer;
        }
      }
    }

    break;
  }

  return node;
};

function wrapper(
  textarea: HTMLInputElement,
  parsed: any,
  callback: (node: EuiMarkdownAstNode) => void
) {
  const node = getCursorNode(textarea, parsed);

  callback(node);
}

export const getCursorNodeModifier = modifier(function getCursorNodeModifier(
  textarea: EuiMarkdownEditorTextAreaSignature['Element'],
  [parsed, onSelectedNode]: [any, (node: Node) => void]
) {
  const fn = wrapper.bind(null, textarea, parsed, onSelectedNode);

  textarea.addEventListener('keyup', fn);
  textarea.addEventListener('mouseup', fn);

  return () => {
    textarea.removeEventListener('keyup', fn);
    textarea.removeEventListener('mouseup', fn);
  };
});

export default class EuiMarkdownEditorComponent extends Component<EuiMarkdownEditorSignature> {
  // Defaults
  @argOrDefaultDecorator(defaultParsingPlugins) declare parsingPluginList: typeof defaultParsingPlugins;

  @argOrDefaultDecorator(250) declare height: number | string;
  @argOrDefaultDecorator(500) declare maxHeight: number | string;
  @argOrDefaultDecorator(true) declare autoExpandPreview: boolean;

  @argOrDefaultDecorator(defaultProcessingPlugins) declare processingPluginList: typeof defaultProcessingPlugins;

  @tracked selectedNode: Node | null = null;
  @tracked editorId = this.args.editorId ?? guidFor({});
  @tracked viewMode = this.args.initialViewMode || MODE_EDITING;
  @tracked textareaRef: HTMLTextAreaElement | null = null;
  @tracked previewRef: HTMLDivElement | null = null;
  @tracked editorToolbarRef: HTMLDivElement | null = null;
  @tracked currentHeight: number | string = 250;
  @tracked editorFooterHeight: number = 0;
  @tracked editorToolbarHeight: number = 0;

  markdownActions: MarkdownActions;

  get toolbarPlugins() {
    return [MarkdownTooltipPlugin.plugin, ...(this.args.uiPlugins || [])];
  }

  constructor(owner: unknown, args: EuiMarkdownEditorArgs) {
    super(owner, args);
    this.markdownActions = new MarkdownActions(
      this.editorId,
      // @ts-expect-error
      this.toolbarPlugins
    );
    this.currentHeight = this.height;
  }

  get previewHeight() {
    if (this.height === 'full') {
      return `calc(100% - ${this.editorFooterHeight}px)`;
    }

    return `${this.currentHeight}px`;
  }

  get textAreaHeight() {
    return this.height === 'full'
      ? '100%'
      : `calc(${(this.height as number) - this.editorFooterHeight}px)`;
  }

  get textAreaMaxHeight() {
    return this.height !== 'full'
      ? `${(this.maxHeight as number) - this.editorFooterHeight}px`
      : '';
  }

  get editorToggleContainerHeight() {
    return `calc(100% - ${this.editorToolbarHeight}px)`;
  }

  @action
  onResize() {
    if (this.textareaRef && this.isEditing && this.height !== 'full') {
      const resizedTextareaHeight =
        this.textareaRef.offsetHeight + this.editorFooterHeight;

      const update = () => {
        this.currentHeight = resizedTextareaHeight;
      };

      scheduleOnce('afterRender', this, update);
    }
  }

  @action
  updateCurrentHeight() {
    let { isPreviewing, autoExpandPreview, height, previewRef, currentHeight } =
      this;

    if (isPreviewing && autoExpandPreview && height !== 'full' && previewRef) {
      //@ts-ignore
      if (previewRef.scrollHeight > currentHeight) {
        // scrollHeight does not include the border or margin
        // so we ask for the computed value for those,
        // which is always in pixels because getComputedValue
        // returns the resolved values
        const elementComputedStyle = window.getComputedStyle(previewRef);
        const borderWidth =
          parseFloat(elementComputedStyle.borderTopWidth) +
          parseFloat(elementComputedStyle.borderBottomWidth);
        const marginWidth =
          parseFloat(elementComputedStyle.marginTop) +
          parseFloat(elementComputedStyle.marginBottom);

        // then add an extra pixel for safety and because the scrollHeight value is rounded
        const extraHeight = borderWidth + marginWidth + 1;

        const update = () => {
          if (previewRef) {
            this.currentHeight = previewRef.scrollHeight + extraHeight;
          }
        };

        scheduleOnce('afterRender', this, update);
      }
    }
  }

  @action
  setTextAreaRef(ref: HTMLTextAreaElement) {
    this.textareaRef = ref;
  }

  @action
  setEditorToolbarRef(ref: EuiMarkdownEditorToolbarSignature['Element']) {
    this.editorToolbarRef = ref;
    this.editorToolbarHeight = ref.offsetHeight;
  }

  @action
  replaceNode(position: EuiMarkdownAstNodePosition, next: string) {
    let value = this.args.value;
    const leading = value.substr(0, position.start.offset);
    const trailing = value.substr(position.end.offset);

    this.args.onChange?.(`${leading}${next}${trailing}`);
  }

  get isEditing() {
    return this.viewMode === MODE_EDITING;
  }

  get isPreviewing() {
    return this.viewMode === MODE_VIEWING;
  }

  @action
  setViewMode() {
    this.viewMode = this.isPreviewing ? MODE_EDITING : MODE_VIEWING;
  }

  @cached
  get parser() {
    const Compiler = (tree: any) => {
      return tree;
    };

    function identityCompiler(this: Processor) {
      //eslint-disable-next-line
      this.Compiler = Compiler;
    }

    return unified().use(this.parsingPluginList).use(identityCompiler);
  }

  @cached
  get parsed(): [
    ReturnType<typeof this.parser.processSync> | null,
    null | unknown
  ] {
    try {
      const parsed = this.parser.processSync(this.args.value);

      return [parsed, null];
    } catch (e) {
      return [null, e];
    }
  }

  get vFile() {
    return this.parsed[0];
  }

  @action
  onParse() {
    if (this.args.onParse) {
      const [parsed, parseError] = this.parsed;
      const onParse = this.args.onParse;
      const messages = parsed ? parsed.messages : [];
      const ast = parsed ? parsed['result'] ?? parsed.contents : null;

      onParse(parseError, { messages, ast });
    }
  }

  @action
  setSelectedNode(node: Node) {
    this.selectedNode = node;
  }

  <template>
    <div
      class={{classNames
        "euiMarkdownEditor"
        (if (eq this.height "full") "euiMarkdownEditor--fullHeight")
        (if this.isPreviewing "euiMarkdownEditor--isPreviewing")
      }}
      {{didUpdate
        this.updateCurrentHeight
        this.currentHeight
        this.isPreviewing
        this.height
        this.autoExpandPreview
      }}
    >
      <EuiMarkdownEditorToolbar
        @selectedNode={{this.selectedNode}}
        @markdownActions={{this.markdownActions}}
        @onClickPreview={{this.setViewMode}}
        @viewMode={{this.viewMode}}
        @uiPlugins={{this.toolbarPlugins}}
        {{didInsert this.setEditorToolbarRef}}
      />
      {{#if this.isPreviewing}}
        <div
          class="euiMarkdownEditorPreview"
          {{didInsert (set this "previewRef")}}
          {{style (hash height=this.previewHeight)}}
        >
          <EuiMarkdownFormat
            @parsingPluginList={{this.parsingPluginList}}
            @processingPluginList={{this.processingPluginList}}
            @value={{@value}}
            @replaceNode={{this.replaceNode}}
          />
        </div>
      {{/if}}

      <div
        class="euiMarkdownEditor__toggleContainer"
        {{style height=this.editorToggleContainerHeight}}
      >
        <EuiMarkdownEditorDropZone
          @uiPlugins={{this.toolbarPlugins}}
          {{resizeObserver onResize=this.onResize}}
        >
          <EuiMarkdownEditorTextArea
            {{getCursorNodeModifier this.vFile this.setSelectedNode}}
            {{didUpdate this.onParse this.parsed}}
            {{didInsert this.setTextAreaRef}}
            disabled={{@disabled}}
            id={{this.editorId}}
            @height={{this.textAreaHeight}}
            @maxHeight={{this.textAreaMaxHeight}}
            value={{@value}}
            aria-label={{@ariaLabel}}
            aria-labelledby={{@ariaLabelledBy}}
            aria-describedby={{@ariaDescribedBy}}
            {{on "input" (pick "target.value" @onChange)}}
            {{validatableControl @isInvalid}}
            ...attributes
          />
        </EuiMarkdownEditorDropZone>
      </div>
    </div>
  </template>
}
