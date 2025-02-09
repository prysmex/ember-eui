import { on } from '@ember/modifier';
import { EnsureSafeComponentHelper } from '@embroider/util';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { element } from 'ember-element-helper';
import set from 'ember-set-helper/helpers/set';
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
    href?: string;
    target?: string;
    onClick?: (event: MouseEvent) => void;
    label?: string;
    iconType?: EuiIconSignature['Args']['type'];
    isActive?: boolean;
    isDisabled?: boolean;
    wrapText?: boolean;
    extraAction?: ComponentLike;
    size?: keyof typeof sizeMapping;
    color?: keyof typeof colorMapping;
  };
  Blocks: {
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
          (component (EnsureSafeComponentHelper @extraAction))
          as |ExtraAction|
        }}
          <ExtraAction />
        {{/let}}

      {{/if}}
    </li>
  </template>;

export default EuiListGroupItem;
