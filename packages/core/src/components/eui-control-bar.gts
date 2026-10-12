import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn, get } from '@ember/helper';
import { on } from '@ember/modifier';
import { deprecate } from '@ember/debug';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiControlBarPageStyles,
  euiControlBarStyles
} from '../utils/eui/control-bar.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';
import EuiButton from './eui-button.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiEmotionProvider from './eui-emotion-provider.gts';
import EuiIcon from './eui-icon.gts';
import EuiPortal from './eui-portal.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiColorMode } from '../utils/emotion/theme.ts';
import type { EuiBreadcrumb } from './eui-breadcrumbs';
import type { EuiIconSignature } from './eui-icon';
import type Owner from '@ember/owner';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A control in the bar; `controlType` decides which. */
export type EuiControlBarControl =
  | {
      controlType: 'button';
      id: string;
      label: string;
      onClick?: (event: MouseEvent) => void;
      href?: string;
      /** Any `EuiButton` color. Defaults to `'ghost'`. */
      color?: string;
      iconType?: EuiIconSignature['Args']['type'];
      isDisabled?: boolean;
      className?: string;
    }
  | {
      controlType: 'icon';
      id: string;
      iconType: EuiIconSignature['Args']['type'];
      /** Makes it a button (with `href`, a link); otherwise a plain icon. */
      onClick?: (event: MouseEvent) => void;
      href?: string;
      /** Accessible label; needed for icon buttons. */
      'aria-label'?: string;
      /** Any `EuiButtonIcon` color. Defaults to `'ghost'`. */
      color?:
        | 'primary'
        | 'accent'
        | 'success'
        | 'warning'
        | 'danger'
        | 'ghost'
        | 'text';
      className?: string;
    }
  | {
      controlType: 'tab';
      id: string;
      label: string;
      /** Usually toggles `@showContent` and shows this tab's content. */
      onClick: (event: MouseEvent) => void;
      className?: string;
    }
  | { controlType: 'text'; id: string; text: string; className?: string }
  | { controlType: 'breadcrumbs'; id: string; breadcrumbs: EuiBreadcrumb[] }
  | { controlType: 'divider' }
  | { controlType: 'spacer' };

export interface EuiControlBarArgs {
  /** The controls, from left to right. */
  controls: EuiControlBarControl[];
  /** Shows the content (the default block) above the controls. */
  showContent?: boolean;
  /** Height of the content area: `'s'`, `'m'` or `'l'`. Defaults to `'l'`. */
  size?: 's' | 'm' | 'l';
  /**
   * `'fixed'` (bottom of the window, rendered at the end of `<body>`),
   * `'absolute'` or `'relative'` (inside a positioned container).
   * Defaults to `'fixed'`.
   */
  position?: 'fixed' | 'absolute' | 'relative';
  /** Space on the left, e.g. for a side navigation. Defaults to `0`. */
  leftOffset?: number | string;
  /** Space on the right. Defaults to `0`. */
  rightOffset?: number | string;
  /** Maximum height of the bar with its content. */
  maxHeight?: number | string;
  /** Keeps the bar on small screens (hidden below the `m` breakpoint by default). */
  showOnMobile?: boolean;
  /** Class added to `<body>` while a fixed bar is shown. */
  bodyClassName?: string;
  /** Accessible name of the bar's region. Defaults to "Page level controls". */
  landmarkHeading?: string;
}

/**
 * A dark bar of controls at the bottom of the page (or of a container),
 * e.g. an editor's toolbar or a code console: buttons, icons, text,
 * breadcrumbs and tabs that open a content area above it.
 */
export interface EuiControlBarSignature {
  Element: HTMLElement;
  Args: EuiControlBarArgs;
  Blocks: {
    /** Content shown above the controls while `@showContent`. */
    default: [];
  };
}

type BarStyles = ReturnType<typeof euiControlBarStyles>;
type PageStyles = ReturnType<typeof euiControlBarPageStyles>;

/**
 * @deprecated Removed from upstream EUI (after 91.3.1); will be removed in
 * the next major version. Use EuiBottomBar instead.
 *
 * EuiControlBar on Borealis tokens. Upstream removed the component after
 * EUI 91.3.1; its last Sass styles are translated in
 * `utils/eui/control-bar.ts`. As upstream, the bar renders in a nested dark
 * provider; the content area renders in the surrounding color mode.
 */
export default class EuiControlBar extends Component<EuiControlBarSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked selectedTab?: string;

  constructor(owner: Owner, args: EuiControlBarArgs) {
    super(owner, args);
    deprecate(
      'EuiControlBar was removed from upstream Elastic UI (after EUI 91.3.1) and will be removed from @ember-eui/core in the next major version. Use EuiBottomBar, or compose your own bar with EuiFlexGroup and EuiTabs.',
      false,
      {
        id: 'ember-eui.eui-control-bar.removed-upstream',
        until: '15.0.0',
        for: '@ember-eui/core',
        since: { available: '14.2.0', enabled: '14.2.0' }
      }
    );
  }

  get position(): 'fixed' | 'absolute' | 'relative' {
    return this.args.position ?? 'fixed';
  }

  get isFixed(): boolean {
    return this.position === 'fixed';
  }

  get heading(): string {
    return (
      this.args.landmarkHeading ??
      this.euiI18n.lookupToken(
        'euiControlBar.screenReaderHeading',
        'Page level controls'
      )
    );
  }

  get announcement(): string {
    return this.args.landmarkHeading
      ? this.euiI18n.lookupToken(
          'euiControlBar.customScreenReaderAnnouncement',
          'There is a new region landmark called {landmarkHeading} with page level controls at the end of the document.',
          { landmarkHeading: this.args.landmarkHeading }
        )
      : this.euiI18n.lookupToken(
          'euiControlBar.screenReaderAnnouncement',
          'There is a new region landmark with page level controls at the end of the document.'
        );
  }

  /** The surrounding (page) color mode, for the content area. */
  get pageColorMode(): EuiColorMode {
    return getEuiThemeContext(this).colorMode;
  }

  /** Content area, active tab and flicker guard use the page theme. */
  @cached
  get pageStyles(): PageStyles {
    return useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiControlBarPageStyles
    );
  }

  @action
  onTabClick(
    control: { id: string; onClick: (event: MouseEvent) => void },
    event: MouseEvent
  ): void {
    this.selectedTab = control.id;
    control.onClick(event);
  }

  <template>
    {{#if this.isFixed}}
      <EuiPortal>
        <EuiEmotionProvider
          @colorMode="dark"
          @wrapper={{false}}
          @globalStyles={{false}}
        >
          {{! template-lint-disable no-duplicate-landmark-elements }}
          <ControlBarSection
            @controls={{@controls}}
            @showContent={{@showContent}}
            @size={{@size}}
            @showOnMobile={{@showOnMobile}}
            @leftOffset={{@leftOffset}}
            @rightOffset={{@rightOffset}}
            @maxHeight={{@maxHeight}}
            @bodyClassName={{@bodyClassName}}
            @position={{this.position}}
            @heading={{this.heading}}
            @selectedTab={{this.selectedTab}}
            @pageStyles={{this.pageStyles}}
            @pageColorMode={{this.pageColorMode}}
            @onTabClick={{this.onTabClick}}
            ...attributes
          >{{yield}}</ControlBarSection>
        </EuiEmotionProvider>
        <EuiScreenReaderOnly>
          <p aria-live="assertive">{{this.announcement}}</p>
        </EuiScreenReaderOnly>
      </EuiPortal>
    {{else}}
      <EuiEmotionProvider
        @colorMode="dark"
        @wrapper={{false}}
        @globalStyles={{false}}
      >
        <ControlBarSection
          @controls={{@controls}}
          @showContent={{@showContent}}
          @size={{@size}}
          @showOnMobile={{@showOnMobile}}
          @leftOffset={{@leftOffset}}
          @rightOffset={{@rightOffset}}
          @maxHeight={{@maxHeight}}
          @bodyClassName={{@bodyClassName}}
          @position={{this.position}}
          @heading={{this.heading}}
          @selectedTab={{this.selectedTab}}
          @pageStyles={{this.pageStyles}}
          @pageColorMode={{this.pageColorMode}}
          @onTabClick={{this.onTabClick}}
          ...attributes
        >{{yield}}</ControlBarSection>
      </EuiEmotionProvider>
    {{/if}}
  </template>
}

interface ControlBarSectionSignature {
  Element: HTMLElement;
  Args: Omit<EuiControlBarArgs, 'position'> & {
    position: 'fixed' | 'absolute' | 'relative';
    heading: string;
    selectedTab?: string;
    pageStyles: PageStyles;
    pageColorMode: EuiColorMode;
    onTabClick: (
      control: { id: string; onClick: (event: MouseEvent) => void },
      event: MouseEvent
    ) => void;
  };
  Blocks: { default: [] };
}

/** A fixed bar pads the bottom of `<body>` by its height while shown. */
const padBody = modifier(
  (
    controls: HTMLElement,
    [isFixed, bodyClassName]: [boolean, string | undefined]
  ) => {
    if (!isFixed) return;

    document.body.style.paddingBottom = `${controls.clientHeight}px`;
    if (bodyClassName) document.body.classList.add(bodyClassName);

    return () => {
      document.body.style.paddingBottom = '';
      if (bodyClassName) document.body.classList.remove(bodyClassName);
    };
  }
);

/**
 * @private The bar's `<section>`, rendered inside the dark provider so its
 * own context (and its controls') is the dark one.
 */
class ControlBarSection extends Component<ControlBarSectionSignature> {
  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    return { context, styles: useEuiBorealisStyles(context, euiControlBarStyles) };
  }

  get barStyles(): BarStyles {
    return this.styles.styles;
  }

  get isFixed(): boolean {
    return this.args.position === 'fixed';
  }

  @cached
  get sectionClass(): string {
    const { context, styles } = this.styles;
    const { showContent, showOnMobile, pageStyles } = this.args;
    const size = this.args.size ?? 'l';
    const classes = [
      'euiControlBar',
      showContent && 'euiControlBar-isOpen',
      `euiControlBar--${{ s: 'small', m: 'medium', l: 'large' }[size]}`,
      `euiControlBar--${this.args.position}`,
      showOnMobile && 'euiControlBar--showOnMobile',
      euiClass(
        context,
        styles.euiControlBar,
        pageStyles.pageBackground,
        showOnMobile && styles.showOnMobile,
        styles[this.args.position],
        showContent && styles.open[size]
      )
    ];
    return classes.filter(Boolean).join(' ');
  }

  @cached
  get inlineStyle() {
    return cssStyle({
      left: this.args.leftOffset ?? 0,
      right: this.args.rightOffset ?? 0,
      maxHeight: this.args.maxHeight
    });
  }

  @cached
  get controlsClass(): string {
    const { context, styles } = this.styles;
    return `euiControlBar__controls ${euiClass(context, styles.euiControlBar__controls)}`;
  }

  @cached
  get contentClass(): string {
    const { context } = this.styles;
    return `euiControlBar__content ${euiClass(
      context,
      this.args.pageStyles.euiControlBar__content
    )}`;
  }

  @cached
  get partClasses() {
    const { context, styles } = this.styles;
    return {
      tab: euiClass(context, styles.euiControlBar__tab),
      activeTab: euiClass(
        context,
        styles.euiControlBar__tab,
        this.args.pageStyles.activeTab
      ),
      text: euiClass(context, styles.euiControlBar__text),
      spacer: euiClass(context, styles.euiControlBar__spacer),
      divider: euiClass(context, styles.euiControlBar__divider)
    };
  }

  tabClasses = (id: string, className?: string): string => {
    const isActive = this.args.showContent && id === this.args.selectedTab;
    return [
      'euiControlBar__tab',
      isActive && 'euiControlBar__tab--active',
      isActive ? this.partClasses.activeTab : this.partClasses.tab,
      className
    ]
      .filter(Boolean)
      .join(' ');
  };

  <template>
    <section
      class={{this.sectionClass}}
      aria-label={{@heading}}
      style={{this.inlineStyle}}
      ...attributes
    >
      <EuiScreenReaderOnly><h2>{{@heading}}</h2></EuiScreenReaderOnly>
      <div class={{this.controlsClass}} {{padBody this.isFixed @bodyClassName}}>
        {{#each @controls as |control|}}
          <Control
            @control={{control}}
            @styles={{this.barStyles}}
            @partClasses={{this.partClasses}}
            @tabClasses={{this.tabClasses}}
            @onTabClick={{@onTabClick}}
          />
        {{/each}}
      </div>
      {{#if @showContent}}
        <EuiEmotionProvider
          @colorMode={{@pageColorMode}}
          @wrapper={{false}}
          @globalStyles={{false}}
        >
          <div class={{this.contentClass}}>{{yield}}</div>
        </EuiEmotionProvider>
      {{/if}}
    </section>
  </template>
}

interface ControlSignature {
  Args: {
    control: EuiControlBarControl;
    styles: BarStyles;
    partClasses: { text: string; spacer: string; divider: string };
    tabClasses: (id: string, className?: string) => string;
    onTabClick: (
      control: { id: string; onClick: (event: MouseEvent) => void },
      event: MouseEvent
    ) => void;
  };
}

function is<T extends EuiControlBarControl['controlType']>(
  control: EuiControlBarControl,
  type: T
): Extract<EuiControlBarControl, { controlType: T }> | undefined {
  return control.controlType === type
    ? (control as Extract<EuiControlBarControl, { controlType: T }>)
    : undefined;
}

function noop(): void {}

const Control: TemplateOnlyComponent<ControlSignature> = <template>
  {{#let
    (is @control "button")
    (is @control "icon")
    (is @control "tab")
    (is @control "text")
    (is @control "breadcrumbs")
    as |buttonControl iconControl tabControl textControl crumbsControl|
  }}
    {{#if buttonControl}}
      <EuiButton
        class="euiControlBar__button {{buttonControl.className}}"
        @color={{if buttonControl.color buttonControl.color "ghost"}}
        @size="s"
        @href={{buttonControl.href}}
        @iconType={{buttonControl.iconType}}
        @isDisabled={{buttonControl.isDisabled}}
        {{on "click" (if buttonControl.onClick buttonControl.onClick noop)}}
      >{{buttonControl.label}}</EuiButton>
    {{else if iconControl}}
      {{#if (or2 iconControl.onClick iconControl.href)}}
        <EuiButtonIcon
          class="euiControlBar__buttonIcon {{iconControl.className}}"
          @css={{@styles.euiControlBar__buttonIcon}}
          @iconType={{iconControl.iconType}}
          @href={{iconControl.href}}
          @color={{if iconControl.color iconControl.color "ghost"}}
          aria-label={{get iconControl "aria-label"}}
          {{on "click" (if iconControl.onClick iconControl.onClick noop)}}
        />
      {{else}}
        <EuiIcon
          class="euiControlBar__icon {{iconControl.className}}"
          @css={{@styles.euiControlBar__icon}}
          @type={{iconControl.iconType}}
          @color={{if iconControl.color iconControl.color "ghost"}}
          aria-label={{get iconControl "aria-label"}}
        />
      {{/if}}
    {{else if tabControl}}
      <button
        type="button"
        class={{@tabClasses tabControl.id tabControl.className}}
        {{on "click" (fn @onTabClick tabControl)}}
      >{{tabControl.label}}</button>
    {{else if textControl}}
      <div
        class="euiControlBar__text {{@partClasses.text}} {{textControl.className}}"
      >{{textControl.text}}</div>
    {{else if crumbsControl}}
      <EuiBreadcrumbs
        class="euiControlBar__breadcrumbs"
        @breadcrumbs={{crumbsControl.breadcrumbs}}
      />
    {{else if (eq2 @control.controlType "divider")}}
      <div class="euiControlBar__divider {{@partClasses.divider}}"></div>
    {{else if (eq2 @control.controlType "spacer")}}
      <div class="euiControlBar__spacer {{@partClasses.spacer}}"></div>
    {{/if}}
  {{/let}}
</template>;

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function eq2(a: unknown, b: unknown): boolean {
  return a === b;
}
