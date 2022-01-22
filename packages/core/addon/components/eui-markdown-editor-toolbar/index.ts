import Component from '@glimmer/component';
import { action } from '@ember/object';
import type MarkdownActions from '../../utils/markdown/markdown-actions';
import { MODE_VIEWING } from '../../utils/markdown/markdown-modes';
import { cached } from '@glimmer/tracking';
import { getOwner } from '@ember/application';
import { Plugin } from 'unified';

export interface EuiMarkdownEditorToolbarArgs {
  viewMode?: string;
  markdownActions: MarkdownActions;
  uiPlugins: Plugin[];
  openPluginEditor?: (actionResult: ReturnType<MarkdownActions['do']>) => void;
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

  get svgPath() {
    const config = getOwner(this).resolveRegistration('config:environment');
    const svgPath = config?.['@ember-eui/core']?.svgPath || 'svg';
    return svgPath;
  }

  @cached
  get listButtons() {
    return [
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
        useSvg: true,
        iconType: `${this.svgPath}/markdown-checkmark`
      }
    ];
  }

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
    return this.args.viewMode === MODE_VIEWING;
  }

  @action
  handleMdButtonClick(mdButtonId: string) {
    const actionResult = this.args.markdownActions.do(mdButtonId);
    if (actionResult !== true) this.args.openPluginEditor?.(actionResult);
  }
}
