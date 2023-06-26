import Component from '@glimmer/component';
import { action } from '@ember/object';
import { cached, tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import MarkdownActions from '../../utils/markdown/markdown-actions';
import {
  MODE_EDITING,
  MODE_VIEWING
} from '../../utils/markdown/markdown-modes';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { guidFor } from '@ember/object/internals';
import unified from 'unified';
import * as MarkdownTooltipPlugin from '../../utils/markdown/plugins/markdown-tooltip';
import {
  EuiMarkdownEditorUiPlugin,
  EuiMarkdownAstNodePosition,
  EuiMarkdownAstNode
} from '../../utils/markdown/markdown-types';
import { Processor } from 'unified';
import { scheduleOnce } from '@ember/runloop';
import { modifier } from 'ember-modifier';

export interface EuiMarkdownEditorArgs {
  initialViewMode?: string;
  editorId?: string;
  uiPlugins: EuiMarkdownEditorUiPlugin[];
  value: string;
  onChange: (str: string) => void;
  onParse: (
    parseError: string | null,
    parsed: { messages: string[]; ast: EuiMarkdownAstNode }
  ) => void;
}

// function isNewLine(char: string | undefined): boolean {
//   if (char == null) return true;
//   return !!char.match(/[\r\n]/);
// }
// function padWithNewlinesIfNeeded(textarea: HTMLTextAreaElement, text: string) {
//   const selectionStart = textarea.selectionStart;
//   const selectionEnd = textarea.selectionEnd;

//   // block parsing requires two leading new lines and none trailing, but we add an extra trailing line for readability
//   const isPrevNewLine = isNewLine(textarea.value[selectionStart - 1]);
//   const isPrevPrevNewLine = isNewLine(textarea.value[selectionStart - 2]);
//   const isNextNewLine = isNewLine(textarea.value[selectionEnd]);

//   // pad text with newlines as needed
//   text = `${isPrevNewLine ? '' : '\n'}${isPrevPrevNewLine ? '' : '\n'}${text}${
//     isNextNewLine ? '' : '\n'
//   }`;
//   return text;
// }

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
  textarea: HTMLInputElement,
  [parsed, onSelectedNode]: [boolean, () => void]
) {
  const fn = wrapper.bind(null, textarea, parsed, onSelectedNode);
  textarea.addEventListener('keyup', fn);
  textarea.addEventListener('mouseup', fn);

  return () => {
    textarea.removeEventListener('keyup', fn);
    textarea.removeEventListener('mouseup', fn);
  };
});

export default class EuiMarkdownEditorComponent extends Component<EuiMarkdownEditorArgs> {
  getCursorNodeModifier = getCursorNodeModifier;
  // Defaults
  @argOrDefault(defaultParsingPlugins)
  declare parsingPluginList: typeof defaultParsingPlugins;

  @argOrDefault(250) declare height: number | string;
  @argOrDefault(500) declare maxHeight: number | string;
  @argOrDefault(true) declare autoExpandPreview: boolean;

  @argOrDefault(defaultProcessingPlugins)
  declare processingPluginList: typeof defaultProcessingPlugins;

  @tracked selectedNode: Node | null = null;
  @tracked editorId = this.args.editorId ?? guidFor({});
  @tracked viewMode = this.args.initialViewMode || MODE_EDITING;
  @tracked textareaRef: HTMLTextAreaElement | null = null;
  @tracked previewRef: HTMLDivElement | null = null;
  @tracked editorToolbarRef: HTMLDivElement | null = null;
  @tracked currentHeight: number | string = 250;
  @tracked editorFooterHeight: number = 0;
  @tracked editorToolbarHeight: number = 0;

  markdownActions: MarkdownActions | null = null;

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
      // @ts-expect-error
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
  setEditorToolbarRef(ref: HTMLDivElement) {
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
  get parsed() {
    try {
      const parsed = this.parser.processSync(this.args.value);
      return [parsed, null];
    } catch (e) {
      return [null, e];
    }
  }

  @action
  onParse() {
    if (this.args.onParse) {
      const [parsed, parseError] = this.parsed;
      const onParse = this.args.onParse;
      const messages = parsed ? parsed.messages : [];
      const ast = parsed ? parsed.result ?? parsed.contents : null;
      onParse(parseError, { messages, ast });
    }
  }

  @action
  setSelectedNode(node: Node) {
    this.selectedNode = node;
  }
}
