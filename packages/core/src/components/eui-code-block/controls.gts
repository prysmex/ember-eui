import EuiButtonIcon from '../eui-button-icon';
import EuiCopy from '../eui-copy';
import { or } from 'ember-truth-helpers';
import { on } from '@ember/modifier';

<template>
  {{#if (or @showCopyButton @showFullScreenButton)}}
    <div class="euiCodeBlock__controls">
      {{#if @showFullScreenButton}}
        <EuiButtonIcon
          class="euiCodeBlock__fullScreenButton"
          @iconType={{if @isFullScreen "fullScreenExit" "fullScreen"}}
          @color="text"
          aria-label={{if @isFullScreen "Collapse" "Expand"}}
          {{on "click" @toggleFullScreen}}
        />
      {{/if}}

      {{#if @showCopyButton}}
        <div class="euiCodeBlock__copyButton">
          <EuiCopy @textToCopy={{@textToCopy}} @afterMessage="Copied" as |copy|>
            <EuiButtonIcon
              {{on "click" copy}}
              @iconType="copyClipboard"
              @color="text"
              aria-label="Copy"
            />
          </EuiCopy>
        </div>
      {{/if}}
    </div>
  {{/if}}
</template>