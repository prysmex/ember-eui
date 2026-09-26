import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { and, eq, not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-list-group-item.ts';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

export interface EuiListGroupItemSignature {
  Element:
    | HTMLLIElement
    | HTMLAnchorElement
    | HTMLButtonElement
    | HTMLSpanElement;
  Args: {
    /** Makes the item a link. */
    href?: string;
    /** `target` of the `@href` link. */
    target?: string;
    /** Makes the item a button calling this function. */
    onClick?: (event: MouseEvent) => void;
    /** The item's text. */
    label?: string;
    /** Icon before the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Highlights the item, e.g. the current page. */
    isActive?: boolean;
    /** Disables the item. */
    isDisabled?: boolean;
    /** Wraps long text instead of truncating it. */
    wrapText?: boolean;
    /**
     * A component rendered at the end of the item, e.g. an
     * `EuiButtonIcon` to pin it (use `(component EuiButtonIcon …)`).
     */
    extraAction?: ComponentLike;
    /** `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    size?: keyof typeof sizeMapping;
    /**
     * `'inherit'`, `'primary'`, `'text'`, `'subdued'` or `'ghost'`.
     * Defaults to `'inherit'`.
     */
    color?: keyof typeof colorMapping;
  };
  Blocks: {
    /** Custom content instead of `@label`. */
    default: [];
  };
}

const EuiListGroupItem: TemplateOnlyComponent<EuiListGroupItemSignature> =
  <template>
    <li
      class={{classNames
        (if (or @href @onClick) "euiListGroupItem-isClickable")
        (if @isActive "euiListGroupItem-isActive")
        (if @isDisabled "euiListGroupItem-isDisabled")
        (if @wrapText "euiListGroupItem-wrapText")
        componentName="EuiListGroupItem"
        size=(argOrDefault @size "m")
        color=(argOrDefault @color "inherit")
      }}
    >
      {{#if (and @href (not @isDisabled))}}
        <a
          class="euiListGroupItem__button"
          href={{@href}}
          target={{@target}}
          {{on "click" (optional @onClick)}}
          ...attributes
        >
          {{#if @iconType}}
            <EuiIcon
              @iconClasses="euiListGroupItem__icon"
              @type={{@iconType}}
            />
          {{/if}}
          <span class="euiListGroupItem__label">
            {{#if (has-block)}}
              {{yield}}
            {{else}}
              {{@label}}
            {{/if}}
          </span>
        </a>
      {{else if (or @onClick (and @href @isDisabled))}}
        <button
          class="euiListGroupItem__button"
          type="button"
          disabled={{eq @isDisabled true}}
          {{on "click" (optional @onClick)}}
          ...attributes
        >
          {{#if @iconType}}
            <EuiIcon
              @iconClasses="euiListGroupItem__icon"
              @type={{@iconType}}
              @color="inherit"
            />
          {{/if}}
          <span class="euiListGroupItem__label">
            {{#if (has-block)}}
              {{yield}}
            {{else}}
              {{@label}}
            {{/if}}
          </span>
        </button>
      {{else}}
        <span class="euiListGroupItem__text" ...attributes>
          {{#if @iconType}}
            <EuiIcon
              @iconClasses="euiListGroupItem__icon"
              @type={{@iconType}}
              @color="inherit"
            />
          {{/if}}
          <span class="euiListGroupItem__label">
            {{#if (has-block)}}
              {{yield}}
            {{else}}
              {{@label}}
            {{/if}}
          </span>
        </span>
      {{/if}}
      {{#if @extraAction}}
        {{#let
          (component @extraAction)
          as |ExtraAction|
        }}
          <ExtraAction />
        {{/let}}

      {{/if}}
    </li>
  </template>;

export default EuiListGroupItem;
