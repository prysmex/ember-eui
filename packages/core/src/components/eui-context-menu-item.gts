import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { concat } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { and, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type { layoutAlignMapping, sizeMapping } from '../utils/css-mappings/eui-context-menu-item.ts';
import type { EuiIconSignature } from './eui-icon';

export interface EuiContextMenuItemSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    layoutAlign?: keyof typeof layoutAlignMapping;
    disabled?: boolean;
    size?: keyof typeof sizeMapping;
    href?: string;
    target?: string;
    isLoading?: boolean;
    icon: EuiIconSignature['Args']['type'];
    iconClasses?: string;
    hasPanel?: boolean;
  };

  Blocks: {
    default: [];
  };
}

export default class EuiContextMenuItemComponent extends Component<EuiContextMenuItemSignature> {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  @action
  registerLink(e: HTMLAnchorElement | HTMLButtonElement) {
    this.link = e;
  }

  <template>
    {{#let
      (classNames
        "euiContextMenuItem"
        componentName="EuiContextMenuItem"
        disabled=@disabled
        layoutAlign=(argOrDefault @layoutAlign "center")
        size=@size
      )
      as |classes|
    }}
      {{#if (and @href (not @disabled))}}
        <a
          class={{classes}}
          href={{@href}}
          target={{@target}}
          {{didInsert this.registerLink}}
          ...attributes
        />

      {{else}}
        <button
          class={{classes}}
          disabled={{@disabled}}
          type="button"
          {{didInsert this.registerLink}}
          ...attributes
        />
      {{/if}}
    {{/let}}

    {{! shared code that will be rendered inside the button or anchor }}
    {{#if this.link}}
      {{#in-element this.link}}
        <span
          class={{classNames
            "euiContextMenu__itemLayout"
            componentName="EuiContextMenuItem"
            layoutAlign=(argOrDefault @layoutAlign "center")
          }}
        >
          {{#if @isLoading}}
            {{! spinner is not part of eui spec }}
            <EuiLoadingSpinner class="euiContextMenu__icon" />
          {{else}}
            <EuiIcon
              @iconClasses={{concat "euiContextMenu__icon " @iconClasses}}
              @type={{@icon}}
              @size="m"
              @color="inherit"
            />
          {{/if}}
          <span class="euiContextMenuItem__text">
            {{yield}}
          </span>
          {{#if @hasPanel}}
            <EuiIcon
              @type="arrowRight"
              @size="m"
              class="euiContextMenu__arrow"
            />
          {{/if}}
        </span>
      {{/in-element}}
    {{/if}}
  </template>
}
