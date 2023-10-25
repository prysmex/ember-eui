import classNames from '@ember-eui/core/helpers/class-names';
import screenReaderOnly from '@ember-eui/core/modifiers/screen-reader-only';
import { on } from '@ember/modifier';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiText from '@ember-eui/core/components/eui-text';
import EuiMarkdownFormat from '@ember-eui/core/components/eui-markdown-format';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';

<template>
  <div
    class={{classNames
      componentName="EuiToast"
      color=(argOrDefault @color "none")
    }}
    ...attributes
  >
    {{! TODO: Translate strings when EuiI18n is available }}
    <p {{screenReaderOnly}}>
      A new notification appears
    </p>

    <div
      class={{classNames
        "euiToastHeader"
        (if @body "euiToastHeader--withBody")
      }}
      aria-label="Notification"
      data-test-subj="euiToastHeader"
    >
      {{#if @iconType}}
        <EuiIcon
          @iconClasses="euiToastHeader__icon"
          @type={{@iconType}}
          @size="m"
          aria-hidden="true"
        />
      {{/if}}

      <span class="euiToastHeader__title">
        {{@title}}
      </span>
    </div>

    {{#if @onClose}}
      <button
        type="button"
        class="euiToast__closeButton"
        aria-label="Dismiss toast"
        data-test-subj="toastCloseButton"
        {{on "click" @onClose}}
      >
        <EuiIcon @type="cross" @size="m" aria-hidden="true" />
      </button>
    {{/if}}

    {{#if @body}}
      {{#if @useMarkdownFormat}}
        <EuiMarkdownFormat @value={{@body}} />
      {{else}}
        <EuiText @size="s" class="euiToastBody">
          {{@body}}
        </EuiText>
      {{/if}}
    {{/if}}
  </div>
</template>
