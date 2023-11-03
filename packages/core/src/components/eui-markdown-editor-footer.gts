import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiPopover from './eui-popover.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiModal from './eui-modal.gts';
import EuiModalHeader from './eui-modal-header.gts';
import EuiModalBody from './eui-modal-body.gts';
import EuiTitle from './eui-title.gts';
import EuiText from './eui-text.gts';
import EuiHorizontalRule from './eui-horizontal-rule.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiMarkdownFormat from './eui-markdown-format.gts';
import MarkdownLogo from '../components/eui-markdown-editor-footer/icons/markdown-logo';
import set from 'ember-set-helper/helpers/set';

import { on } from '@ember/modifier';

import { and, not } from 'ember-truth-helpers';

export interface EuiMarkdownEditorFooterSignature {
  Args: {
    isUploadingFiles?: boolean;
    errors?: string[];
    uiPlugins?: any[];
  };
}

export default class EuiMarkdownEditorFooterComponent extends Component<EuiMarkdownEditorFooterSignature> {
  @tracked isPopoverOpen = false;
  @tracked isShowingHelp = false;

  <template>
    <div class="euiMarkdownEditorFooter">
      <div class="euiMarkdownEditorFooter__actions">

        {{#if @isUploadingFiles}}
          {{! pending implementation}}
          <EuiButtonIcon
            @iconType={{component EuiLoadingSpinner}}
            @useComponent={{true}}
            {{! aria-label={ariaLabels.uploadingFiles} }}
          />
        {{/if}}
        {{#if (and @errors @errors.length)}}
          <EuiPopover
            @isOpen={{this.isPopoverOpen}}
            @closePopover={{set this "isPopoverOpen" false}}
          >
            <:button>
              <EuiButtonEmpty
                @iconType="error"
                @size="s"
                @color="danger"
                {{! aria-label={ariaLabels.showSyntaxErrors} }}
                {{on
                  "click"
                  (set this "isPopoverOpen" (not this.isPopoverOpen))
                }}
              >
                {{@errors.length}}
              </EuiButtonEmpty>
            </:button>
          </EuiPopover>
        {{/if}}
      </div>
      <EuiButtonIcon
        class="euiMarkdownEditorFooter__help"
        @iconType={{component MarkdownLogo}}
        @useComponent={{true}}
        @color="text"
        @useSvg={{true}}
        {{! aria-label={ariaLabels.showMarkdownHelp} }}
        {{on "click" (set this "isShowingHelp" (not this.isShowingHelp))}}
      />

      {{#if this.isShowingHelp}}

        <EuiModal @onClose={{set this "isShowingHelp" false}}>
          <EuiModalHeader>
            <EuiTitle>
              <h3>
                Syntax Help
                {{! <EuiI18n
                token="euiMarkdownEditorFooter.syntaxTitle"
                default="Syntax help"
              /> }}
              </h3>
            </EuiTitle>
          </EuiModalHeader>
          <EuiModalBody>

            <EuiText>
              <p>The editor uses</p>
              <a
                href="https://github.github.com/gfm/"
                target="_blank"
                rel="noreferrer noopener"
              >
                Github flavored markdown
              </a>
              <p>You can also utilize these additional syntax plugins to add
                rich content to yoru text.</p>
            </EuiText>
            <EuiHorizontalRule />
            {{#each @uiPlugins as |uiPlugin|}}
              {{#if uiPlugin.helpText}}
                <EuiTitle size="xxs">
                  <p>
                    <strong>{{uiPlugin.name}}</strong>
                  </p>
                </EuiTitle>
                <EuiSpacer size="s" />
                <EuiMarkdownFormat @value={{uiPlugin.helpText}} />
                <EuiSpacer size="l" />

              {{/if}}
            {{/each}}
          </EuiModalBody>
        </EuiModal>

      {{/if}}
    </div>
  </template>
}
