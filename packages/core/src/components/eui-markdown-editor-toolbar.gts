import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import style from 'ember-style-modifier/modifiers/style';
import { and, eq, gte, or } from 'ember-truth-helpers';

import { MODE_VIEWING } from '../utils/markdown/markdown-modes';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import MarkdownCheckmark from './eui-markdown-editor-toolbar/icons/markdown-checkmark.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type MarkdownActions from '../utils/markdown/markdown-actions';

export interface EuiMarkdownEditorToolbarArgs {
  viewMode?: string;
  markdownActions: MarkdownActions;
  uiPlugins: any[];
  openPluginEditor?: (actionResult: ReturnType<MarkdownActions['do']>) => void;
  onClickPreview: () => void;
  selectedNode: any;
}

export interface EuiMarkdownEditorToolbarSignature {
  Element: HTMLDivElement;
  Args: EuiMarkdownEditorToolbarArgs;
  Blocks: {
    default: [];
  };
}

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownEditorToolbarSignature> {
  boldItalicsButtons = [
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
        iconType: {
          component: MarkdownCheckmark
        }
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

  iconType = (item: {
    iconType:
      | {
          component: any;
        }
      | string;
  }) => {
    if (typeof item.iconType === 'string') {
      return item.iconType;
    }

    return item.iconType.component;
  };

  <template>
    <div class="euiMarkdownEditorToolbar" ...attributes>
      <div class="euiMarkdownEditorToolbar__buttons">
        {{#each this.boldItalicsButtons as |item|}}
          <EuiToolTip @content={{item.label}} @delay="long">
            <EuiButtonIcon
              @color="text"
              {{on "click" (fn this.handleMdButtonClick item.id)}}
              @iconType={{item.iconType}}
              aria-label={{item.label}}
              @isDisabled={{this.isPreviewing}}
            />
          </EuiToolTip>

        {{/each}}
        <span class="euiMarkdownEditorToolbar__divider"></span>
        {{#each this.listButtons as |item|}}
          <EuiToolTip @content={{item.label}} @delay="long">
            <EuiButtonIcon
              @color="text"
              {{on "click" (fn this.handleMdButtonClick item.id)}}
              @iconType={{this.iconType item}}
              {{!@glint-expect-error}}
              @useComponent={{if item.iconType.component true}}
              aria-label={{item.label}}
              @useSvg={{item.useSvg}}
              @isDisabled={{this.isPreviewing}}
            />
          </EuiToolTip>

        {{/each}}
        <span class="euiMarkdownEditorToolbar__divider"></span>
        {{#each this.quoteCodeLinkButtons as |item|}}
          <EuiToolTip @content={{item.label}} @delay="long">
            <EuiButtonIcon
              @color="text"
              {{on "click" (fn this.handleMdButtonClick item.id)}}
              @iconType={{item.iconType}}
              aria-label={{item.label}}
              @isDisabled={{this.isPreviewing}}
            />
          </EuiToolTip>

        {{/each}}
        {{#if (gte this.uiPlugins.length 0)}}
          <span class="euiMarkdownEditorToolbar__divider"></span>
          {{#each this.uiPlugins as |plugin|}}
            {{#let
              (and @selectedNode (eq @selectedNode.type plugin.name))
              as |isSelectedNodeType|
            }}
              <EuiToolTip @content={{plugin.button.label}} @delay="long">
                <EuiButtonIcon
                  @color="text"
                  {{style
                    (if
                      isSelectedNodeType (hash background="rgba(0, 0, 0, 0.15)")
                    )
                  }}
                  {{on "click" (fn this.handleMdButtonClick plugin.name)}}
                  @iconType={{plugin.button.iconType}}
                  aria-label={{plugin.button.label}}
                  @isDisabled={{this.isPreviewing}}
                />
              </EuiToolTip>
            {{/let}}
          {{/each}}
        {{/if}}
      </div>

      {{#if this.isPreviewing}}
        <EuiButtonEmpty
          @iconType="editorCodeBlock"
          @color="text"
          @size="s"
          {{on "click" @onClickPreview}}
        >
          Editor
        </EuiButtonEmpty>

      {{else}}
        <EuiButtonEmpty
          @iconType="eye"
          @color="text"
          @size="s"
          {{on "click" @onClickPreview}}
        >
          Preview
        </EuiButtonEmpty>
      {{/if}}
    </div>
  </template>
}
