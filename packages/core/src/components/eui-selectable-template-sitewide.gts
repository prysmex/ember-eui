import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import cssStyle from '../-private/css-style.ts';
import EuiAvatar from './eui-avatar.gts';
import EuiHighlight from './eui-highlight.gts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';
import EuiPopover from './eui-popover.gts';
import EuiPopoverFooter from './eui-popover-footer.gts';
import EuiPopoverTitle from './eui-popover-title.gts';
import EuiSelectable from './eui-selectable.gts';
import EuiSpacer from './eui-spacer.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiSelectableOption } from '../-private/selectable-options.ts';
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
}

export interface EuiSelectableTemplateSitewideOption extends EuiSelectableOption {
  /** Icon before the label: `{ type, color }` (subdued by default). */
  icon?: { type: EuiIconSignature['Args']['type']; color?: EuiIconSignature['Args']['color'] };
  /** Avatar after the label, e.g. the space it belongs to: `{ name, type, color }`. */
  avatar?: {
    name: string;
    type?: EuiAvatarSignature['Args']['type'];
    color?: EuiAvatarSignature['Args']['color'];
  };
  /** Details under the label, e.g. its type and where it lives. */
  meta?: EuiSelectableTemplateSitewideMeta[];
}

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
    /** Placeholder of the search. Defaults to "Search for anything...". */
    placeholder?: string;
    /** Width of the popover in px. Defaults to `600`. */
    popoverWidth?: number;
    /**
     * The results are already filtered (e.g. by a server), so the search
     * does not filter them again. Defaults to `false`.
     */
    isPreFiltered?: boolean;
  };
  Blocks: {
    /**
     * A button opening the popover (the search moves into it), e.g. an
     * icon in a narrow header; yields the function toggling it.
     */
    popoverButton: [toggle: () => void];
    /** Content above the results, e.g. a title. */
    popoverTitle: [];
    /** Content below the results, e.g. keyboard shortcuts. */
    popoverFooter: [];
  };
}

function metaClass(meta: EuiSelectableTemplateSitewideMeta): string {
  return meta.type
    ? `euiSelectableTemplateSitewide__optionMeta euiSelectableTemplateSitewide__optionMeta--${meta.type}`
    : 'euiSelectableTemplateSitewide__optionMeta';
}

export default class EuiSelectableTemplateSitewide extends Component<EuiSelectableTemplateSitewideSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;

  get formattedOptions(): EuiSelectableTemplateSitewideOption[] {
    return this.args.options.map((option) => ({
      key: option.label,
      ...option,
      className: ['euiSelectableTemplateSitewide__listItem', option.className]
        .filter(Boolean)
        .join(' ')
    }));
  }

  get placeholder(): string {
    return (
      this.args.placeholder ??
      this.euiI18n.lookupToken(
        'euiSelectableTemplateSitewide.searchPlaceholder',
        'Search for anything...'
      )
    );
  }

  get loadingText(): string {
    return this.euiI18n.lookupToken('euiSelectableTemplateSitewide.loadingResults', 'Loading results');
  }

  get noResultsText(): string {
    return this.euiI18n.lookupToken('euiSelectableTemplateSitewide.noResults', 'No results available');
  }

  get goTo(): string {
    return this.euiI18n.lookupToken('euiSelectableTemplateSitewide.onFocusBadgeGoTo', 'Go to');
  }

  @action
  open(): void {
    this.isOpen = true;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  onSearchBlur(event: FocusEvent): void {
    const next = event.relatedTarget as Node | null;
    const panel = (event.currentTarget as HTMLElement)
      .closest('.euiSelectableTemplateSitewide')
      ?.querySelector('.euiSelectableTemplateSitewide__popover');

    // moving into the results keeps the popover open
    if (next && panel?.contains(next)) return;
    if (next && document.querySelector('.euiPopover__panel')?.contains(next)) return;

    this.isOpen = false;
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
      @singleSelection={{true}}
      @searchable={{true}}
      @isLoading={{@isLoading}}
      @isPreFiltered={{@isPreFiltered}}
      @searchProps={{hash placeholder=this.placeholder onSearch=@onSearch}}
      @listProps={{hash
        rowHeight=68
        showIcons=false
        onFocusBadge=(hash text=this.goTo iconSide="right")
      }}
      @loadingMessage={{this.loadingText}}
      @emptyMessage={{this.noResultsText}}
      @noMatchesMessage={{this.noResultsText}}
      ...attributes
      as |parts|
    >
      <EuiPopover
        @isOpen={{this.isOpen}}
        @closePopover={{this.close}}
        @panelPaddingSize="none"
        @ownFocus={{if (has-block "popoverButton") true false}}
        @display={{if (has-block "popoverButton") "inlineBlock" "block"}}
      >
        <:button>
          {{#if (has-block "popoverButton")}}
            {{yield this.toggle to="popoverButton"}}
          {{else if parts.search}}
            <parts.search
              class="euiSelectableTemplateSitewide__search"
              aria-label={{this.placeholder}}
              {{on "focus" this.open}}
              {{on "input" this.open}}
              {{on "blur" this.onSearchBlur}}
            />
          {{/if}}
        </:button>
        <:content>
          <div
            class="euiSelectableTemplateSitewide__popover"
            style={{cssStyle
              (hash
                width=(if @popoverWidth @popoverWidth 600) maxWidth="100%"
              )
            }}
          >
            {{#if (or2 (has-block "popoverTitle") (has-block "popoverButton"))}}
              <EuiPopoverTitle @paddingSize="s">
                {{yield to="popoverTitle"}}
                {{#if (has-block "popoverButton")}}
                  {{#if (has-block "popoverTitle")}}
                    <EuiSpacer />
                  {{/if}}
                  {{#if parts.search}}
                    <parts.search
                      class="euiSelectableTemplateSitewide__search"
                      aria-label={{this.placeholder}}
                    />
                  {{/if}}
                {{/if}}
              </EuiPopoverTitle>
            {{/if}}
            {{#if @isLoading}}
              <div
                class="euiText euiText--extraSmall euiSelectableMessage"
                style="min-height: 300px;"
              >
                <EuiLoadingSpinner @size="l" />
                <br />
                <p>{{this.loadingText}}</p>
              </div>
            {{else}}
              <parts.list class="euiSelectableTemplateSitewide__list">
                <:option as |option searchValue|>
                  <EuiHighlight
                    class="euiSelectableTemplateSitewide__listItemTitle"
                    @text={{option.label}}
                    @search={{searchValue}}
                  />
                  {{#if (metaOf option)}}
                    <span class="euiSelectableTemplateSitewide__optionMetasList">
                      {{#each (metaOf option) as |meta|}}
                        <EuiHighlight
                          class={{metaClass meta}}
                          @text={{meta.text}}
                          @search={{if meta.highlightSearchString searchValue ""}}
                        />
                      {{/each}}
                    </span>
                  {{/if}}
                </:option>
                <:optionPrepend as |option|>
                  {{~#let (iconOf option) as |icon|~}}
                    {{~#if icon~}}
                      <EuiIcon
                        @type={{icon.type}}
                        @color={{if icon.color icon.color "subdued"}}
                        @size="l"
                      />
                    {{~/if~}}
                  {{~/let~}}
                </:optionPrepend>
                <:optionAppend as |option|>
                  {{~#let (avatarOf option) as |avatar|~}}
                    {{~#if avatar~}}
                      <EuiAvatar
                        @name={{avatar.name}}
                        @type={{if avatar.type avatar.type "space"}}
                        @color={{avatar.color}}
                        @size="s"
                      />
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
    </EuiSelectable>
  </template>
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
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
