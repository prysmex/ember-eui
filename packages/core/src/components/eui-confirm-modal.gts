import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { modifier } from 'ember-modifier';
import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { composedOver } from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiModalStyles } from '../utils/eui/styles.generated.ts';
import EuiButton from './eui-button.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiModal from './eui-modal.gts';
import EuiModalBody from './eui-modal-body.gts';
import EuiModalFooter from './eui-modal-footer.gts';
import EuiModalHeader from './eui-modal-header.gts';
import EuiModalHeaderTitle from './eui-modal-header-title.gts';
import EuiText from './eui-text.gts';

import type { EuiModalSignature } from './eui-modal';

export const CONFIRM_BUTTON = 'confirm';
export const CANCEL_BUTTON = 'cancel';

export interface EuiConfirmModalSignature {
  Element: EuiModalSignature['Element'];
  Args: {
    /** Title of the modal (an `<h1>`). Use the `<:title>` block for markup. */
    title?: string;
    /** The question or explanation (a `<p>`), e.g. "This can't be undone.". */
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
    /**
     * The button focused when the modal opens: `'confirm'` or `'cancel'`.
     * Defaults to the modal itself.
     */
    defaultFocusedButton?: 'confirm' | 'cancel';
    /** Disables the confirm button, e.g. until a checkbox is checked. */
    confirmButtonDisabled?: boolean;
    /** Shows a spinner in the confirm button while the action runs. */
    isLoading?: boolean;
    /**
     * Width cap, as `EuiModal`'s `@maxWidth`. Defaults to `true`.
     */
    maxWidth?: EuiModalSignature['Args']['maxWidth'];
    /** Called by the cancel and close buttons and Escape. Close the modal here. */
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

/**
 * A modal asking to confirm or cancel an action, announced as an
 * `alertdialog`.
 */
export default class EuiConfirmModal extends Component<EuiConfirmModalSignature> {
  cancelButton?: HTMLElement;
  confirmButton?: HTMLElement;

  registerCancel = modifier((element: HTMLElement) => {
    this.cancelButton = element;
    return () => (this.cancelButton = undefined);
  });

  registerConfirm = modifier((element: HTMLElement) => {
    this.confirmButton = element;
    return () => (this.confirmButton = undefined);
  });

  @cached
  get confirmationClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiModalStyles);
    return euiClass(context, composedOver(styles.confirmation));
  }

  get buttonColor() {
    return this.args.buttonColor ?? 'primary';
  }

  /** Upstream focuses the button after the focus trap settles. */
  get initialFocus() {
    const which = this.args.defaultFocusedButton;
    if (which !== CANCEL_BUTTON && which !== CONFIRM_BUTTON) return undefined;
    return () => {
      const button =
        which === CANCEL_BUTTON ? this.cancelButton : this.confirmButton;
      return (button ?? this.cancelButton) as HTMLElement;
    };
  }

  <template>
    <EuiModal
      class="euiModal--confirmation {{this.confirmationClass}}"
      role="alertdialog"
      @onClose={{@onCancel}}
      @maxWidth={{@maxWidth}}
      @initialFocus={{this.initialFocus}}
      ...attributes
    >
      {{#if (or @title (has-block "title"))}}
        <EuiModalHeader>
          <EuiModalHeaderTitle data-test-subj="confirmModalTitleText">
            {{#if @title}}<h1>{{@title}}</h1>{{/if}}
            {{yield to="title"}}
          </EuiModalHeaderTitle>
        </EuiModalHeader>
      {{/if}}

      {{#if (or @message (has-block))}}
        <EuiModalBody>
          <EuiText data-test-subj="confirmModalBodyText">
            {{#if @message}}<p>{{@message}}</p>{{/if}}
            {{yield}}
          </EuiText>
        </EuiModalBody>
      {{/if}}

      <EuiModalFooter>
        <EuiButtonEmpty
          data-test-subj="confirmModalCancelButton"
          {{this.registerCancel}}
          {{on "click" @onCancel}}
        >
          {{@cancelButtonText}}
        </EuiButtonEmpty>
        <EuiButton
          data-test-subj="confirmModalConfirmButton"
          @fill={{true}}
          @color={{this.buttonColor}}
          @isDisabled={{@confirmButtonDisabled}}
          @isLoading={{@isLoading}}
          {{this.registerConfirm}}
          {{on "click" @onConfirm}}
        >
          {{@confirmButtonText}}
        </EuiButton>
      </EuiModalFooter>
    </EuiModal>
  </template>
}
