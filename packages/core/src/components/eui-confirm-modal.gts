import { on } from '@ember/modifier';

import { or } from 'ember-truth-helpers';

import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiModal from './eui-modal.gts';
import EuiModalBody from './eui-modal-body.gts';
import EuiModalFooter from './eui-modal-footer.gts';
import EuiModalHeader from './eui-modal-header.gts';
import EuiModalHeaderTitle from './eui-modal-header-title.gts';
import EuiText from './eui-text.gts';

import type { EuiModalSignature } from './eui-modal.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiConfirmModalSignature {
  Element: EuiModalSignature['Element'];
  Args: {
    title?: string;
    message?: string;
    cancelButtonText?: string;
    confirmButtonText?: string;
    buttonColor?: string;
    confirmButtonDisabled?: boolean;
    isLoading?: boolean;
    onCancel: () => void;
    onConfirm: () => void;
  };
  Blocks: {
    title: [];
    default: [];
  };
}

const EuiConfirmModal: TemplateOnlyComponent<EuiConfirmModalSignature> =
  <template>
    <EuiModal
      class="euiModal--confirmation"
      @onClose={{@onCancel}}
      ...attributes
    >

      {{#if (or @title (has-block "title"))}}
        <EuiModalHeader>
          <EuiModalHeaderTitle>
            {{@title}}
            {{yield to="title"}}
          </EuiModalHeaderTitle>
        </EuiModalHeader>
      {{/if}}

      {{#if (or @message (has-block))}}
        <EuiModalBody>
          <EuiText>
            {{@message}}
            {{yield}}
          </EuiText>
        </EuiModalBody>
      {{/if}}

      <EuiModalFooter>
        <EuiButtonEmpty {{on "click" @onCancel}}>
          {{@cancelButtonText}}
        </EuiButtonEmpty>
        <EuiButton
          @fill={{true}}
          @color={{@buttonColor}}
          @isDisabled={{@confirmButtonDisabled}}
          @isLoading={{@isLoading}}
          {{on "click" @onConfirm}}
        >
          {{@confirmButtonText}}
        </EuiButton>
      </EuiModalFooter>

    </EuiModal>
  </template>;

export default EuiConfirmModal;
