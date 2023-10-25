import { or } from 'ember-truth-helpers';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiButton from '@ember-eui/core/components/eui-buttonn';
import EuiText from '@ember-eui/core/components/eui-text';
import EuiModal from '@ember-eui/core/components/eui-modal';
import EuiModalHeader from '@ember-eui/core/components/eui-modal-header';
import EuiModalHeaderTitle from '@ember-eui/core/components/eui-modal-header-title';
import EuiModalBody from '@ember-eui/core/components/eui-modal-body';
import EuiModalFooter from '@ember-eui/core/components/eui-modal-footer';
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
