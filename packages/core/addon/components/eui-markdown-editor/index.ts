//@ts-nocheck
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { cached, tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { EuiPopoverArgs } from '../eui-popover';
import MarkdownActions from '../../utils/markdown/markdown-actions';
import {
  MODE_EDITING,
  MODE_VIEWING
} from '../../utils/markdown/markdown-modes';
import {
  defaultParsingPlugins,
  defaultProcessingPlugins
} from '../../utils/markdown/plugins/markdown-default-plugins';
import { uniqueId } from '../../helpers/unique-id';
import unified from 'unified';
import MarkdownTooltipPlugin from '../../utils/markdown/plugins/markdown-tooltip';

export interface EuiMarkdownEditorArgs
  extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  disableFocusTrap?: boolean;
  fullWidth?: boolean;
  input: EuiPopoverArgs['button'];
  inputRef?: EuiPopoverArgs['buttonRef'];
  onPanelResize?: (width?: number) => void;
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

export default class EuiMarkdownEditorComponent extends Component<EuiMarkdownEditorArgs> {
  // Defaults
  @argOrDefault(defaultParsingPlugins)
  parsingPluginList;

  @argOrDefault(defaultProcessingPlugins) processingPluginList;

  @tracked selectedNode;
  @tracked editorId = this.args.editorId ?? uniqueId();
  @tracked viewMode = this.args.initialViewMode || MODE_EDITING;

  markdownActions: MarkdownActions = null;

  get toolbarPlugins() {
    return [MarkdownTooltipPlugin.plugin, ...(this.args.uiPlugins || [])];
  }

  constructor(owner: unknown, args: EuiMarkdownEditorArgs) {
    super(owner, args);
    this.markdownActions = new MarkdownActions(
      this.editorId,
      this.toolbarPlugins
    );
  }

  @action
  replaceNode(position, next) {
    let value = this.args.value;
    const leading = value.substr(0, position.start.offset);
    const trailing = value.substr(position.end.offset);
    this.args.onChange?.(`${leading}${next}${trailing}`);
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
      const parsed = this.parsed;
      const onParse = this.args.onParse;
      const messages = parsed ? parsed.messages : [];
      const ast = parsed ? parsed.result ?? parsed.contents : null;
      onParse(parseError, { messages, ast });
    }
  }

  @action
  setSelectedNode(node) {
    this.selectedNode = node;
  }
}
