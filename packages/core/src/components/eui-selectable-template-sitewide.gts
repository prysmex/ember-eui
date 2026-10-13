import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiSelectableTemplateSitewidePopoverStyles,
  euiSelectableTemplateSitewideStyles,
  SITEWIDE_META_TYPES
} from '../utils/eui/selectable.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiAvatar from './eui-avatar.gts';
import EuiEmotionProvider from './eui-emotion-provider.gts';
import EuiHighlight from './eui-highlight.gts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiPopover from './eui-popover.gts';
import EuiPopoverFooter from './eui-popover-footer.gts';
import EuiPopoverTitle from './eui-popover-title.gts';
import EuiSelectable from './eui-selectable.gts';
import EuiSelectableMessage from './eui-selectable-message.gts';
import { CurrentBreakPointHelper } from './eui-show-for.gts';
import EuiSpacer from './eui-spacer.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiSelectableOption } from '../-private/selectable-options.ts';
import type { EuiBreakpointSize, EuiBreakpoints } from '../utils/breakpoint.ts';
import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { EuiColorMode } from '../utils/emotion/theme.ts';
import type { EuiBorealisContext } from '../utils/eui/theme.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiPopoverArgs } from './eui-popover.gts';
import type { EuiSelectableSignature } from './eui-selectable.gts';
import type { TOC } from '@ember/component/template-only';
import type { EuiAvatarSignature } from './eui-avatar';
import type { EuiIconSignature } from './eui-icon';

export interface EuiSelectableTemplateSitewideMeta {
  /** The text. */
  text: string;
  /**
   * `'application'`, `'deployment'`, `'article'`, `'case'` or
   * `'platform'`, each with its own color; anything else is plain.
   */
  type?: string;
  /** Highlights the search in this text too. */
  highlightSearchString?: boolean;
  /**
   * Extra class name(s) of the meta (upstream `className`). A custom
   * `type` also adds `euiSelectableTemplateSitewide__optionMeta--[type]`,
   * a hook to style your own types (e.g. through `listProps.css`).
   */
  className?: string;
  /** `data-test-subj` of the meta. */
  'data-test-subj'?: string;
}

export interface EuiSelectableTemplateSitewideOption extends EuiSelectableOption {
  /** Icon before the label: `{ type, color }` (subdued by default). */
  icon?: {
    type: EuiIconSignature['Args']['type'];
    color?: EuiIconSignature['Args']['color'];
    size?: EuiIconSignature['Args']['size'];
    title?: string;
  };
  /**
   * Avatar after the label, e.g. the space it belongs to (any
   * `EuiAvatar` argument): `{ name, type, color, size, imageUrl, initials,
   * iconType, ... }`. The size is `s` and the type `space` by default.
   */
  avatar?: {
    name: string;
    type?: EuiAvatarSignature['Args']['type'];
    color?: EuiAvatarSignature['Args']['color'];
    size?: EuiAvatarSignature['Args']['size'];
    imageUrl?: string;
    initials?: string;
    iconType?: EuiAvatarSignature['Args']['iconType'];
    iconSize?: EuiAvatarSignature['Args']['iconSize'];
    iconColor?: EuiAvatarSignature['Args']['iconColor'];
    isDisabled?: boolean;
    casing?: EuiAvatarSignature['Args']['casing'];
  };
  /** Details under the label, e.g. its type and where it lives. */
  meta?: EuiSelectableTemplateSitewideMeta[];
}

/** What a color mode of the template can be (upstream `EuiSelectableTemplateSitewideTheme`). */
export type EuiSelectableTemplateSitewideTheme = 'default' | 'global' | 'light' | 'dark' | 'inverse';

/** Args of `EuiPopover` the template forwards, plus `width`, `className`. */
export type EuiSelectableTemplateSitewidePopoverProps = Partial<
  Omit<EuiPopoverArgs, 'isOpen' | 'button'>
> & {
  /** Width of the popover content (`600` by default). */
  width?: number | string;
  /** Class name(s) of the popover's root. */
  className?: string;
};

/**
 * The search of a whole site or app ("Search for anything…"): a search
 * field that opens a popover of results with icons, details and avatars.
 * You provide the results (filtered from the search, e.g. by a server)
 * and navigate when one is chosen (`@onChange` gets the options with the
 * chosen one `checked: 'on'`).
 */
export interface EuiSelectableTemplateSitewideSignature {
  Element: HTMLDivElement;
  Args: {
    /** The results. */
    options: EuiSelectableTemplateSitewideOption[];
    /** Called with the options, the chosen one `checked: 'on'`. */
    onChange?: (options: EuiSelectableTemplateSitewideOption[]) => void;
    /** Called with the search text as you type. */
    onSearch?: (searchValue: string) => void;
    /** Shows "Loading results" instead of the list. */
    isLoading?: boolean;
    /**
     * Options of the search field, as in `EuiSelectable`: `{ placeholder,
     * compressed, isClearable, value, defaultValue, onChange, onSearch,
     * onKeyDown, onKeyUpCapture, onInput, onClick, onFocus, onBlur,
     * inputRef, className, prepend, append, 'data-test-subj' }`. `append`
     * and `prepend` are a string (a label, e.g. "⌘K") or a component.
     * `onFocus`, `onBlur`, `onKeyDown` and `onInput` run besides the
     * template's own handling (opening and closing the popover).
     */
    searchProps?: EuiSelectableSignature['Args']['searchProps'];
    /**
     * Options of the list, as in `EuiSelectable` (`css`, `textWrap`,
     * `truncationProps`, `isVirtualized`...), plus `className`. Defaults:
     * `{ rowHeight: 52, showIcons: false, onFocusBadge: { text: "Go to",
     * iconSide: "right" } }`; yours win.
     */
    listProps?: NonNullable<EuiSelectableSignature['Args']['listProps']> & {
      className?: string;
    };
    /**
     * Args of the `EuiPopover` housing the list (`anchorPosition`,
     * `panelPaddingSize`, `panelClassName`, `zIndex`, `closePopover`,
     * `panelRef`...), plus `width` (default `600`) and `className`.
     */
    popoverProps?: EuiSelectableTemplateSitewidePopoverProps;
    /**
     * Screen sizes (`'xs'`, `'s'`, `'m'`, `'l'`, `'xl'`) at which the
     * `<:popoverButton>` replaces the search. Without it, the button
     * always shows (if given).
     */
    popoverButtonBreakpoints?: EuiBreakpointSize[];
    /**
     * Color modes of the search and of the popover: `'light'`, `'dark'`,
     * `'inverse'` (the opposite of the nearest provider's), `'default'`
     * (the nearest provider's) and, for the popover, `'global'` (the
     * outermost provider's). Both default to `'default'`.
     */
    colorModes?: {
      search?: EuiSelectableTemplateSitewideTheme;
      popover?: EuiSelectableTemplateSitewideTheme;
    };
    /** Placeholder of the search. Defaults to "Search for anything...". */
    placeholder?: string;
    /**
     * Width of the popover content in px; `@popoverProps.width` wins.
     * Defaults to `600`.
     */
    popoverWidth?: number;
    /** As `EuiSelectable`: called with the current option, or `null`. */
    onActiveOptionChange?: EuiSelectableSignature['Args']['onActiveOptionChange'];
    /** As `EuiSelectable`: decides whether an option matches the search. */
    optionMatcher?: EuiSelectableSignature['Args']['optionMatcher'];
    /** As `EuiSelectable`: height of the list. */
    height?: EuiSelectableSignature['Args']['height'];
    /** As `EuiSelectable`: error message shown instead of the list. */
    errorMessage?: EuiSelectableSignature['Args']['errorMessage'];
    /** As `EuiSelectable`: pressing a checked option excludes it. */
    allowExclusions?: boolean;
    /** As `EuiSelectable`: screen reader text before the instructions. */
    selectableScreenReaderText?: string;
    /** As `EuiSelectable`. Defaults to `true` (one result is chosen). */
    singleSelection?: EuiSelectableSignature['Args']['singleSelection'];
    /** Text while `@isLoading`. Defaults to "Loading results". */
    loadingMessage?: string;
    /** Text when there are no results. Defaults to "No results available". */
    emptyMessage?: string;
    /** Text when the search matches nothing. Defaults to `@emptyMessage`'s. */
    noMatchesMessage?: string;
    /**
     * The results are already filtered (e.g. by a server), so the search
     * does not filter them again. Defaults to `false`.
     */
    isPreFiltered?: EuiSelectableSignature['Args']['isPreFiltered'];
    /**
     * Styles composed last into the selectable's class (upstream's `css`,
     * part of the rest props spread onto `EuiSelectable`).
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * A button opening the popover (the search moves into it), e.g. an
     * icon in a narrow header; yields the function toggling it. See
     * `@popoverButtonBreakpoints`.
     */
    popoverButton: [toggle: () => void];
    /** Content above the results, e.g. a title. */
    popoverTitle: [];
    /** Content below the results, e.g. keyboard shortcuts. */
    popoverFooter: [];
    /**
     * Custom content of each option (upstream `renderOption`), instead of
     * the highlighted label and meta; yields the option and the search
     * value. The icon / avatar stay around it.
     */
    option: [option: EuiSelectableTemplateSitewideOption, searchValue: string];
  };
}

const isMetaType = (
  type: string | undefined
): type is (typeof SITEWIDE_META_TYPES)[number] =>
  (SITEWIDE_META_TYPES as readonly (string | undefined)[]).includes(type);

/** Upstream `title`: the label and the meta texts. */
function optionTitle(option: EuiSelectableTemplateSitewideOption): string {
  return option.meta?.length
    ? `${option.label} \u2022${option.meta.map((meta) => ` ${meta.text}`).join('')}`
    : option.label;
}

/** Upstream `euiSelectableTemplateSitewidePopoverStyles`, as a theme function. */
const popoverPanelCss = (theme: EuiBorealisContext) =>
  euiSelectableTemplateSitewidePopoverStyles(theme).euiSelectableTemplateSitewide__popover;

const DEFAULT_POPOVER_WIDTH = 600;

const oppositeOf = (mode: EuiColorMode): EuiColorMode => (mode === 'dark' ? 'light' : 'dark');


/** `{{yield}}`s inside a provider of `@colorMode`, or as is without one. */
const ModeProvider = <template>
  {{#if @colorMode}}
    <EuiEmotionProvider
      @colorMode={{@colorMode}}
      @parent={{@parent}}
      @wrapper={{@wrapper}}
      @globalStyles={{false}}
      style="display: block;"
    >
      {{yield}}
    </EuiEmotionProvider>
  {{else}}
    {{yield}}
  {{/if}}
</template> as TOC<{
  Args: { colorMode?: EuiColorMode; parent?: EuiThemeContext; wrapper?: boolean };
  Blocks: { default: [] };
}>;

export default class EuiSelectableTemplateSitewide extends Component<EuiSelectableTemplateSitewideSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;

  /** The popover panel, to tell focus moving into it from leaving. */
  panel: HTMLElement | null = null;

  get themeContext(): EuiThemeContext {
    return getEuiThemeContext(this);
  }

  get breakpoints(): EuiBreakpoints {
    return this.themeContext.upstream.euiTheme.breakpoint as EuiBreakpoints;
  }

  get formattedOptions(): EuiSelectableTemplateSitewideOption[] {
    return this.args.options.map((option) => ({
      key: option.label,
      title: optionTitle(option),
      ...option,
      className: ['euiSelectableTemplateSitewide__listItem', option.className]
        .filter(Boolean)
        .join(' ')
    }));
  }

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiSelectableTemplateSitewideStyles
    );
    const metaClasses = new Map<string | undefined, string>();
    return {
      root: styles.euiSelectableTemplateSitewide,
      metasList: `euiSelectableTemplateSitewide__optionMetasList ${euiClass(
        context,
        styles.euiSelectableTemplateSitewide__optionMetasList
      )}`,
      meta: (meta: EuiSelectableTemplateSitewideMeta): string => {
        const key = isMetaType(meta.type) ? meta.type : undefined;
        let className = metaClasses.get(key);
        if (!className) {
          className = euiClass(
            context,
            styles.euiSelectableTemplateSitewide__optionMeta,
            key && styles.metaTypes.fontWeight,
            key && styles.metaTypes[key]
          );
          metaClasses.set(key, className);
        }
        // upstream order: the type's class, the base, the custom one
        return [
          meta.type && `euiSelectableTemplateSitewide__optionMeta--${meta.type}`,
          'euiSelectableTemplateSitewide__optionMeta',
          meta.className,
          className
        ]
          .filter(Boolean)
          .join(' ');
      }
    };
  }

  /** `@searchProps` over the defaults; the handlers of `@onSearch` joined. */
  /** Upstream's root styles, then the caller's `@css`. */
  @cached
  get rootCss(): EuiCss {
    return this.args.css ? [this.styles.root, this.args.css] : this.styles.root;
  }

  @cached
  get searchProps(): NonNullable<EuiSelectableTemplateSitewideSignature['Args']['searchProps']> {
    const searchProps = this.args.searchProps ?? {};
    const { onSearch } = this.args;
    const ownOnSearch = searchProps.onSearch;

    return {
      isClearable: true,
      ...searchProps,
      placeholder: this.placeholder,
      className: ['euiSelectableTemplateSitewide__search', searchProps.className]
        .filter(Boolean)
        .join(' '),
      onSearch:
        ownOnSearch || onSearch
          ? (value, matching) => {
              ownOnSearch?.(value, matching);
              onSearch?.(value);
            }
          : undefined
    };
  }

  /** `@listProps` over the defaults (upstream: the consumer's win). */
  @cached
  get listProps(): NonNullable<EuiSelectableTemplateSitewideSignature['Args']['listProps']> {
    return {
      rowHeight: 52,
      showIcons: false,
      onFocusBadge: { text: this.goTo, iconSide: 'right' },
      ...this.args.listProps
    };
  }

  get listClassName(): string {
    return ['euiSelectableTemplateSitewide__list', this.args.listProps?.className]
      .filter(Boolean)
      .join(' ');
  }

  get popoverProps(): EuiSelectableTemplateSitewidePopoverProps {
    return this.args.popoverProps ?? {};
  }

  get popoverWidth(): number | string {
    return this.popoverProps.width ?? this.args.popoverWidth ?? DEFAULT_POPOVER_WIDTH;
  }

  @cached
  get panelCss(): EuiCss {
    return [popoverPanelCss, this.popoverProps.panelCss];
  }

  /** The nearest provider's mode, the base of `'inverse'`. */
  get currentColorMode(): EuiColorMode {
    return this.themeContext.colorMode;
  }

  /** Upstream: `light`, `dark`, `inverse`; anything else is the nearest. */
  get searchColorMode(): EuiColorMode {
    const mode = this.args.colorModes?.search?.toLowerCase();

    if (mode === 'light' || mode === 'dark') return mode;
    if (mode === 'inverse') return oppositeOf(this.currentColorMode);

    return this.currentColorMode;
  }

  /** Whether the search has its own provider element (a mode is set). */
  get searchHasOwnWrapper(): boolean {
    const mode = this.args.colorModes?.search;

    return mode === 'light' || mode === 'dark' || mode === 'inverse';
  }

  /** Like `searchColorMode`, and `global`: the outermost provider's. */
  get popoverColorMode(): EuiColorMode {
    const mode = this.args.colorModes?.popover?.toLowerCase();

    if (mode === 'light' || mode === 'dark') return mode;
    if (mode === 'inverse') return oppositeOf(this.currentColorMode);
    if (mode === 'global') return this.themeContext.root.colorMode;

    return this.currentColorMode;
  }

  /** A provider is only needed when the mode differs from the one in effect. */
  get popoverProviderMode(): EuiColorMode | undefined {
    return this.popoverColorMode === this.currentColorMode ? undefined : this.popoverColorMode;
  }

  /** The search sits in the popover's mode, unless its own differs. */
  get searchProviderMode(): EuiColorMode | undefined {
    return this.searchColorMode === this.popoverColorMode ? undefined : this.searchColorMode;
  }

  get placeholder(): string {
    return (
      this.args.searchProps?.placeholder ??
      this.args.placeholder ??
      this.euiI18n.lookupToken(
        'euiSelectableTemplateSitewide.searchPlaceholder',
        'Search for anything...'
      )
    );
  }

  get loadingText(): string {
    return this.args.loadingMessage ?? this.euiI18n.lookupToken('euiSelectableTemplateSitewide.loadingResults', 'Loading results');
  }

  get noResultsText(): string {
    return this.args.emptyMessage ?? this.euiI18n.lookupToken('euiSelectableTemplateSitewide.noResults', 'No results available');
  }

  get noMatchesText(): string {
    return this.args.noMatchesMessage ?? this.noResultsText;
  }

  get goTo(): string {
    return this.euiI18n.lookupToken('euiSelectableTemplateSitewide.onFocusBadgeGoTo', 'Go to');
  }

  @action
  open(): void {
    this.isOpen = true;
  }

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  /** Upstream: Enter in the search opens the popover too. */
  @action
  onSearchKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter') this.isOpen = true;
  }

  @action
  onSearchBlur(event: FocusEvent): void {
    const next = event.relatedTarget as Node | null;

    // moving into the results keeps the popover open
    if (next && this.panel?.contains(next)) return;

    this.isOpen = false;
  }

  /** Upstream `closePopover`: closes, then `popoverProps.closePopover`. */
  @action
  closePopover(): void {
    this.isOpen = false;
    this.popoverProps.closePopover?.();
  }

  @action
  setPanel(panel: HTMLElement | null): void {
    this.panel = panel;
    this.popoverProps.panelRef?.(panel);
  }

  @action
  onChange(options: EuiSelectableOption[]): void {
    this.args.onChange?.(options as EuiSelectableTemplateSitewideOption[]);
  }

  <template>
    <EuiSelectable
      class="euiSelectableTemplateSitewide"
      @options={{this.formattedOptions}}
      @onChange={{this.onChange}}
      @singleSelection={{orDefault @singleSelection true}}
      @searchable={{true}}
      @isLoading={{@isLoading}}
      @isPreFiltered={{@isPreFiltered}}
      @searchProps={{this.searchProps}}
      @css={{this.rootCss}}
      @listProps={{this.listProps}}
      @onActiveOptionChange={{@onActiveOptionChange}}
      @optionMatcher={{@optionMatcher}}
      @height={{@height}}
      @errorMessage={{@errorMessage}}
      @allowExclusions={{@allowExclusions}}
      @selectableScreenReaderText={{@selectableScreenReaderText}}
      @loadingMessage={{this.loadingText}}
      @emptyMessage={{this.noResultsText}}
      @noMatchesMessage={{this.noMatchesText}}
      ...attributes
      as |parts|
    >
      {{#let
        (and2
          (has-block "popoverButton")
          (if
            @popoverButtonBreakpoints
            (CurrentBreakPointHelper @popoverButtonBreakpoints this.breakpoints)
            true
          )
        )
        as |showButton|
      }}
        <ModeProvider
          @colorMode={{this.popoverProviderMode}}
          @parent={{this.themeContext}}
          @wrapper={{false}}
        >
          <EuiPopover
            class={{this.popoverProps.className}}
            @isOpen={{this.isOpen}}
            @closePopover={{this.closePopover}}
            @panelRef={{this.setPanel}}
            @panelPaddingSize={{orDefault this.popoverProps.panelPaddingSize "s"}}
            @anchorPosition={{orDefault this.popoverProps.anchorPosition "downCenter"}}
            @ownFocus={{orDefault this.popoverProps.ownFocus showButton}}
            @display={{orDefault
              this.popoverProps.display
              (if showButton "inlineBlock" "block")
            }}
            @panelCss={{this.panelCss}}
            @anchorClassName={{this.popoverProps.anchorClassName}}
            @attachToAnchor={{this.popoverProps.attachToAnchor}}
            @container={{this.popoverProps.container}}
            @hasArrow={{this.popoverProps.hasArrow}}
            @initialFocus={{this.popoverProps.initialFocus}}
            @insert={{this.popoverProps.insert}}
            @isFocusTrapPaused={{this.popoverProps.isFocusTrapPaused}}
            @focusTrapOptions={{this.popoverProps.focusTrapOptions}}
            @mutationObserverOptions={{this.popoverProps.mutationObserverOptions}}
            @ariaLabel={{this.popoverProps.ariaLabel}}
            @ariaLabelledBy={{this.popoverProps.ariaLabelledBy}}
            @offset={{this.popoverProps.offset}}
            @buffer={{this.popoverProps.buffer}}
            @onTrapDeactivation={{this.popoverProps.onTrapDeactivation}}
            @panelClassName={{this.popoverProps.panelClassName}}
            @panelStyle={{this.popoverProps.panelStyle}}
            @popoverScreenReaderText={{this.popoverProps.popoverScreenReaderText}}
            @portalRef={{this.popoverProps.portalRef}}
            @popoverRef={{this.popoverProps.popoverRef}}
            @buttonRef={{this.popoverProps.buttonRef}}
            @rootCss={{this.popoverProps.rootCss}}
            @css={{this.popoverProps.css}}
            @repositionOnScroll={{this.popoverProps.repositionOnScroll}}
            @repositionToCrossAxis={{this.popoverProps.repositionToCrossAxis}}
            @shouldAccountForOtherPopovers={{this.popoverProps.shouldAccountForOtherPopovers}}
            @shouldSelfFocus={{this.popoverProps.shouldSelfFocus}}
            @tabindex={{this.popoverProps.tabindex}}
            @zIndex={{this.popoverProps.zIndex}}
            @arrowChildren={{this.popoverProps.arrowChildren}}
          >
            <:button>
              {{#if showButton}}
                {{yield this.toggle to="popoverButton"}}
              {{else if parts.search}}
                <ModeProvider
                  @colorMode={{this.searchProviderMode}}
                  @wrapper={{this.searchHasOwnWrapper}}
                >
                  <parts.search
                    aria-label={{this.placeholder}}
                    {{on "focus" this.open}}
                    {{on "input" this.open}}
                    {{on "keydown" this.onSearchKeydown}}
                    {{on "blur" this.onSearchBlur}}
                  />
                </ModeProvider>
              {{/if}}
            </:button>
            <:content>
              <div
                class="euiSelectableTemplateSitewide__popover"
                style={{cssStyle (hash width=this.popoverWidth maxWidth="100%")}}
              >
                {{#if (or2 (has-block "popoverTitle") showButton)}}
                  <EuiPopoverTitle @paddingSize="s">
                    {{yield to="popoverTitle"}}
                    {{#if showButton}}
                      {{#if (has-block "popoverTitle")}}
                        <EuiSpacer />
                      {{/if}}
                      {{#if parts.search}}
                        <parts.search aria-label={{this.placeholder}} />
                      {{/if}}
                    {{/if}}
                  </EuiPopoverTitle>
                {{/if}}
                {{#if @isLoading}}
                  <EuiSelectableMessage style="min-height: 300px;">
                    <EuiLoadingSpinner @size="l" />
                    <br />
                    <p>{{this.loadingText}}</p>
                  </EuiSelectableMessage>
                {{else}}
                  <parts.list
                    class={{this.listClassName}}
                    @messageMinHeight={{300}}
                  >
                    <:option as |option searchValue|>
                      {{#if (has-block "option")}}
                        {{yield (asSitewideOption option) searchValue to="option"}}
                      {{else}}
                        <EuiHighlight
                          class="euiSelectableTemplateSitewide__listItemTitle"
                          @text={{option.label}}
                          @search={{searchValue}}
                        />
                        {{#if (metaOf option)}}
                          <span class={{this.styles.metasList}}>
                            {{#each (metaOf option) as |meta|}}
                              <EuiHighlight
                                class={{this.styles.meta meta}}
                                @text={{meta.text}}
                                @search={{if meta.highlightSearchString searchValue ""}}
                                data-test-subj={{get meta "data-test-subj"}}
                              />
                            {{/each}}
                          </span>
                        {{/if}}
                      {{/if}}
                    </:option>
                    <:optionPrepend as |option|>
                      {{~#let (iconOf option) as |icon|~}}
                        {{~#if icon~}}
                          <EuiIcon
                            @type={{icon.type}}
                            @color={{orDefault icon.color "subdued"}}
                            @size={{orDefault icon.size "l"}}
                            @title={{icon.title}}
                          />
                        {{~else~}}
                          {{option.prepend}}
                        {{~/if~}}
                      {{~/let~}}
                    </:optionPrepend>
                    <:optionAppend as |option|>
                      {{~#let (avatarOf option) as |avatar|~}}
                        {{~#if avatar~}}
                          <EuiAvatar
                            @name={{avatar.name}}
                            @type={{orDefault avatar.type "space"}}
                            @color={{avatar.color}}
                            @size={{orDefault avatar.size "s"}}
                            @imageUrl={{avatar.imageUrl}}
                            @initials={{avatar.initials}}
                            @iconType={{avatar.iconType}}
                            @iconSize={{avatar.iconSize}}
                            @iconColor={{avatar.iconColor}}
                            @isDisabled={{avatar.isDisabled}}
                            @casing={{avatar.casing}}
                          />
                        {{~else~}}
                          {{option.append}}
                        {{~/if~}}
                      {{~/let~}}
                    </:optionAppend>
                  </parts.list>
                {{/if}}
                {{#if (has-block "popoverFooter")}}
                  <EuiPopoverFooter @paddingSize="s">
                    {{yield to="popoverFooter"}}
                  </EuiPopoverFooter>
                {{/if}}
              </div>
            </:content>
          </EuiPopover>
        </ModeProvider>
      {{/let}}
    </EuiSelectable>
  </template>
}

function and2(a: unknown, b: unknown): boolean {
  return Boolean(a && b);
}

function orDefault<T>(value: T | undefined, fallback: T): T {
  return value === undefined ? fallback : value;
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function asSitewideOption(option: EuiSelectableOption): EuiSelectableTemplateSitewideOption {
  return option as EuiSelectableTemplateSitewideOption;
}

function metaOf(option: EuiSelectableOption): EuiSelectableTemplateSitewideMeta[] | undefined {
  const meta = (option as EuiSelectableTemplateSitewideOption).meta;

  return meta?.length ? meta : undefined;
}

function iconOf(option: EuiSelectableOption): EuiSelectableTemplateSitewideOption['icon'] {
  return (option as EuiSelectableTemplateSitewideOption).icon;
}

function avatarOf(option: EuiSelectableOption): EuiSelectableTemplateSitewideOption['avatar'] {
  return (option as EuiSelectableTemplateSitewideOption).avatar;
}
