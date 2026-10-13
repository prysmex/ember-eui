import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import style from 'ember-style-modifier/modifiers/style';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiMarkdownEditorToolbarStyles } from '../utils/eui/styles.generated.ts';
import { MODE_VIEWING } from '../utils/markdown/markdown-modes.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiI18n from './eui-i18n.gts';
import EuiToolTip from './eui-tool-tip.gts';
import EuiRenderNodeView from '../-private/eui-render-node.gts';

import type { EuiRenderNode } from '../-private/eui-render-node.gts';
import type MarkdownActions from '../utils/markdown/markdown-actions';
import type { EuiMarkdownEditorUiPlugin } from '../utils/markdown/markdown-types';

/** @private Args of EuiMarkdownEditor's toolbar. */
export interface EuiMarkdownEditorToolbarArgs {
  /** `'editing'` or `'viewing'`; formatting buttons are disabled while viewing. */
  viewMode?: string;
  /** Applies a formatting button to the textarea. */
  markdownActions: MarkdownActions;
  /** Plugins adding toolbar buttons (plugins without `button` are skipped). */
  uiPlugins: any[];
  /** Opens a plugin's editor (plugins with `editor`). */
  openPluginEditor?: (plugin: EuiMarkdownEditorUiPlugin) => void;
  /** Toggles the preview. */
  onClickPreview: () => void;
  /** The node under the cursor, to highlight its button. */
  selectedNode: any;
  /** Disables every button, including the preview switch. */
  readOnly?: boolean;
  /** Replaces the preview/editor switch: text or a component. */
  right?: EuiRenderNode;
}

/** @private EuiMarkdownEditor's toolbar. */
export interface EuiMarkdownEditorToolbarSignature {
  Element: HTMLDivElement;
  Args: EuiMarkdownEditorToolbarArgs;
  Blocks: {
    /** Unused. */
    default: [];
  };
}

export interface EuiMarkdownEditorToolbarItem {
  id: string;
  label: string;
  /** The markdown AST node type that highlights this button. */
  name: string;
  iconType:
    | string
    | {
        component: any;
      };
  useSvg?: boolean;
}

type EuiMarkdownEditorToolbarIconItem = EuiMarkdownEditorToolbarItem & {
  iconType: string;
};

/** Upstream highlights the button of the node under the cursor inline. */
const SELECTED_STYLE = { background: 'rgba(0, 0, 0, 0.15)' };

// Upstream's icon names.
const BOLD_ITALIC_BUTTONS: EuiMarkdownEditorToolbarIconItem[] = [
  { id: 'mdBold', label: 'Bold', name: 'strong', iconType: 'textBold' },
  {
    id: 'mdItalic',
    label: 'Italic',
    name: 'emphasis',
    iconType: 'textItalic'
  }
];

const LIST_BUTTONS: EuiMarkdownEditorToolbarItem[] = [
  {
    id: 'mdUl',
    label: 'Unordered list',
    name: 'ul',
    iconType: 'listBullet'
  },
  {
    id: 'mdOl',
    label: 'Ordered list',
    name: 'ol',
    iconType: 'listNumber'
  },
  {
    id: 'mdTl',
    label: 'Task list',
    name: 'tl',
    iconType: 'listCheck'
  }
];

const QUOTE_CODE_LINK_BUTTONS: EuiMarkdownEditorToolbarIconItem[] = [
  { id: 'mdQuote', label: 'Quote', name: 'quote', iconType: 'quote' },
  {
    id: 'mdCode',
    label: 'Code',
    name: 'inlineCode',
    iconType: 'code'
  },
  { id: 'mdLink', label: 'Link', name: 'link', iconType: 'link' }
];

export default class EuiMarkdownEditorToolbarComponent extends Component<EuiMarkdownEditorToolbarSignature> {
  boldItalicsButtons = BOLD_ITALIC_BUTTONS;
  listButtons = LIST_BUTTONS;
  quoteCodeLinkButtons = QUOTE_CODE_LINK_BUTTONS;

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiMarkdownEditorToolbarStyles
    );

    return {
      root: euiClass(context, styles.euiMarkdownEditorToolbar),
      buttons: euiClass(context, styles.euiMarkdownEditorToolbar__buttons),
      divider: euiClass(context, styles.euiMarkdownEditorToolbar__divider)
    };
  }

  @cached
  get uiPlugins() {
    return (this.args.uiPlugins || []).filter((plugin) => !!plugin.button);
  }

  get isPreviewing() {
    return this.args.viewMode === MODE_VIEWING;
  }

  /** Upstream `!isEditable`: previewing or read-only. */
  get isLocked() {
    return this.isPreviewing || !!this.args.readOnly;
  }

  isComponentIcon = (item: EuiMarkdownEditorToolbarItem) => {
    return typeof item.iconType !== 'string';
  };

  isSelected = (nodeId: string) => {
    return !!this.args.selectedNode && this.args.selectedNode.type === nodeId;
  };

  testSubj = (nodeId: string) => {
    return this.isSelected(nodeId)
      ? 'euiMarkdownEditorToolbarButton pressed'
      : 'euiMarkdownEditorToolbarButton';
  };

  selectedStyle = (nodeId: string) => {
    return this.isSelected(nodeId) ? SELECTED_STYLE : undefined;
  };

  @action
  handleMdButtonClick(mdButtonId: string) {
    const actionResult = this.args.markdownActions.do(mdButtonId);

    if (actionResult !== true) this.args.openPluginEditor?.(actionResult!);
  }

  itemComponent(item: EuiMarkdownEditorToolbarItem) {
    if (typeof item.iconType === 'string') return item.iconType;

    return item.iconType.component;
  }

  <template>
    <div
      class="euiMarkdownEditorToolbar {{this.styles.root}}"
      data-test-subj="euiMarkdownEditorToolbar"
      ...attributes
    >
      <div class="euiMarkdownEditorToolbar__buttons {{this.styles.buttons}}">
        {{#each this.boldItalicsButtons as |item|}}
          <EuiToolTip @content={{item.label}}>
            <EuiButtonIcon
              @color="text"
              @iconType={{item.iconType}}
              @isDisabled={{this.isLocked}}
              aria-label={{item.label}}
              data-test-subj={{this.testSubj item.name}}
              {{style (this.selectedStyle item.name)}}
              {{on "click" (fn this.handleMdButtonClick item.id)}}
            />
          </EuiToolTip>
        {{/each}}
        <span
          class="euiMarkdownEditorToolbar__divider {{this.styles.divider}}"
        ></span>
        {{#each this.listButtons as |item|}}
          <EuiToolTip @content={{item.label}}>
            <EuiButtonIcon
              @color="text"
              @iconType={{this.itemComponent item}}
              @useComponent={{this.isComponentIcon item}}
              @useSvg={{item.useSvg}}
              @isDisabled={{this.isLocked}}
              aria-label={{item.label}}
              data-test-subj={{this.testSubj item.name}}
              {{style (this.selectedStyle item.name)}}
              {{on "click" (fn this.handleMdButtonClick item.id)}}
            />
          </EuiToolTip>
        {{/each}}
        <span
          class="euiMarkdownEditorToolbar__divider {{this.styles.divider}}"
        ></span>
        {{#each this.quoteCodeLinkButtons as |item|}}
          <EuiToolTip @content={{item.label}}>
            <EuiButtonIcon
              @color="text"
              @iconType={{item.iconType}}
              @isDisabled={{this.isLocked}}
              aria-label={{item.label}}
              data-test-subj={{this.testSubj item.name}}
              {{style (this.selectedStyle item.name)}}
              {{on "click" (fn this.handleMdButtonClick item.id)}}
            />
          </EuiToolTip>
        {{/each}}
        {{#if this.uiPlugins.length}}
          <span
            class="euiMarkdownEditorToolbar__divider {{this.styles.divider}}"
          ></span>
          {{#each this.uiPlugins as |plugin|}}
            <EuiToolTip @content={{plugin.button.label}}>
              <EuiButtonIcon
                @color="text"
                @iconType={{plugin.button.iconType}}
                @isDisabled={{or this.isLocked plugin.button.isDisabled}}
                aria-label={{plugin.button.label}}
                data-test-subj={{this.testSubj plugin.name}}
                {{style (this.selectedStyle plugin.name)}}
                {{on "click" (fn this.handleMdButtonClick plugin.name)}}
              />
            </EuiToolTip>
          {{/each}}
        {{/if}}
      </div>

      {{#if @right}}
        <EuiRenderNodeView @value={{@right}} />
      {{else if this.isPreviewing}}
        <EuiButtonEmpty
          @iconType="code"
          @color="text"
          @size="s"
          @isDisabled={{@readOnly}}
          data-test-subj="markdown_editor_preview_button"
          {{on "click" @onClickPreview}}
        >
          <EuiI18n
            @token="euiMarkdownEditorToolbar.editor"
            @default="Editor"
            as |Token|
          >
            <Token as |value|>
              {{value}}
            </Token>
          </EuiI18n>
        </EuiButtonEmpty>
      {{else}}
        <EuiButtonEmpty
          @iconType="eye"
          @color="text"
          @size="s"
          @isDisabled={{@readOnly}}
          data-test-subj="markdown_editor_edit_button"
          {{on "click" @onClickPreview}}
        >
          <EuiI18n
            @token="euiMarkdownEditorToolbar.preview"
            @default="Preview"
            as |Token|
          >
            <Token as |value|>
              {{value}}
            </Token>
          </EuiI18n>
        </EuiButtonEmpty>
      {{/if}}
    </div>
  </template>
}
