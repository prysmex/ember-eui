import { or } from 'ember-truth-helpers';
import EuiButtonEmpty from './eui-button-empty';
import EuiButton from './eui-buttonn';
import EuiText from './eui-text';
import EuiModal from './eui-modal';
import EuiModalHeader from './eui-modal-header';
import EuiModalHeaderTitle from './eui-modal-header-title';
import EuiModalBody from './eui-modal-body';
import EuiModalFooter from './eui-modal-footer';
import { on } from '@ember/modifier';

<template>
  <EuiModal class="euiModal--confirmation" @onClose={{@onCancel}} ...attributes>

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
</template>
