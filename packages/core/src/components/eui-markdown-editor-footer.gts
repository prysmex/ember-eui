import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiMarkdownEditorFooterStyles,
  euiMarkdownEditorHelpButtonStyles
} from '../utils/eui/styles.generated.ts';
import MarkdownLogo from './eui-markdown-editor-footer/icons/markdown-logo.gts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiHorizontalRule from './eui-horizontal-rule.gts';
import EuiI18n from './eui-i18n.gts';
import EuiLink from './eui-link.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiMarkdownFormat from './eui-markdown-format.gts';
import EuiModal from './eui-modal.gts';
import EuiModalBody from './eui-modal-body.gts';
import EuiModalFooter from './eui-modal-footer.gts';
import EuiModalHeader from './eui-modal-header.gts';
import EuiPopover from './eui-popover.gts';
import EuiPopoverTitle from './eui-popover-title.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type EuiI18nService from '../services/eui-i18n';
import type {
  EuiMarkdownDropHandler,
  EuiMarkdownParseError
} from '../utils/markdown/markdown-types';

/** Upstream's syntax guide link. */
export const MARKDOWN_SYNTAX_HREF =
  'https://guides.github.com/features/mastering-markdown/';

const errorText = (message: EuiMarkdownParseError) => String(message);

/** @private EuiMarkdownEditor's footer: upload status, errors and syntax help. */
export interface EuiMarkdownEditorFooterSignature {
  Element: HTMLDivElement;
  Args: {
    /** Shows the upload spinner. */
    isUploadingFiles?: boolean;
    /** Errors listed in a popover (upstream `EuiMarkdownParseError`s). */
    errors?: EuiMarkdownParseError[];
    /** The editor's plugins, whose help text the help modal lists. */
    uiPlugins?: any[];
    /** File drop handlers; any handler adds the upload button. */
    dropHandlers?: EuiMarkdownDropHandler[];
    /** A dropped file had no handler: the upload button turns into an error. */
    hasUnacceptedItems?: boolean;
    /** Opens the file picker. */
    openFiles?: () => void;
    /** Disables the footer buttons. */
    readOnly?: boolean;
  };
}

export default class EuiMarkdownEditorFooterComponent extends Component<EuiMarkdownEditorFooterSignature> {
  @service('eui-i18n') declare euiI18n: EuiI18nService;

  @tracked isPopoverOpen = false;
  @tracked isShowingHelpModal = false;
  @tracked isShowingHelpPopover = false;

  helpModalTitleId = `${guidFor(this)}-help-title`;

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const footer = useEuiBorealisStyles(context, euiMarkdownEditorFooterStyles);
    const help = useEuiBorealisStyles(
      context,
      euiMarkdownEditorHelpButtonStyles
    );

    return {
      root: euiClass(context, footer.euiMarkdownEditorFooter),
      actions: euiClass(context, footer.euiMarkdownEditorFooter__actions),
      popover: euiClass(context, footer.euiMarkdownEditorFooter__popover),
      // Composed into the migrated button's own class (upstream `css`)
      helpButton: help.euiMarkdownEditorFooter__helpButton
    };
  }

  get dropHandlers() {
    return this.args.dropHandlers ?? [];
  }

  get errors() {
    return this.args.errors ?? [];
  }

  @cached
  get uiPluginsWithHelpText() {
    return (this.args.uiPlugins ?? []).filter((plugin) => !!plugin.helpText);
  }

  @cached
  get supportedFileTypes() {
    return this.dropHandlers
      .map(({ supportedFiles }) => supportedFiles.join(', '))
      .sort()
      .join(', ');
  }

  @cached
  get labels() {
    const t = (token: string, fallback: string, values?: object) =>
      this.euiI18n.lookupToken(token, fallback, values);

    const uploadingFiles = t(
      'euiMarkdownEditorFooter.uploadingFiles',
      'Click to upload files'
    );
    const unsupportedFileType = t(
      'euiMarkdownEditorFooter.unsupportedFileType',
      'File type not supported'
    );
    const supportedFileTypes = t(
      'euiMarkdownEditorFooter.supportedFileTypes',
      'Supported files: {supportedFileTypes}',
      { supportedFileTypes: this.supportedFileTypes }
    );

    return {
      uploadingFiles,
      openUploadModal: t(
        'euiMarkdownEditorFooter.openUploadModal',
        'Open upload files modal'
      ),
      unsupportedFileType,
      supportedFileTypes,
      unsupportedAriaLabel: `${unsupportedFileType}. ${supportedFileTypes}. ${uploadingFiles}`,
      showSyntaxErrors: t(
        'euiMarkdownEditorFooter.showSyntaxErrors',
        'Show errors'
      ),
      syntaxTitle: t('euiMarkdownEditorHelpButton.syntaxTitle', 'Syntax help'),
      showMarkdownHelp: t(
        'euiMarkdownEditorHelpButton.showMarkdownHelp',
        'Show markdown help'
      )
    };
  }

  @action
  toggleErrors() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closeErrors() {
    this.isPopoverOpen = false;
  }

  @action
  setHelpModal(isShowing: boolean) {
    this.isShowingHelpModal = isShowing;
  }

  @action
  toggleHelpModal() {
    this.isShowingHelpModal = !this.isShowingHelpModal;
  }

  @action
  toggleHelpPopover() {
    this.isShowingHelpPopover = !this.isShowingHelpPopover;
  }

  @action
  closeHelpPopover() {
    this.isShowingHelpPopover = false;
  }

  @action
  openFiles() {
    this.args.openFiles?.();
  }

  <template>
    <div
      class="euiMarkdownEditorFooter {{this.styles.root}}"
      data-test-subj="euiMarkdownEditorFooter"
      ...attributes
    >
      <div class="euiMarkdownEditorFooter__actions {{this.styles.actions}}">
        {{#if @isUploadingFiles}}
          <EuiButtonIcon
            @size="s"
            @iconType={{component EuiLoadingSpinner}}
            @useComponent={{true}}
            @isDisabled={{@readOnly}}
            aria-label={{this.labels.uploadingFiles}}
          />
        {{else if (if this.dropHandlers.length @hasUnacceptedItems)}}
          <EuiToolTip @content={{this.labels.supportedFileTypes}}>
            {{! upstream autoFocus: the error is announced right after a drop }}
            <EuiButtonEmpty
              {{! upstream also composes footer.euiMarkdownEditorFooter__uploadError
                (panel border radius) via css; EuiButtonEmpty has no @css yet }}
              class="euiMarkdownEditorFooter__uploadError"
              @size="s"
              @iconType="paperClip"
              @color="danger"
              @isDisabled={{@readOnly}}
              aria-label={{this.labels.unsupportedAriaLabel}}
              autofocus
              {{on "click" this.openFiles}}
            >
              {{this.labels.unsupportedFileType}}
            </EuiButtonEmpty>
          </EuiToolTip>
        {{else if this.dropHandlers.length}}
          <EuiButtonIcon
            @size="s"
            @iconType="paperClip"
            @color="text"
            @isDisabled={{@readOnly}}
            aria-label={{this.labels.openUploadModal}}
            {{on "click" this.openFiles}}
          />
        {{/if}}
        {{#if this.errors.length}}
          <EuiPopover
            @isOpen={{this.isPopoverOpen}}
            @closePopover={{this.closeErrors}}
            @panelPaddingSize="s"
            @anchorPosition="upCenter"
          >
            <:button>
              <EuiButtonEmpty
                @iconType="error"
                @size="s"
                @color="danger"
                @isDisabled={{@readOnly}}
                aria-label={{this.labels.showSyntaxErrors}}
                {{on "click" this.toggleErrors}}
              >
                {{this.errors.length}}
              </EuiButtonEmpty>
            </:button>
            <:content>
              <div
                class="euiMarkdownEditorFooter__popover {{this.styles.popover}}"
              >
                <EuiPopoverTitle>
                  <EuiI18n
                    @token="euiMarkdownEditorFooter.errorsTitle"
                    @default="Errors"
                    as |Token|
                  >
                    <Token as |value|>{{value}}</Token>
                  </EuiI18n>
                </EuiPopoverTitle>
                {{#each this.errors as |message|}}
                  <EuiText @size="s">{{errorText message}}</EuiText>
                {{/each}}
              </div>
            </:content>
          </EuiPopover>
        {{/if}}
      </div>

      {{#if this.uiPluginsWithHelpText.length}}
        <EuiToolTip
          @content={{this.labels.syntaxTitle}}
          @disableScreenReaderOutput={{true}}
        >
          <EuiButtonIcon
            class="euiMarkdownEditorFooter__helpButton"
            @css={{this.styles.helpButton}}
            @size="s"
            @iconType={{component MarkdownLogo}}
            @useComponent={{true}}
            @useSvg={{true}}
            @color="text"
            @isDisabled={{@readOnly}}
            aria-label={{this.labels.showMarkdownHelp}}
            {{on "click" this.toggleHelpModal}}
          />
        </EuiToolTip>
        {{#if this.isShowingHelpModal}}
          <EuiModal
            @onClose={{fn this.setHelpModal false}}
            aria-labelledby={{this.helpModalTitleId}}
          >
            <EuiModalHeader>
              <EuiTitle>
                <h1 id={{this.helpModalTitleId}}>{{this.labels.syntaxTitle}}</h1>
              </EuiTitle>
            </EuiModalHeader>
            <EuiModalBody>
              <EuiText>
                <p>
                  <EuiI18n
                    @token="euiMarkdownEditorHelpButton.syntaxModalDescriptionPrefix"
                    @default="This editor uses"
                    as |Token|
                  ><Token as |value|>{{value}}</Token></EuiI18n>
                  {{! template-lint-disable no-whitespace-for-layout }}
                  <EuiLink @href={{MARKDOWN_SYNTAX_HREF}} @target="_blank">
                    <EuiI18n
                      @token="euiMarkdownEditorHelpButton.mdSyntaxLink"
                      @default="GitHub flavored markdown"
                      as |Token|
                    ><Token as |value|>{{value}}</Token></EuiI18n>
                  </EuiLink>.
                  <EuiI18n
                    @token="euiMarkdownEditorHelpButton.syntaxModalDescriptionSuffix"
                    @default="You can also utilize these additional syntax plugins to add rich content to your text."
                    as |Token|
                  ><Token as |value|>{{value}}</Token></EuiI18n>
                </p>
              </EuiText>
              <EuiHorizontalRule />
              {{#each this.uiPluginsWithHelpText as |uiPlugin|}}
                <EuiTitle @size="xxs">
                  <p>
                    <strong>{{uiPlugin.name}}</strong>
                  </p>
                </EuiTitle>
                <EuiSpacer @size="s" />
                <EuiMarkdownFormat @value={{uiPlugin.helpText}} />
                <EuiSpacer @size="l" />
              {{/each}}
              <EuiHorizontalRule />
            </EuiModalBody>
            <EuiModalFooter>
              <EuiButton
                @fill={{true}}
                {{on "click" (fn this.setHelpModal false)}}
              >
                <EuiI18n
                  @token="euiMarkdownEditorHelpButton.closeButton"
                  @default="Close"
                  as |Token|
                ><Token as |value|>{{value}}</Token></EuiI18n>
              </EuiButton>
            </EuiModalFooter>
          </EuiModal>
        {{/if}}
      {{else}}
        <EuiPopover
          @isOpen={{this.isShowingHelpPopover}}
          @closePopover={{this.closeHelpPopover}}
          @panelPaddingSize="s"
          @anchorPosition="upCenter"
          aria-labelledby={{this.helpModalTitleId}}
        >
          <:button>
            <EuiToolTip
              @content={{this.labels.syntaxTitle}}
              @disableScreenReaderOutput={{true}}
            >
              <EuiButtonIcon
                class="euiMarkdownEditorFooter__helpButton"
                @css={{this.styles.helpButton}}
                @size="s"
                @iconType={{component MarkdownLogo}}
                @useComponent={{true}}
                @useSvg={{true}}
                @color="text"
                aria-label={{this.labels.showMarkdownHelp}}
                {{on "click" this.toggleHelpPopover}}
              />
            </EuiToolTip>
          </:button>
          <:content>
            <p>
              <EuiI18n
                @token="euiMarkdownEditorHelpButton.syntaxPopoverDescription"
                @default="This editor uses"
                as |Token|
              ><Token as |value|>{{value}}</Token></EuiI18n>
              <EuiLink @href={{MARKDOWN_SYNTAX_HREF}} @target="_blank">
                <EuiI18n
                  @token="euiMarkdownEditorHelpButton.mdSyntaxLink"
                  @default="GitHub flavored markdown"
                  as |Token|
                ><Token as |value|>{{value}}</Token></EuiI18n>
              </EuiLink>.
            </p>
          </:content>
        </EuiPopover>
      {{/if}}
    </div>
  </template>
}
