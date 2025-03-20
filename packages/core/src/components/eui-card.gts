import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from 'ember-composable-helpers/helpers/optional';
import { element } from 'ember-element-helper';
import set from 'ember-set-helper/helpers/set';
import { and, eq, not, notEq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiBetaBadge from './eui-beta-badge.gts';
import { euiCardSelectableColor } from './eui-card-select.gts';
import EuiCardSelect from './eui-card-select.gts';
import EuiIcon from './eui-icon.gts';
import EuiPanel from './eui-panel.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiCardSelectProps } from './eui-card-select';
import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';
import type { EuiTitleSignature } from './eui-title';

type EuiCardComponentArgs = {
  footer?: string;
  selectable?: EuiCardSelectProps;
  /**
   * Class that will apply to the card top section.
   */
  topClassName?: string;

  /**
   * Class that will apply to the card content section.
   */
  contentClassName?: string;

  /**
   * Class that will apply to the card footer section.
   */
  footerClassName?: string;

  target?: string;

  betaBadgeProps?: {
    label: string;
    title?: string;
    tooltipContent?: string;
  };

  description?: string;

  /**
   * The title of the card.
   */
  title?: string;
  titleSize?: EuiTitleSignature['Args']['size'];

  /**
   * The title element. Will wrap the title in a heading tag.
   */
  titleElement?: string;

  href?: string;

  onClick?: (e: MouseEvent) => void;

  isDisabled?: boolean;

  textAlign?: 'left' | 'center' | 'right';

  image?: string;
  icon?: string;
  layout?: 'horizontal' | 'vertical';

  display?: EuiPanelSignature['Args']['color'];
  paddingSize?: EuiPanelSignature['Args']['paddingSize'];

  iconSize?: EuiIconSignature['Args']['size'];
};

export interface EuiCardSignature {
  Element: EuiPanelSignature['Element'];
  Args: EuiCardComponentArgs;
  Blocks: {
    icon: ['euiCard__icon'];
    title: [() => void];
    description: [];
    body: [];
    footer: [];
  };
}

export default class EuiCardComponent extends Component<EuiCardSignature> {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  outerOnClick = (e: MouseEvent) => {
    if (this.link && this.link !== e.target) {
      this.link.click();
    }
  };

  get selectableColorClass() {
    const selectable = this.args.selectable;

    return selectable
      ? `euiCard--isSelectable--${euiCardSelectableColor(
          selectable.color,
          selectable.isSelected
        )}`
      : undefined;
  }

  get topClasses(): string {
    return ['euiCard__top', this.args.topClassName].join(' ');
  }

  get contentClasses(): string {
    return ['euiCard__content', this.args.contentClassName].join(' ');
  }

  get footerClasses(): string {
    return ['euiCard__footer', this.args.footerClassName].join(' ');
  }

  willDestroy() {
    super.willDestroy();

    this.link = null;
  }

  <template>
    {{#let
      (if @selectable (randomId))
      (and
        (not @isDisabled)
        (or @onClick @href (and @selectable (not @selectable.isDisabled)))
      )
      (argOrDefault @titleElement "span")
      (argOrDefault @layout "vertical")
      as |selectableId isClickable titleElement layout|
    }}
      <EuiPanel
        class={{classNames
          (if (eq layout "horizontal") "euiCard--horizontal")
          (if isClickable "euiCard--isClickable")
          (if @betaBadgeProps.label "euiCard--hasBetaBadge")
          (if
            @icon "euiCard--hasIcon" (if (has-block "icon") "euiCard--hasIcon")
          )
          (if @selectable "euiCard--isSelectable")
          (if (and @selectable @selectable.isSelected) "euiCard-isSelected")
          (if @isDisabled "euiCard-isDisabled")
          this.selectableColorClass
          componentName="EuiCard"
          textAlign=(argOrDefault @textAlign "center")
        }}
        @color={{if @isDisabled "subdued" @display}}
        @onClick={{if isClickable this.outerOnClick}}
        @hasShadow={{if (or @isDisabled @display) true}}
        @hasBorder={{if @display true undefined}}
        @paddingSize={{@paddingSize}}
        ...attributes
      >

        {{#if (or (has-block "icon") (or @image @icon))}}
          <div class={{this.topClasses}}>
            {{#if (has-block "icon")}}
              {{yield "euiCard__icon" to="icon"}}
            {{else}}
              {{#if (or @image @icon)}}
                {{#if (and @image (notEq layout "horizontal"))}}
                  <div class="euiCard__image">
                    <img src={{@image}} alt="card-top" />
                  </div>
                {{/if}}
                {{#if @icon}}
                  <EuiIcon
                    @iconClasses="euiCard__icon"
                    @type={{@icon}}
                    @size={{@iconSize}}
                  />
                {{/if}}
              {{/if}}
            {{/if}}
          </div>
        {{/if}}

        <div class={{this.contentClasses}}>
          <EuiTitle
            class="euiCard__title"
            @size={{argOrDefault @titleSize "s"}}
          >
            {{#if (has-block "title")}}
              {{yield (set this "link") to="title"}}
            {{else if (and (not @isDisabled) @href)}}
              <a
                class="euiCard__titleAnchor"
                target={{@target}}
                disabled={{@isDisabled}}
                href={{@href}}
                {{didInsert (set this "link")}}
              >
                {{#if (notEq titleElement "span")}}
                  {{#let (element titleElement) as |TitleElement|}}
                    <TitleElement>{{@title}}</TitleElement>
                  {{/let}}
                {{else}}
                  <span>{{@title}}</span>
                {{/if}}

              </a>
            {{else if (or @isDisabled @onClick)}}
              <button
                type="button"
                class="euiCard__titleButton"
                disabled={{@isDisabled}}
                {{didInsert (set this "link")}}
                {{on "click" (optional @onClick)}}
              >
                {{#if (notEq titleElement "span")}}
                  {{#let (element titleElement) as |TitleElement|}}
                    <TitleElement>{{@title}}</TitleElement>
                  {{/let}}
                {{else}}
                  <span>{{@title}}</span>
                {{/if}}
              </button>
            {{else}}
              {{#if (notEq titleElement "span")}}
                {{#let (element titleElement) as |TitleElement|}}
                  <TitleElement>{{@title}}</TitleElement>
                {{/let}}
              {{else}}
                <span>{{@title}}</span>
              {{/if}}
            {{/if}}
          </EuiTitle>
          {{#if (or @description (has-block "description"))}}
            <EuiText @grow={{true}} @size="s" class="euiCard__description">
              {{#if (has-block "description")}}
                <p>{{yield to="description"}}</p>
              {{else}}
                <p>{{@description}}</p>
              {{/if}}
            </EuiText>
          {{/if}}
          {{yield to="body"}}
        </div>
        {{#if @betaBadgeProps.label}}
          <span class="euiCard__betaBadgeWrapper">
            <EuiBetaBadge
              class="euiCard__betaBadge"
              @label={{@betaBadgeProps.label}}
              @title={{@betaBadgeProps.title}}
              @tooltipContent={{@betaBadgeProps.tooltipContent}}
            />
          </span>
        {{/if}}
        {{#if (and (eq layout "vertical") (or (has-block "footer") @footer))}}
          <div class={{this.footerClasses}}>
            {{#if (has-block "footer")}}
              {{yield to="footer"}}
            {{else}}
              {{@footer}}
            {{/if}}
          </div>
        {{/if}}
        {{#if @selectable}}
          <EuiCardSelect
            @type={{@selectable.type}}
            @buttonId={{selectableId}}
            @isSelected={{@selectable.isSelected}}
            @isDisabled={{@selectable.isDisabled}}
            @color={{@selectable.color}}
            @isLoading={{@selectable.isLoading}}
            @href={{@selectable.href}}
            @iconSide={{@selectable.iconSide}}
            @flush={{@selectable.flush}}
            {{didInsert (set this "link")}}
            @onClick={{optional @selectable.onClick}}
          />
        {{/if}}
      </EuiPanel>
    {{/let}}
  </template>
}
