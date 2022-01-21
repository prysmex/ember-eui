//@ts-nocheck
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiPopoverArgs } from '../eui-popover';
import type MarkdownActions from '../../utils/markdown/markdown-actions';
import { MODE_VIEWING } from '../../utils/markdown/markdown-modes';

export interface EuiMarkdownEditorToolbarArgs
  extends Omit<EuiPopoverArgs, 'button' | 'buttonRef'> {
  disableFocusTrap?: boolean;
  fullWidth?: boolean;
  input: EuiPopoverArgs['button'];
  inputRef?: EuiPopoverArgs['buttonRef'];
  viewMode?: string;
  markdownActions: MarkdownActions;
}

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownEditorToolbarArgs> {
  boldItalicButtons = [
    {
      id: 'mdBold',
      label: 'Bold',
      name: 'bold',
      iconType: 'editorBold'
    },
    {
      id: 'mdItalic',
      label: 'Italic',
      name: 'italic',
      iconType: 'editorItalic'
    }
  ];

  listButtons = [
    {
      id: 'mdUl',
      label: 'Unordered list',
      name: 'ul',
      iconType: 'editorUnorderedList'
    },
    {
      id: 'mdOl',
      label: 'Ordered list',
      name: 'ol',
      iconType: 'editorOrderedList'
    },
    {
      id: 'mdTl',
      label: 'Task list',
      name: 'tl',
      iconType: 'stop'
    }
  ];

  quoteCodeLinkButtons = [
    {
      id: 'mdQuote',
      label: 'Quote',
      name: 'quote',
      iconType: 'quote'
    },
    {
      id: 'mdCode',
      label: 'Code',
      name: 'code',
      iconType: 'editorCodeBlock'
    },
    {
      id: 'mdLink',
      label: 'Link',
      name: 'link',
      iconType: 'editorLink'
    }
  ];

  get uiPlugins() {
    return this.args.uiPlugins || [];
  }

  get isPreviewing() {
    this.args.viewMode === MODE_VIEWING;
  }

  @action
  handleMdButtonClick(mdButtonId: string) {
    const actionResult = this.args.markdownActions.do(mdButtonId);
    if (actionResult !== true) this.args.openPluginEditor?.(actionResult);
  }
}
