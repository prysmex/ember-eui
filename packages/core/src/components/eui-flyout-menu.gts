import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiFlyoutMenuStyles } from '../utils/eui/flyout-menu.ts';
import { euiFlyoutCloseButtonStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiListGroup from './eui-list-group.gts';
import EuiListGroupItem from './eui-list-group-item.gts';
import EuiPopover from './eui-popover.gts';
import { euiScreenReaderOnlyClass } from './eui-screen-reader-only.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';
import EuiToolTip from './eui-tool-tip.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiIconSignature } from './eui-icon.gts';
import type { EuiTooltipArgs } from './eui-tool-tip.gts';
import type { TOC } from '@ember/component/template-only';

/** Upstream `MIN_HISTORY_ITEMS`: the history popover needs at least two items. */
const MIN_HISTORY_ITEMS = 2;

type IconType = EuiIconSignature['Args']['type'];

/** An entry of the history popover. */
export interface EuiFlyoutHistoryItem {
  /** The text of the entry. */
  title: string;
  /** An icon next to the title. */
  iconType?: IconType;
  /** Called when the entry is chosen. */
  onClick: () => void;
}

/**
 * An icon button of the menu bar. The menu sets its color, size and display
 * itself so every action looks the same.
 */
export interface EuiFlyoutMenuAction {
  /** The icon of the button. */
  iconType: IconType;
  /** Accessible label of the button (required, there is no visible text). */
  ariaLabel: string;
  /** Called when the button is clicked. */
  onClick?: (event: MouseEvent) => void;
  /** Makes the button a link. */
  href?: string;
  /** `target` of the `href` link. */
  target?: string;
  /** Disables the button. */
  isDisabled?: boolean;
  /** Tooltip text shown on hover or focus. */
  toolTipContent?: string;
  /** Options of the tooltip, used with `toolTipContent`. */
  toolTipProps?: Pick<EuiTooltipArgs, 'position' | 'title' | 'delay'>;
  /** The `data-test-subj` of the button. */
  dataTestSubj?: string;
}

/** Deprecated custom action; use `trailingActions`. */
export interface EuiFlyoutMenuCustomAction {
  iconType: IconType;
  onClick: () => void;
  ariaLabel: string;
  dataTestSubj?: string;
}

/** Props of the back button. */
export interface EuiFlyoutMenuBackButtonProps {
  /** Called when the button is clicked. */
  onClick?: (event: MouseEvent) => void;
  /** Disables the button. */
  isDisabled?: boolean;
  /** Replaces the "Back" label. */
  ariaLabel?: string;
  /** The `data-test-subj` of the button. Defaults to `euiFlyoutMenuBackButton`. */
  dataTestSubj?: string;
}

/** Previous/next navigation with a position counter. */
export interface EuiFlyoutMenuPagination {
  /** Zero-based index of the current item. */
  currentIndex: number;
  /** Total number of items. */
  total: number;
  /** Called by the Previous button. */
  onPrevious: () => void;
  /** Called by the Next button. */
  onNext: () => void;
  /** Called by the First button, to jump to the beginning. */
  onFirst?: () => void;
  /** Called by the Last button, to jump to the end. */
  onLast?: () => void;
}

/**
 * The top menu bar of a flyout: a back button or history, pagination, a
 * title and icon actions, with the flyout's close button at the end. Place
 * it first inside an `EuiFlyout`. Upstream's `EuiFlyoutMenu`.
 */
export interface EuiFlyoutMenuSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Title of the menu. Hidden from view by default (see `@hideTitle`) but
     * still read by screen readers.
     */
    title?: string;
    /** Id of the title element, e.g. for the flyout's `aria-labelledby`. */
    titleId?: string;
    /**
     * Hides the title visually. Defaults to `true`.
     * @deprecated Use `EuiFlyoutHeader` for visible titles.
     */
    hideTitle?: boolean;
    /** Hides the close button. Defaults to `false`. */
    hideCloseButton?: boolean;
    /** Called by the close button. Without it the button does nothing. */
    onClose?: (event: MouseEvent) => void;
    /** Shows a back button. Defaults to `false`. */
    showBackButton?: boolean;
    /** Options of the back button, such as `onClick`. */
    backButtonProps?: EuiFlyoutMenuBackButtonProps;
    /**
     * Entries of the history popover, most recent first: index 0 is where the
     * back button goes. Shown from two entries.
     */
    historyItems?: EuiFlyoutHistoryItem[];
    /** Actions at the inline start of the bar. */
    leadingActions?: EuiFlyoutMenuAction[];
    /** Actions at the inline end of the bar. */
    trailingActions?: EuiFlyoutMenuAction[];
    /**
     * @deprecated Use `@trailingActions`, which takes precedence when both
     * are set.
     */
    customActions?: EuiFlyoutMenuCustomAction[];
    /**
     * Previous/next controls and a counter. They replace the back button and
     * history.
     */
    pagination?: EuiFlyoutMenuPagination;
    /** Extra styles composed last into the menu's class. */
    css?: EuiCss;
  };
}

export default class EuiFlyoutMenu extends Component<EuiFlyoutMenuSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isHistoryOpen = false;

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiFlyoutMenuStyles);
  }

  @cached
  get containerClass(): string {
    return `euiFlyoutMenu ${euiClass(
      this.context,
      { boxSizing: 'border-box' },
      this.styles.euiFlyoutMenu__container,
      this.args.css
    )}`;
  }

  @cached
  get screenReaderClass(): string {
    return euiScreenReaderOnlyClass(this.context);
  }

  /** The close button: upstream's inside close button of the flyout. */
  @cached
  get closeButtonCss() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiFlyoutCloseButtonStyles
    );

    return [styles.euiFlyout__closeButton, styles.inside];
  }

  get hideTitle(): boolean {
    return this.args.hideTitle ?? true;
  }

  get titleCss(): EuiCss {
    return this.hideTitle ? this.styles.euiFlyoutMenu__hiddenTitle : undefined;
  }

  get showPagination(): boolean {
    return (this.args.pagination?.total ?? 0) >= 1;
  }

  get historyItems(): EuiFlyoutHistoryItem[] {
    return this.args.historyItems ?? [];
  }

  get hasBackButton(): boolean {
    return !this.showPagination && Boolean(this.args.showBackButton);
  }

  get hasHistory(): boolean {
    return !this.showPagination && this.historyItems.length >= MIN_HISTORY_ITEMS;
  }

  get leadingActions(): EuiFlyoutMenuAction[] {
    return this.args.leadingActions ?? [];
  }

  /** `@trailingActions` takes precedence over the deprecated `@customActions`. */
  get trailingActions(): EuiFlyoutMenuAction[] {
    return this.args.trailingActions ?? this.args.customActions ?? [];
  }

  get showBackHistoryDivider(): boolean {
    return this.hasBackButton && this.hasHistory;
  }

  get showLeadingBoundaryDivider(): boolean {
    return (
      (this.showPagination || this.hasBackButton || this.hasHistory) &&
      this.leadingActions.length > 0
    );
  }

  get showTrailingCloseDivider(): boolean {
    return this.trailingActions.length > 0 && !this.args.hideCloseButton;
  }

  get spacerCss(): EuiCss {
    return this.showTrailingCloseDivider
      ? [this.styles.euiFlyoutMenu__spacer, this.styles.euiFlyoutMenu__divider]
      : this.styles.euiFlyoutMenu__spacer;
  }

  get previousPageTitle(): string {
    return this.historyItems[0]?.title ?? '';
  }

  // i18n: the menu owns the `euiFlyoutMenu.*` tokens

  t = (token: string, text: string, values?: Record<string, unknown>) =>
    this.euiI18n.lookupToken(token, text, values);

  get backLabel(): string {
    return this.args.backButtonProps?.ariaLabel ?? this.t('euiFlyoutMenu.back', 'Back');
  }

  get backTooltip(): string {
    return this.t('euiFlyoutMenu.back.tooltip', 'Back to {previousPage}', {
      previousPage: this.previousPageTitle
    });
  }

  get historyLabel(): string {
    return this.t('euiFlyoutMenu.history', 'History');
  }

  get recentlyVisitedLabel(): string {
    return this.t('euiFlyoutMenu.history.tooltip', 'Recently visited');
  }

  get closeLabel(): string {
    return this.t('euiFlyoutCloseButton.ariaLabel', 'Close this dialog');
  }

  get paginationLabels() {
    const { currentIndex = 0, total = 0 } = this.args.pagination ?? {};

    return {
      first: this.t('euiFlyoutMenu.pagination.first', 'First'),
      previous: this.t('euiFlyoutMenu.pagination.previous', 'Previous'),
      next: this.t('euiFlyoutMenu.pagination.next', 'Next'),
      last: this.t('euiFlyoutMenu.pagination.last', 'Last'),
      counter: this.t('euiFlyoutMenu.pagination.counter', '{position} of {total}', {
        position: currentIndex + 1,
        total
      })
    };
  }

  /** Jump controls make the Previous/Next chevrons horizontal (upstream). */
  get hasJumpControls(): boolean {
    return Boolean(this.args.pagination?.onFirst || this.args.pagination?.onLast);
  }

  get previousIcon(): IconType {
    return this.hasJumpControls ? 'chevronSingleLeft' : 'chevronSingleUp';
  }

  get nextIcon(): IconType {
    return this.hasJumpControls ? 'chevronSingleRight' : 'chevronSingleDown';
  }

  get isAtStart(): boolean {
    return this.args.pagination?.currentIndex === 0;
  }

  get isAtEnd(): boolean {
    const pagination = this.args.pagination;

    return pagination
      ? pagination.currentIndex === pagination.total - 1
      : false;
  }

  @action
  onBackClick(event: MouseEvent): void {
    this.args.backButtonProps?.onClick?.(event);
  }

  @action
  onCloseClick(event: MouseEvent): void {
    this.args.onClose?.(event);
  }

  @action
  toggleHistory(): void {
    this.isHistoryOpen = !this.isHistoryOpen;
  }

  @action
  closeHistory(): void {
    this.isHistoryOpen = false;
  }

  @action
  chooseHistoryItem(item: EuiFlyoutHistoryItem): void {
    item.onClick();
    this.isHistoryOpen = false;
  }

  <template>
    <div
      class={{this.containerClass}}
      data-test-subj="euiFlyoutMenu"
      ...attributes
    >
      <EuiFlexGroup
        @alignItems="center"
        @justifyContent="spaceBetween"
        @gutterSize="none"
        @responsive={{false}}
        @css={{this.styles.euiFlyoutMenu__controls}}
      >
        {{#if this.showPagination}}
          <EuiFlexItem @grow={{false}}>
            <EuiFlexGroup
              @gutterSize="xs"
              @alignItems="center"
              @responsive={{false}}
            >
              {{#if @pagination.onFirst}}
                <EuiFlexItem @grow={{false}}>
                  <PaginationButton
                    @iconType="chevronLimitLeft"
                    @label={{this.paginationLabels.first}}
                    @onClick={{@pagination.onFirst}}
                    @isDisabled={{this.isAtStart}}
                    @dataTestSubj="euiFlyoutMenuPaginationFirst"
                  />
                </EuiFlexItem>
              {{/if}}
              <EuiFlexItem @grow={{false}}>
                <PaginationButton
                  @iconType={{this.previousIcon}}
                  @label={{this.paginationLabels.previous}}
                  @onClick={{@pagination.onPrevious}}
                  @isDisabled={{this.isAtStart}}
                  @dataTestSubj="euiFlyoutMenuPaginationPrev"
                />
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <EuiText
                  @size="s"
                  @css={{this.styles.euiFlyoutMenu__paginationCounter}}
                  aria-hidden="true"
                >{{this.paginationLabels.counter}}</EuiText>
                <div
                  role="status"
                  aria-live="polite"
                  aria-atomic="true"
                  class={{this.screenReaderClass}}
                >{{this.paginationLabels.counter}}</div>
              </EuiFlexItem>
              <EuiFlexItem @grow={{false}}>
                <PaginationButton
                  @iconType={{this.nextIcon}}
                  @label={{this.paginationLabels.next}}
                  @onClick={{@pagination.onNext}}
                  @isDisabled={{this.isAtEnd}}
                  @dataTestSubj="euiFlyoutMenuPaginationNext"
                />
              </EuiFlexItem>
              {{#if @pagination.onLast}}
                <EuiFlexItem @grow={{false}}>
                  <PaginationButton
                    @iconType="chevronLimitRight"
                    @label={{this.paginationLabels.last}}
                    @onClick={{@pagination.onLast}}
                    @isDisabled={{this.isAtEnd}}
                    @dataTestSubj="euiFlyoutMenuPaginationLast"
                  />
                </EuiFlexItem>
              {{/if}}
            </EuiFlexGroup>
          </EuiFlexItem>
        {{else}}
          {{#if this.hasBackButton}}
            <EuiFlexItem @grow={{false}}>
              {{#if this.previousPageTitle}}
                <EuiToolTip @content={{this.backTooltip}}>
                  <BackButton @menu={{this}} />
                </EuiToolTip>
              {{else}}
                <BackButton @menu={{this}} />
              {{/if}}
            </EuiFlexItem>
          {{/if}}
          {{#if this.showBackHistoryDivider}}
            <EuiFlexItem
              @grow={{false}}
              @css={{this.styles.euiFlyoutMenu__divider}}
              class="euiFlyoutMenu__divider"
              aria-hidden="true"
            />
          {{/if}}
          {{#if this.hasHistory}}
            <EuiFlexItem @grow={{false}}>
              <EuiPopover
                @isOpen={{this.isHistoryOpen}}
                @closePopover={{this.closeHistory}}
                @ariaLabel={{this.historyLabel}}
                @panelPaddingSize="xs"
                @anchorPosition="downLeft"
              >
                <:button>
                  <EuiToolTip
                    @content={{this.recentlyVisitedLabel}}
                    @disableScreenReaderOutput={{true}}
                  >
                    <EuiButtonIcon
                      @iconType="clockCounter"
                      @color="text"
                      aria-label={{this.historyLabel}}
                      data-test-subj="euiFlyoutMenuHistoryButton"
                      {{on "click" this.toggleHistory}}
                    />
                  </EuiToolTip>
                </:button>
                <:content>
                  <EuiListGroup>
                    {{#each this.historyItems as |item index|}}
                      <EuiListGroupItem
                        @label={{item.title}}
                        @iconType={{item.iconType}}
                        @onClick={{fn this.chooseHistoryItem item}}
                        data-test-subj="euiFlyoutMenuHistoryItem-{{index}}"
                      />
                    {{/each}}
                  </EuiListGroup>
                </:content>
              </EuiPopover>
            </EuiFlexItem>
          {{/if}}
        {{/if}}

        {{#if this.showLeadingBoundaryDivider}}
          <EuiFlexItem
            @grow={{false}}
            @css={{this.styles.euiFlyoutMenu__divider}}
            class="euiFlyoutMenu__divider"
            aria-hidden="true"
          />
        {{/if}}

        {{#if this.leadingActions.length}}
          <EuiFlexItem
            @grow={{false}}
            @css={{this.styles.euiFlyoutMenu__actions}}
          >
            <EuiFlexGroup
              @gutterSize="s"
              @alignItems="center"
              @responsive={{false}}
            >
              {{#each this.leadingActions as |item|}}
                <EuiFlexItem @grow={{false}}>
                  <MenuActionButton @action={{item}} />
                </EuiFlexItem>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
        {{/if}}

        {{#if @title}}
          <EuiFlexItem @grow={{false}}>
            <EuiTitle
              @tagName="h3"
              @size="xxs"
              @css={{this.titleCss}}
              id={{@titleId}}
            >{{@title}}</EuiTitle>
          </EuiFlexItem>
        {{/if}}

        <EuiFlexItem @grow={{true}} />

        {{#if this.trailingActions.length}}
          <EuiFlexItem
            @grow={{false}}
            @css={{this.styles.euiFlyoutMenu__actions}}
          >
            <EuiFlexGroup
              @gutterSize="s"
              @alignItems="center"
              @responsive={{false}}
            >
              {{#each this.trailingActions as |item|}}
                <EuiFlexItem @grow={{false}}>
                  <MenuActionButton @action={{item}} />
                </EuiFlexItem>
              {{/each}}
            </EuiFlexGroup>
          </EuiFlexItem>
        {{/if}}

        {{#unless @hideCloseButton}}
          {{! gives the actions room around the absolutely positioned close button; doubles as the divider }}
          <EuiFlexItem
            @grow={{false}}
            @css={{this.spacerCss}}
            class={{if this.showTrailingCloseDivider "euiFlyoutMenu__divider"}}
            aria-hidden={{if this.showTrailingCloseDivider "true"}}
          />
        {{/unless}}
      </EuiFlexGroup>

      {{#unless @hideCloseButton}}
        <EuiButtonIcon
          @display="empty"
          @iconType="cross"
          @color="text"
          @css={{this.closeButtonCss}}
          class="euiFlyout__closeButton"
          aria-label={{this.closeLabel}}
          data-test-subj="euiFlyoutCloseButton"
          {{on "click" this.onCloseClick}}
        />
      {{/unless}}
    </div>
  </template>
}

const BackButton: TOC<{ Args: { menu: EuiFlyoutMenu } }> = <template>
  <EuiButtonEmpty
    @size="xs"
    @color="text"
    @iconType="undo"
    @isDisabled={{@menu.args.backButtonProps.isDisabled}}
    data-test-subj={{if
      @menu.args.backButtonProps.dataTestSubj
      @menu.args.backButtonProps.dataTestSubj
      "euiFlyoutMenuBackButton"
    }}
    {{on "click" @menu.onBackClick}}
  >{{@menu.backLabel}}</EuiButtonEmpty>
</template>;

/** The menu bar sets color, size and display itself so every action looks the same. */
const MenuActionButton: TOC<{
  Args: { action: EuiFlyoutMenuAction };
}> = <template>
  {{#if @action.toolTipContent}}
    <EuiToolTip
      @content={{@action.toolTipContent}}
      @position={{@action.toolTipProps.position}}
      @title={{@action.toolTipProps.title}}
      @delay={{@action.toolTipProps.delay}}
      @disableScreenReaderOutput={{true}}
    >
      <EuiButtonIcon
        @iconType={{@action.iconType}}
        @href={{@action.href}}
        @target={{@action.target}}
        @isDisabled={{@action.isDisabled}}
        @color="text"
        @size="xs"
        @display="empty"
        @iconSize="m"
        aria-label={{@action.ariaLabel}}
        data-test-subj={{@action.dataTestSubj}}
        {{on "click" (optional @action.onClick)}}
      />
    </EuiToolTip>
  {{else}}
    <EuiButtonIcon
      @iconType={{@action.iconType}}
      @href={{@action.href}}
      @target={{@action.target}}
      @isDisabled={{@action.isDisabled}}
      @color="text"
      @size="xs"
      @display="empty"
      @iconSize="m"
      aria-label={{@action.ariaLabel}}
      data-test-subj={{@action.dataTestSubj}}
      {{on "click" (optional @action.onClick)}}
    />
  {{/if}}
</template>;

/** A disabled pagination button has no tooltip, like upstream. */
const PaginationButton: TOC<{
  Args: {
    iconType: IconType;
    label: string;
    onClick?: () => void;
    isDisabled: boolean;
    dataTestSubj: string;
  };
}> = <template>
  {{#if @isDisabled}}
    <EuiButtonIcon
      @iconType={{@iconType}}
      @color="text"
      @size="xs"
      @isDisabled={{true}}
      aria-label={{@label}}
      data-test-subj={{@dataTestSubj}}
    />
  {{else}}
    <EuiToolTip @content={{@label}} @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon
        @iconType={{@iconType}}
        @color="text"
        @size="xs"
        aria-label={{@label}}
        data-test-subj={{@dataTestSubj}}
        {{on "click" (optional @onClick)}}
      />
    </EuiToolTip>
  {{/if}}
</template>;
