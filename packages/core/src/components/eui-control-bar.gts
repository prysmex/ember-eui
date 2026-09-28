import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import EuiBreadcrumbs from './eui-breadcrumbs.gts';
import EuiButton from './eui-button.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiPortal from './eui-portal.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiBreadcrumb } from './eui-breadcrumbs';
import type { EuiIconSignature } from './eui-icon';
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
      color?: 'primary' | 'accent' | 'success' | 'warning' | 'danger' | 'ghost' | 'text';
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

/**
 * A dark bar of controls at the bottom of the page (or of a container),
 * e.g. an editor's toolbar or a code console: buttons, icons, text,
 * breadcrumbs and tabs that open a content area above it.
 */
export interface EuiControlBarSignature {
  Element: HTMLElement;
  Args: {
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
    /** Keeps the bar on small screens (hidden there by default). */
    showOnMobile?: boolean;
    /** Class added to `<body>` while a fixed bar is shown. */
    bodyClassName?: string;
    /** Accessible name of the bar's region. Defaults to "Page level controls". */
    landmarkHeading?: string;
  };
  Blocks: {
    /** Content shown above the controls while `@showContent`. */
    default: [];
  };
}

export default class EuiControlBar extends Component<EuiControlBarSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked selectedTab?: string;

  get position(): string {
    return this.args.position ?? 'fixed';
  }

  get isFixed(): boolean {
    return this.position === 'fixed';
  }

  get classes(): string {
    const { showContent, showOnMobile } = this.args;

    return [
      'euiControlBar',
      showContent && 'euiControlBar-isOpen',
      `euiControlBar--${{ s: 'small', m: 'medium', l: 'large' }[this.args.size ?? 'l']}`,
      `euiControlBar--${this.position}`,
      showOnMobile && 'euiControlBar--showOnMobile'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get heading(): string {
    return (
      this.args.landmarkHeading ??
      this.euiI18n.lookupToken('euiControlBar.screenReaderHeading', 'Page level controls')
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

  tabClasses = (id: string, className?: string): string =>
    [
      'euiControlBar__tab',
      this.args.showContent && id === this.selectedTab && 'euiControlBar__tab--active',
      className
    ]
      .filter(Boolean)
      .join(' ');

  @action
  onTabClick(control: { id: string; onClick: (event: MouseEvent) => void }, event: MouseEvent): void {
    this.selectedTab = control.id;
    control.onClick(event);
  }

  /** A fixed bar pads the bottom of `<body>` by its height while shown. */
  padBody = modifier((controls: HTMLElement, [isFixed, bodyClassName]: [boolean, string | undefined]) => {
    if (!isFixed) return;

    document.body.style.paddingBottom = `${controls.clientHeight}px`;
    if (bodyClassName) document.body.classList.add(bodyClassName);

    return () => {
      document.body.style.paddingBottom = '';
      if (bodyClassName) document.body.classList.remove(bodyClassName);
    };
  });

  <template>
    {{#if this.isFixed}}
      <EuiPortal>
        {{! template-lint-disable no-duplicate-landmark-elements }}
        <section
          class={{this.classes}}
          aria-label={{this.heading}}
          style={{cssStyle
            (hash
              left=(if @leftOffset @leftOffset 0)
              right=(if @rightOffset @rightOffset 0)
              maxHeight=@maxHeight
            )
          }}
          ...attributes
        >
          <EuiScreenReaderOnly><h2>{{this.heading}}</h2></EuiScreenReaderOnly>
          <div class="euiControlBar__controls" {{this.padBody true @bodyClassName}}>
            {{#each @controls as |control|}}
              <Control
                @control={{control}}
                @tabClasses={{this.tabClasses}}
                @onTabClick={{this.onTabClick}}
              />
            {{/each}}
          </div>
          {{#if @showContent}}
            <div class="euiControlBar__content">{{yield}}</div>
          {{/if}}
        </section>
        <EuiScreenReaderOnly>
          <p aria-live="assertive">{{this.announcement}}</p>
        </EuiScreenReaderOnly>
      </EuiPortal>
    {{else}}
      <section
        class={{this.classes}}
        aria-label={{this.heading}}
        style={{cssStyle
          (hash
            left=(if @leftOffset @leftOffset 0)
            right=(if @rightOffset @rightOffset 0)
            maxHeight=@maxHeight
          )
        }}
        ...attributes
      >
        <EuiScreenReaderOnly><h2>{{this.heading}}</h2></EuiScreenReaderOnly>
        <div class="euiControlBar__controls">
          {{#each @controls as |control|}}
            <Control
                @control={{control}}
                @tabClasses={{this.tabClasses}}
                @onTabClick={{this.onTabClick}}
              />
          {{/each}}
        </div>
        {{#if @showContent}}
          <div class="euiControlBar__content">{{yield}}</div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}

interface ControlSignature {
  Args: {
    control: EuiControlBarControl;
    tabClasses: (id: string, className?: string) => string;
    onTabClick: (control: { id: string; onClick: (event: MouseEvent) => void }, event: MouseEvent) => void;
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
          @iconType={{iconControl.iconType}}
          @href={{iconControl.href}}
          @color={{if iconControl.color iconControl.color "ghost"}}
          aria-label={{get iconControl "aria-label"}}
          {{on "click" (if iconControl.onClick iconControl.onClick noop)}}
        />
      {{else}}
        <EuiIcon
          class="euiControlBar__icon {{iconControl.className}}"
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
      <div class="euiControlBar__text {{textControl.className}}">{{textControl.text}}</div>
    {{else if crumbsControl}}
      <EuiBreadcrumbs
        class="euiControlBar__breadcrumbs"
        @breadcrumbs={{crumbsControl.breadcrumbs}}
      />
    {{else if (eq2 @control.controlType "divider")}}
      <div class="euiControlBar__divider"></div>
    {{else if (eq2 @control.controlType "spacer")}}
      <div class="euiControlBar__spacer"></div>
    {{/if}}
  {{/let}}
</template>;

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function eq2(a: unknown, b: unknown): boolean {
  return a === b;
}
