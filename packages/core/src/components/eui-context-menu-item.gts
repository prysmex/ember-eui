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

/**
 * An action in a menu, usually inside an `EuiContextMenuPanel` in an
 * `EuiPopover`. Add `{{on "click" …}}` for the action.
 */
export interface EuiContextMenuItemSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /**
     * Vertical alignment of the icon and text: `'center'`, `'top'` or
     * `'bottom'`. Defaults to `'center'`.
     */
    layoutAlign?: keyof typeof layoutAlignMapping;
    /** Disables the item. */
    disabled?: boolean;
    /** `'s'` or `'m'`. Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /** Renders the item as a link. */
    href?: string;
    /** `target` of the `@href` link, e.g. `'_blank'`. */
    target?: string;
    /** Shows a spinner instead of the icon. */
    isLoading?: boolean;
    /**
     * Icon before the text; anything `EuiIcon`'s `@type` accepts. Pass
     * `'empty'` to align items without an icon with the others.
     */
    icon: EuiIconSignature['Args']['type'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** Shows an arrow on the right, for items opening another panel. */
    hasPanel?: boolean;
  };

  Blocks: {
    /** The item's text. */
    default: [];
  };
}

export default class EuiContextMenuItemComponent extends Component<EuiContextMenuItemSignature> {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  @action
  registerLink(e: HTMLAnchorElement | HTMLButtonElement) {
    this.link = e;
  }

  willDestroy() {
    super.willDestroy();
    
    this.link = null;
  }

  <template>
    {{#let
      (classNames
        "euiContextMenuItem"
        componentName="EuiContextMenuItem"
        disabled=@disabled
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
