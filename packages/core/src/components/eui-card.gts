import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { element } from 'ember-element-helper';
import set from 'ember-set-helper/helpers/set';
import { and, eq, not, notEq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
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
  /** Footer text (vertical layout only). Use the `<:footer>` block for markup. */
  footer?: string;
  /**
   * Adds a "Select" toggle button to the bottom of the card, making the card
   * selectable: `{ onClick, isSelected, isDisabled, color, … }` (see
   * `EuiCardSelectProps`). Clicking anywhere on the card clicks it.
   */
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
  /** `target` of the `@href` link, e.g. `'_blank'`. */
  target?: string;
  /**
   * Shows an `EuiBetaBadge` on the card's top edge:
   * `{ label: 'Beta', title?, tooltipContent? }`.
   */
  betaBadgeProps?: {
    label: string;
    title?: string;
    tooltipContent?: string;
  };
  /** Text under the title. Use the `<:description>` block for markup. */
  description?: string;
  /**
   * The title of the card.
   */
  title?: string;
  /** Size of the title, any `EuiTitle` size. Defaults to `'s'`. */
  titleSize?: EuiTitleSignature['Args']['size'];
  /**
   * Tag wrapping the title, e.g. `'h3'` to include it in the page outline.
   * Defaults to `'span'`.
   */
  titleElement?: string;
  /** Makes the title a link; clicking anywhere on the card follows it. */
  href?: string;
  /** Makes the title a button; clicking anywhere on the card calls it. */
  onClick?: (e: MouseEvent) => void;
  /** Disables the card's link or button and greys it out. */
  isDisabled?: boolean;
  /** `'left'`, `'center'` or `'right'`. Defaults to `'center'`. */
  textAlign?: 'left' | 'center' | 'right';
  /** URL of an image across the top of the card (vertical layout only). */
  image?: string;
  /** Icon above the title; anything `EuiIcon`'s `@type` accepts. */
  icon?: string;
  /**
   * `'vertical'` stacks icon, title, description and footer.
   * `'horizontal'` puts the icon next to the text and hides the image and
   * footer. Defaults to `'vertical'`.
   */
  layout?: 'horizontal' | 'vertical';
  /**
   * Background of the card, any `EuiPanel` color (`'plain'`, `'subdued'`,
   * `'transparent'`, `'primary'`, …); also adds a border. Defaults to a
   * plain panel with a shadow.
   */
  display?: EuiPanelSignature['Args']['color'];
  /** Padding inside the card, any `EuiPanel` padding size. */
  paddingSize?: EuiPanelSignature['Args']['paddingSize'];
  /** Size of `@icon`. */
  iconSize?: EuiIconSignature['Args']['size'];
};

export interface EuiCardSignature {
  Element: EuiPanelSignature['Element'];
  Args: EuiCardComponentArgs;
  Blocks: {
    /**
     * Custom content above the title instead of `@icon` / `@image`; yields
     * the class to put on it.
     */
    icon: ['euiCard__icon'];
    /**
     * Custom title. Yields a function to register your link or button
     * element (e.g. with `did-insert`) so clicks on the card trigger it.
     */
    title: [() => void];
    /** Custom description, instead of `@description`. */
    description: [];
    /** Extra content after the description. */
    body: [];
    /** Custom footer, instead of `@footer` (vertical layout only). */
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
