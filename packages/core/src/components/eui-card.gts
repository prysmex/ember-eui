import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCardSelectProps, euiCardSelectableColor } from '../eui-card-select';

import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import { and, eq, or, not, notEq } from 'ember-truth-helpers';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiTitle from '@ember-eui/core/components/eui-title';
import EuiText from '@ember-eui/core/components/eui-text';
import EuiBetaBadge from '@ember-eui/core/components/eui-beta-badge';
import EuiCardSelect from '@ember-eui/core/components/eui-card-select';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { set } from 'ember-set-helper/helpers/set';
import { element } from 'ember-element-helper';
import { optional } from 'ember-composable-helpers/helpers/optional';

type EuiCardComponentArgs = {
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
};

export default class EuiCardComponent extends Component<EuiCardComponentArgs> {
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

  <template>
    {{#let
      (if @selectable (guidFor))
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
        @hasShadow={{or @isDisabled @display}}
        @hasBorder={{if @display @display undefined}}
        @paddingSize={{@paddingSize}}
        ...attributes
      >

        {{#if (or (has-block "icon") (or @image @icon))}}
          <div class={{this.topClasses}}>
            {{#if (has-block "icon")}}
              {{yield "euiCard__icon" to="icon"}}
            {{else}}
              {{#if (or @image @icon)}}
                {{#if (and @image (not-eq layout "horizontal"))}}
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
            @iconType={{@selectable.iconType}}
            @isLoading={{@selectable.isLoading}}
            @href={{@selectable.href}}
            @iconSide={{@selectable.iconSide}}
            @flush={{@selectable.flush}}
            {{didInsert (set this "link")}}
            {{on "click" (optional @selectable.onClick)}}
          />
        {{/if}}
      </EuiPanel>
    {{/let}}
  </template>
}
