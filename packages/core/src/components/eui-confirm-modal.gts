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

import type { EuiModalSignature } from './eui-modal';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiConfirmModalSignature {
  Element: EuiModalSignature['Element'];
  Args: {
    /** Title of the modal. Use the `<:title>` block for markup. */
    title?: string;
    /** The question or explanation, e.g. "This can't be undone.". */
    message?: string;
    /** Text of the cancel button. Required: there is no default text. */
    cancelButtonText?: string;
    /** Text of the confirm button, ideally the action ("Delete report"). Required. */
    confirmButtonText?: string;
    /**
     * Color of the confirm button, any `EuiButton` color; `'danger'` for
     * destructive actions. Defaults to `'primary'`.
     */
    buttonColor?: string;
    /** Disables the confirm button, e.g. until a checkbox is checked. */
    confirmButtonDisabled?: boolean;
    /** Shows a spinner in the confirm button while the action runs. */
    isLoading?: boolean;
    /** Called by the cancel button, Escape and clicks outside. Close the modal here. */
    onCancel: () => void;
    /** Called by the confirm button. */
    onConfirm: () => void;
  };
  Blocks: {
    /** The title, after `@title`. */
    title: [];
    /** The body, after `@message` (e.g. a checkbox or details). */
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
