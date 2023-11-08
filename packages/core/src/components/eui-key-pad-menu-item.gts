import { helper } from '@ember/component/helper';
import { element } from 'ember-element-helper';
import { and, eq, not } from 'ember-truth-helpers';
import uniqueId from '../helpers/unique-id';
import classNames from '../helpers/class-names';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

import argOrDefault from '../helpers/arg-or-default';
import EuiRadio from './eui-radio.gts';
import EuiCheckbox from './eui-checkbox.gts';
import EuiBetaBadge from './eui-beta-badge.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const charAt = helper(function ([str, num]: [string | undefined, number]) {
  return str?.charAt?.(num);
});

export interface EuiKeyPadMenuItemSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    checkable?: 'label';
    href?: string;
    isDisabled?: boolean;
    isSelected?: boolean;
    label?: string;
    name?: string;
    value?: string;
    onChange: (id: string, value?: string | Event) => void;
    betaBadgeLabel?: string;
    betaBadgeIconType?: string;
    betaBadgeTooltipContent?: string;
    id?: string;
    target?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiKeyPadMenuItem: TemplateOnlyComponent<EuiKeyPadMenuItemSignature> =
  <template>
    {{#let
      (if @checkable "label" (if (and @href (not @isDisabled)) "a" "button"))
      (argOrDefault @id (uniqueId))
      (and @href (not @isDisabled))
      as |ElementTag itemId useHref|
    }}
      {{#let (element ElementTag) as |TagElement|}}
        <TagElement
          href={{if useHref @href}}
          target={{if useHref @target}}
          aria-current={{if (and useHref @isSelected) @isSelected}}
          for={{if @checkable itemId}}
          disabled={{if (and (not useHref) (not @checkable)) @isDisabled}}
          type={{if (and (not useHref) (not @checkable)) "button"}}
          aria-pressed={{if (and (not useHref) (not @checkable)) @isSelected}}
          class={{classNames
            "euiKeyPadMenuItem"
            (if @betaBadgeLabel "euiKeyPadMenuItem--hasBetaBadge")
            (if @checkable "euiKeyPadMenuItem--checkable")
            (if @isDisabled "euiKeyPadMenuItem-isDisabled")
            (if @isSelected "euiKeyPadMenuItem-isSelected")
          }}
          rel={{if useHref "noreferrer"}}
          {{!@glint-expect-error}}
          ...attributes
        >
          <span class="euiKeyPadMenuItem__inner">
            {{#if @checkable}}
              {{#if (eq @checkable "single")}}
                {{! template-lint-disable no-duplicate-id }}
                <EuiRadio
                  id={{itemId}}
                  @containerClass="euiKeyPadMenuItem__checkableInput"
                  @checked={{@isSelected}}
                  @disabled={{@isDisabled}}
                  @name={{@name}}
                  value={{@value}}
                  {{on "change" (fn @onChange itemId @value)}}
                />
              {{else}}
                <EuiCheckbox
                  id={{itemId}}
                  @containerClass="euiKeyPadMenuItem__checkableInput"
                  @checked={{@isSelected}}
                  @disabled={{@isDisabled}}
                  @name={{@name}}
                  {{on "change" (fn @onChange itemId)}}
                />
              {{/if}}
            {{else}}
              <EuiBetaBadge
                @size="s"
                @color="subdued"
                class="euiKeyPadMenuItem__betaBadge"
                @label={{charAt @betaBadgeLabel 0}}
                @title={{@betaBadgeLabel}}
                @iconType={{@betaBadgeIconType}}
                @tooltipContent={{@betaBadgeTooltipContent}}
              />
            {{/if}}
            <span class="euiKeyPadMenuItem__icon">{{yield}}</span>
            <span class="euiKeyPadMenuItem__label">{{@label}}</span>
          </span>
        </TagElement>

      {{/let}}
    {{/let}}
  </template>;

export default EuiKeyPadMenuItem;
