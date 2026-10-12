import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { modifier } from 'ember-modifier';
import { and, eq, not, or } from 'ember-truth-helpers';

import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiCardBetaBadgeStyles,
  euiCardStyles,
  euiCardTextStyles,
  euiPanelStyles,
  euiTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiBetaBadge from './eui-beta-badge.gts';
import EuiCardSelect from './eui-card-select.gts';
import EuiIcon from './eui-icon.gts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';
import EuiPanel from './eui-panel.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';

import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiCardSelectProps } from './eui-card-select';
import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';

type EuiCardPadding = NonNullable<EuiPanelSignature['Args']['paddingSize']>;

type EuiCardComponentArgs = {
  /** Footer text (vertical layout only). Use the `<:footer>` block for markup. */
  footer?: string;
  /**
   * Adds a "Select" switch button to the bottom of the card, making the card
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
   * `rel` of the `@href` link. `noreferrer` is always added, and `noopener`
   * for `target="_blank"`.
   */
  rel?: string;
  /**
   * Shows an `EuiBetaBadge` centered on the card's top edge:
   * `{ label: 'Beta', title?, tooltipContent?, tooltipPosition? }`.
   */
  betaBadgeProps?: {
    label: string;
    title?: string;
    tooltipContent?: string;
    tooltipPosition?: 'top' | 'right' | 'bottom' | 'left';
  };
  /** Text under the title. Use the `<:description>` block for markup. */
  description?: string;
  /**
   * The title of the card.
   */
  title?: string;
  /** Size of the title, `'s'` or `'xs'` (any `EuiTitle` size). Defaults to `'s'`. */
  titleSize?: 'xxxs' | 'xxs' | 'xs' | 's' | 'm' | 'l';
  /**
   * Tag of the title, e.g. `'h3'` to include it in the page outline.
   * Defaults to `'p'`.
   */
  titleElement?: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p' | 'span';
  /** Makes the title a link; clicking anywhere on the card follows it. */
  href?: string;
  /** Makes the title a button; clicking anywhere on the card calls it. */
  onClick?: (e: MouseEvent) => void;
  /** Disables the card's link or button and greys it out. */
  isDisabled?: boolean;
  /**
   * `'left'`, `'center'` or `'right'` (logical: start/end in RTL). Ignored
   * by the horizontal layout. Defaults to `'center'`.
   */
  textAlign?: 'left' | 'center' | 'right';
  /** URL of an image across the top of the card (vertical layout only). */
  image?: string;
  /** Icon above the title; anything `EuiIcon`'s `@type` accepts. */
  icon?: EuiIconSignature['Args']['type'];
  /**
   * `'vertical'` stacks icon, title, description and footer.
   * `'horizontal'` puts the icon next to the text and ignores the image,
   * footer and text alignment. Defaults to `'vertical'`.
   */
  layout?: 'horizontal' | 'vertical';
  /**
   * Background of the card, any `EuiPanel` color (`'plain'`, `'subdued'`,
   * `'transparent'`, `'primary'`, …). Without it the card is plain with a
   * shadow; with it the card has neither shadow nor border.
   */
  display?: EuiPanelSignature['Args']['color'];
  /** Padding inside the card: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
  paddingSize?: EuiCardPadding;
  /** Size of `@icon`. */
  iconSize?: EuiIconSignature['Args']['size'];
  /**
   * Extra styles composed last into the card's class (like upstream's
   * `css` prop).
   */
  css?: EuiCss;
};

export interface EuiCardSignature {
  Element: EuiPanelSignature['Element'];
  Args: EuiCardComponentArgs;
  Blocks: {
    /**
     * Custom content above the title instead of `@icon` / `@image`; yields
     * the classes (`euiCard__icon` plus its spacing) to put on it.
     */
    icon: [string];
    /**
     * Custom title. Yields a function to register your link or button
     * element (e.g. with `did-insert`) so clicks on the card trigger it.
     */
    title: [(element: HTMLAnchorElement | HTMLButtonElement | null) => void];
    /** Custom description, instead of `@description`. */
    description: [];
    /** Extra content after the description (upstream `children`). */
    body: [];
    /** Custom footer, instead of `@footer` (vertical layout only). */
    footer: [];
  };
}

/**
 * Clicks on these, inside the card, are theirs: the card does not forward
 * them to the title link as well.
 */
const INTERACTIVE =
  'a[href], button, input, select, textarea, label, summary, [contenteditable], [tabindex]:not([tabindex="-1"]), [role="button"], [role="link"], [role="checkbox"], [role="switch"]';

// Upstream factories take the padding size; one memoizable factory each.
type CardStyles = ReturnType<typeof euiCardStyles>;
type BetaStyles = ReturnType<typeof euiCardBetaBadgeStyles>;
const PADDINGS: EuiCardPadding[] = ['none', 's', 'm', 'l'];
const cardFactories = Object.fromEntries(
  PADDINGS.map((size) => [
    size,
    (theme: EuiBorealisContext): CardStyles => euiCardStyles(theme, size)
  ])
) as Record<EuiCardPadding, (theme: EuiBorealisContext) => CardStyles>;
const betaFactories = Object.fromEntries(
  PADDINGS.map((size) => [
    size,
    (theme: EuiBorealisContext): BetaStyles =>
      euiCardBetaBadgeStyles(theme, size)
  ])
) as Record<EuiCardPadding, (theme: EuiBorealisContext) => BetaStyles>;

// React's global reset, scoped to the card's own title/text elements.
const TITLE_RESET = { boxSizing: 'border-box', margin: 0, padding: 0 } as const;
const TEXT_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  textDecoration: 'none'
} as const;

/**
 * Upstream `EuiCard` (EUI 123.1.0): an `EuiPanel` whose whole surface
 * forwards clicks to the title link/button (or the select button), which
 * stays the only focusable, accessible control.
 */
export default class EuiCardComponent extends Component<EuiCardSignature> {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  ariaId = randomId();

  get context(): EuiThemeContext {
    return getEuiThemeContext(this);
  }

  get layout(): 'horizontal' | 'vertical' {
    return this.args.layout === 'horizontal' ? 'horizontal' : 'vertical';
  }

  /** Horizontal cards always align left (upstream). */
  get align(): 'left' | 'center' | 'right' {
    return this.layout === 'horizontal'
      ? 'left'
      : (this.args.textAlign ?? 'center');
  }

  get paddingSize(): EuiCardPadding {
    return this.args.paddingSize ?? 'm';
  }

  get isDisabled(): boolean {
    const href = this.args.href;
    return Boolean(this.args.isDisabled || (href && !isValidHref(href)));
  }

  get isClickable(): boolean {
    const { onClick, href, selectable } = this.args;
    return (
      !this.isDisabled &&
      Boolean(onClick || href || (selectable && !this.selectIsDisabled))
    );
  }

  /** A disabled card disables its select button unless told otherwise. */
  get selectIsDisabled(): boolean | undefined {
    const selectable = this.args.selectable;
    return selectable?.isDisabled ?? (this.isDisabled || undefined);
  }

  get titleId(): string {
    return `${this.ariaId}Title`;
  }

  get descriptionId(): string {
    return `${this.ariaId}Description`;
  }

  get betaBadgeId(): string | undefined {
    return this.args.betaBadgeProps?.label
      ? `${this.ariaId}BetaBadge`
      : undefined;
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  get color(): EuiPanelSignature['Args']['color'] {
    return this.isDisabled ? 'subdued' : this.args.display;
  }

  get hasShadow(): boolean {
    return !(this.isDisabled || this.args.display);
  }

  get betaBadgeColor(): 'subdued' | 'hollow' {
    return this.isDisabled ? 'subdued' : 'hollow';
  }

  /** The description's id, when there is one (`@description` or block). */
  descriptionFor = (hasBlock: boolean): string | undefined =>
    hasBlock || this.args.description ? this.descriptionId : undefined;

  selectAriaDescribedBy = (hasBlock: boolean): string =>
    [this.titleId, this.descriptionFor(hasBlock)].filter(Boolean).join(' ');

  buttonAriaDescribedBy = (hasBlock: boolean): string | undefined => {
    const ids = [this.betaBadgeId, this.descriptionFor(hasBlock)].filter(
      Boolean
    );
    return ids.length ? ids.join(' ') : undefined;
  };

  get cardStyles(): CardStyles {
    return useEuiBorealisStyles(
      this.context,
      cardFactories[this.paddingSize] ?? cardFactories.m
    );
  }

  /** Composed last into EuiPanel's own class, like upstream's `css`. */
  @cached
  get panelCss(): EuiCss {
    const context = this.context;
    const styles = this.cardStyles;
    const beta = this.args.betaBadgeProps?.label
      ? useEuiBorealisStyles(
          context,
          betaFactories[this.paddingSize] ?? betaFactories.m
        )
      : undefined;
    return [
      // Upstream EuiPanel adds its clickable slot for any `onClick`; the
      // card is not a button itself, so it is composed here.
      this.isClickable &&
        useEuiBorealisStyles(context, euiPanelStyles).isClickable,
      styles.card.euiCard,
      styles.card.aligned[this.align],
      this.isDisabled && styles.card.disabled,
      beta?.hasBetaBadge,
      this.args.css
    ];
  }

  @cached
  get mainClass(): string {
    const styles = this.cardStyles;
    return euiClass(
      this.context,
      styles.main.euiCard__main,
      styles.main.layout[this.layout]
    );
  }

  @cached
  get topClass(): string {
    const styles = this.cardStyles;
    return euiClass(
      this.context,
      styles.top.euiCard__top,
      styles.top.layout[this.layout],
      this.isDisabled && styles.top.disabled
    );
  }

  get hasImage(): boolean {
    return Boolean(this.args.image) && this.layout === 'vertical';
  }

  @cached
  get imageClass(): string {
    const styles = this.cardStyles;
    return euiClass(
      this.context,
      styles.image.euiCard__image,
      this.args.display === 'transparent' && styles.image.transparent
    );
  }

  @cached
  get iconCss(): EuiCss {
    const styles = this.cardStyles;
    return [
      styles.icon.euiCard__icon,
      styles.icon.layout[this.layout],
      this.hasImage && styles.icon.withImage
    ];
  }

  @cached
  get iconBlockClass(): string {
    return `euiCard__icon ${euiClass(this.context, this.iconCss)}`;
  }

  @cached
  get contentClass(): string {
    const styles = this.cardStyles;
    return euiClass(
      this.context,
      styles.content.euiCard__content,
      styles.content.layout[this.layout],
      // EuiText takes no `css`; its margin is scoped from here.
      { '& > .euiCard__description': styles.euiCard__description }
    );
  }

  @cached
  get titleClass(): string {
    const context = this.context;
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    // Upstream EuiTitle clones its classes onto the title element.
    return euiClass(
      context,
      TITLE_RESET,
      { fontFamily: context.upstream.euiTheme.font.family },
      title.euiTitle,
      title[this.args.titleSize ?? 's']
    );
  }

  @cached
  get textClass(): string {
    const context = this.context;
    const text = useEuiBorealisStyles(context, euiCardTextStyles);
    return euiClass(
      context,
      TEXT_RESET,
      text.euiCard__text,
      text.aligned[this.align],
      this.isClickable && text.interactive,
      this.isDisabled && text.disabled
    );
  }

  @cached
  get childrenClass(): string {
    return euiClass(this.context, this.cardStyles.euiCard__children);
  }

  @cached
  get footerClass(): string {
    return euiClass(this.context, this.cardStyles.euiCard__footer);
  }

  @cached
  get betaAnchorClass(): string {
    const beta = useEuiBorealisStyles(
      this.context,
      betaFactories[this.paddingSize] ?? betaFactories.m
    );
    return euiClass(this.context, beta.euiCard__betaBadgeAnchor, {
      // EuiBetaBadge takes no `css`; upstream's badge slot is scoped here.
      '& .euiCard__betaBadge': beta.euiCard__betaBadge
    });
  }

  get spacerSize(): 's' | 'm' | 'l' | undefined {
    const size = this.paddingSize;
    return size === 'none' ? undefined : size;
  }

  setLink = (element: HTMLAnchorElement | HTMLButtonElement | null): void => {
    this.link = element;
  };

  /** Registers the element whose click the card surface forwards to. */
  registerLink = modifier(
    (element: HTMLAnchorElement | HTMLButtonElement | HTMLElement) => {
      const link = element as HTMLAnchorElement | HTMLButtonElement;
      this.link = link;
      return () => {
        if (this.link === link) this.link = null;
      };
    }
  );

  /**
   * Upstream's "redundant click": a click anywhere on the card clicks the
   * title link/button, without making the card itself a control. Clicks on
   * the link itself, or on other interactive content inside the card, are
   * left alone.
   */
  outerOnClick = (event: MouseEvent): void => {
    const link = this.link;
    if (!this.isClickable || !link) return;
    const card = event.currentTarget as HTMLElement;
    const target = event.target as Element;
    if (link === target || link.contains(target)) return;
    const interactive = target.closest(INTERACTIVE);
    if (interactive && interactive !== card && card.contains(interactive))
      return;
    link.click();
  };

  <template>
    <EuiPanel
      class="euiCard"
      @css={{this.panelCss}}
      @color={{this.color}}
      @hasShadow={{this.hasShadow}}
      @hasBorder={{false}}
      @paddingSize={{this.paddingSize}}
      {{on "click" this.outerOnClick}}
      ...attributes
    >
      <div class="euiCard__main {{this.mainClass}}">
        {{#if (or (has-block "icon") this.hasImage @icon)}}
          <div class="euiCard__top {{@topClassName}} {{this.topClass}}">
            {{#if (has-block "icon")}}
              {{yield this.iconBlockClass to="icon"}}
            {{else}}
              {{#if this.hasImage}}
                <div class="euiCard__image {{this.imageClass}}">
                  <img src={{@image}} alt="" />
                </div>
              {{/if}}
              {{#if @icon}}
                <EuiIcon
                  @iconClasses="euiCard__icon"
                  @type={{@icon}}
                  @size={{@iconSize}}
                  @css={{this.iconCss}}
                />
              {{/if}}
            {{/if}}
          </div>
        {{/if}}

        <div class="euiCard__content {{@contentClassName}} {{this.contentClass}}">
          {{#let
            (element (if @titleElement @titleElement "p"))
            as |TitleElement|
          }}
            <TitleElement
              id={{this.titleId}}
              class="euiTitle euiCard__title {{this.titleClass}}"
            >
              {{#if (has-block "title")}}
                {{yield this.setLink to="title"}}
              {{else if (and (not this.isDisabled) @href)}}
                <a
                  class="euiCard__titleAnchor {{this.textClass}}"
                  href={{@href}}
                  target={{@target}}
                  rel={{this.rel}}
                  aria-describedby={{this.descriptionFor
                    (has-block "description")
                  }}
                  {{on "click" (optional @onClick)}}
                  {{this.registerLink}}
                >{{@title}}</a>
              {{else if (or this.isDisabled @onClick)}}
                <button
                  type="button"
                  class="euiCard__titleButton {{this.textClass}}"
                  disabled={{this.isDisabled}}
                  aria-describedby={{this.buttonAriaDescribedBy
                    (has-block "description")
                  }}
                  {{on "click" (optional @onClick)}}
                  {{this.registerLink}}
                >{{@title}}</button>
              {{else}}
                <span class={{this.textClass}}>{{@title}}</span>
              {{/if}}
            </TitleElement>
          {{/let}}
          {{#if (has-block "description")}}
            <EuiText
              @size="s"
              class="euiCard__description"
              id={{this.descriptionId}}
            >
              <p>{{yield to="description"}}</p>
            </EuiText>
          {{else if @description}}
            <EuiText
              @size="s"
              class="euiCard__description"
              id={{this.descriptionId}}
            >
              <p>{{@description}}</p>
            </EuiText>
          {{/if}}
          {{#if (has-block "body")}}
            <div class="euiCard__children {{this.childrenClass}}">
              {{yield to="body"}}
            </div>
          {{/if}}
        </div>

        {{#if @betaBadgeProps.label}}
          <span class="euiCard__betaBadgeAnchor {{this.betaAnchorClass}}">
            <EuiBetaBadge
              id={{this.betaBadgeId}}
              class="euiCard__betaBadge"
              @color={{this.betaBadgeColor}}
              @label={{@betaBadgeProps.label}}
              @title={{@betaBadgeProps.title}}
              @tooltipContent={{@betaBadgeProps.tooltipContent}}
              @tooltipPosition={{@betaBadgeProps.tooltipPosition}}
            />
          </span>
        {{/if}}

        {{#if
          (and (eq this.layout "vertical") (or (has-block "footer") @footer))
        }}
          <div class="euiCard__footer {{@footerClassName}} {{this.footerClass}}">
            {{#if (has-block "footer")}}
              {{yield to="footer"}}
            {{else}}
              {{@footer}}
            {{/if}}
          </div>
        {{/if}}
      </div>

      {{#if @selectable}}
        {{#if this.spacerSize}}
          <EuiSpacer @size={{this.spacerSize}} />
        {{/if}}
        <EuiCardSelect
          aria-describedby={{this.selectAriaDescribedBy
            (has-block "description")
          }}
          @type={{@selectable.type}}
          @buttonId={{@selectable.buttonId}}
          @isSelected={{@selectable.isSelected}}
          @isDisabled={{this.selectIsDisabled}}
          @color={{@selectable.color}}
          @isLoading={{@selectable.isLoading}}
          @href={{@selectable.href}}
          @iconSide={{@selectable.iconSide}}
          @onClick={{@selectable.onClick}}
          {{this.registerLink}}
        />
      {{/if}}
    </EuiPanel>
  </template>
}
