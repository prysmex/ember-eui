import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import cssStyle from '../-private/css-style.ts';
import { EuiTourFooter, EuiTourHeader } from '../-private/eui-tour-parts.gts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiTourBeaconStyles,
  euiTourStyles
} from '../utils/eui/styles.generated.ts';
import EuiBeacon from './eui-beacon.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPopover from './eui-popover.gts';
import EuiWrappingPopover from './eui-wrapping-popover.gts';
import EuiTourStepIndicator from './eui-tour-step-indicator.gts';

import type EuiI18n from '../services/eui-i18n';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';
import type { EuiPopoverSignature } from './eui-popover';

/** What a tour tells its steps (set by `EuiTour`). */
export interface EuiTourContext {
  currentTourStep: number;
  isTourActive: boolean;
  stepsTotal: number;
  tourPopoverWidth?: number;
  tourSubtitle?: string;
  finishTour: () => void;
  stepConfig: (step: number) => EuiTourStepConfig | undefined;
}

/** The content of a step, given to `EuiTour`'s `@steps`. */
export interface EuiTourStepConfig {
  /** The step's number (1-based). */
  step: number;
  /** Title of the step. */
  title: string;
  /** Text of the step. */
  content?: string;
  /** Where the popover opens. Defaults to `'leftUp'`. */
  anchorPosition?: EuiPopoverSignature['Args']['anchorPosition'];
}

/**
 * The EuiPopover args a step passes on (upstream's popover props). They
 * replace the step's own values, except `panelClassName` (added to
 * `euiTour`) and `panelProps` (its `css` is composed after the tour's).
 * `hasArrow` defaults to whether there is a beacon, and `offset` to `10`
 * with a beacon and an arrow.
 */
export type EuiTourStepPopoverArgs = Partial<
  Pick<
    EuiPopoverSignature['Args'],
    | 'attachToAnchor'
    | 'buffer'
    | 'container'
    | 'display'
    | 'focusTrapProps'
    | 'hasArrow'
    | 'initialFocus'
    | 'insert'
    | 'isOpen'
    | 'offset'
    | 'onPositionChange'
    | 'ownFocus'
    | 'panelClassName'
    | 'panelPaddingSize'
    | 'panelProps'
    | 'panelStyle'
    | 'popoverScreenReaderText'
    | 'repositionOnScroll'
    | 'repositionToCrossAxis'
  >
>;

/**
 * One step of a guided tour: a popover with a pulsing beacon next to the
 * element it explains (the block), a title, content, the progress and a
 * button to skip or end the tour. Render it through `EuiTour`, which opens
 * the current step, or on its own with `@isStepOpen`.
 */
export interface EuiTourStepSignature {
  Element: HTMLDivElement;
  Args: {
    /** Shows the popover. Defaults to whether it is the tour's current step. */
    isStepOpen?: boolean;
    /** The step's number (1-based). Defaults to `1`. */
    step?: number;
    /** Number of steps in the tour, for the progress dots. */
    stepsTotal?: number;
    /** Title of the step. */
    title?: string;
    /** Small title above it, e.g. the tour's name. */
    subtitle?: string;
    /** Text of the step. Use the `<:content>` block for markup. */
    content?: string;
    /** Where the popover opens. Defaults to `'leftUp'`. */
    anchorPosition?: EuiPopoverSignature['Args']['anchorPosition'];
    /** Minimum width in px. Defaults to `300`. */
    minWidth?: number;
    /** Maximum width in px. Defaults to `600`. */
    maxWidth?: number;
    /** Called by the "Skip / End / Close tour" button. */
    onFinish?: () => void;
    /** Called when clicking outside or pressing Escape. */
    closePopover?: () => void;
    /**
     * Attaches the popover to an element that is already in the page,
     * given as a CSS selector, the element itself or a function returning
     * it, instead of wrapping
     * the default block (which is then not rendered). The popover appears
     * once the element is found.
     */
    anchor?: string | HTMLElement | (() => HTMLElement | null | undefined);
    /** `z-index` of the popover. Defaults to the popover layer. */
    zIndex?: number;
    /**
     * Replaces the "Skip tour" button in the footer: a component (use
     * `(component …)`), or an array of components for up to two buttons.
     * The `<:footerAction>` block wins when both are given.
     */
    footerAction?: ComponentLike | ComponentLike[];
    /** `'beacon'` (a pulsing dot on the arrow) or `'none'`. Defaults to `'beacon'`. */
    decoration?: 'beacon' | 'none';
    /** @private Set by `EuiTour`. */
    tour?: EuiTourContext;
    /**
     * Extra styles composed into the panel's class, after the tour's own
     * (upstream's `css`, which EuiTourStep moves to the panel).
     */
    css?: EuiCss;
  } & EuiTourStepPopoverArgs;
  Blocks: {
    /** The element the step points at (unused with `@anchor`). */
    default: [];
    /** Markup for the step's content, instead of `@content`. */
    content: [];
    /** Replaces the "Skip tour" button, e.g. with "Next" / "Back" buttons. */
    footerAction: [];
    /**
     * Content of the popover's arrow, instead of the beacon (upstream
     * `arrowChildren`).
     */
    arrowChildren: [];
  };
}

type Status = 'complete' | 'active' | 'incomplete';

const POSITIONS = ['top', 'right', 'bottom', 'left'] as const;

/** Scoped list reset for the progress dots (no React global reset). */
const STEP_LIST_RESET = {
  listStyle: 'none',
  margin: 0,
  padding: 0
} as const;

export default class EuiTourStep extends Component<EuiTourStepSignature> {
  @service declare euiI18n: EuiI18n;

  titleId = `euiTourStep_${randomId()}`;

  get step(): number {
    return this.args.step ?? 1;
  }

  get config(): EuiTourStepConfig | undefined {
    return this.args.tour?.stepConfig(this.step);
  }

  /** Upstream: the popover's own `isOpen` wins over `isStepOpen`. */
  get popoverIsOpen(): boolean {
    return this.args.isOpen ?? this.isOpen;
  }

  get hasArrow(): boolean {
    return this.args.hasArrow ?? this.hasBeacon;
  }

  get offset(): number | undefined {
    if (this.args.offset !== undefined) return this.args.offset;

    return this.hasBeacon && this.args.hasArrow !== false ? 10 : undefined;
  }

  get ownFocus(): boolean {
    return this.args.ownFocus ?? false;
  }

  get panelClassName(): string {
    return ['euiTour', this.args.panelClassName].filter(Boolean).join(' ');
  }

  get isOpen(): boolean {
    if (this.args.isStepOpen !== undefined) return this.args.isStepOpen;

    const tour = this.args.tour;

    return Boolean(tour?.isTourActive && tour.currentTourStep === this.step);
  }

  get stepsTotal(): number {
    return this.args.stepsTotal ?? this.args.tour?.stepsTotal ?? 1;
  }

  get title(): string | undefined {
    return this.args.title ?? this.config?.title;
  }

  get subtitle(): string | undefined {
    return this.args.subtitle ?? this.args.tour?.tourSubtitle;
  }

  get content(): string | undefined {
    return this.args.content ?? this.config?.content;
  }

  get anchorPosition(): EuiPopoverSignature['Args']['anchorPosition'] {
    return this.args.anchorPosition ?? this.config?.anchorPosition ?? 'leftUp';
  }

  get hasBeacon(): boolean {
    return (this.args.decoration ?? 'beacon') === 'beacon';
  }

  /** Upstream: `minWidth`/`maxWidth` as logical sizes on the content wrapper. */
  get widthStyle() {
    const minWidth = this.args.minWidth ?? this.args.tour?.tourPopoverWidth ?? 300;

    return cssStyle({
      minInlineSize: minWidth,
      maxInlineSize: this.args.maxWidth ?? 600
    });
  }

  /**
   * Upstream `euiTourStyles` (arrow background matching the footer), the
   * popover's `panelProps.css`.
   */
  @cached
  get panelCss(): EuiCss {
    const context = getEuiThemeContext(this);
    return [
      useEuiBorealisStyles(context, euiTourStyles).euiTour,
      this.args.css,
      this.args.panelProps?.css
    ];
  }

  /**
   * Upstream `euiTourBeaconStyles`, EuiBeacon's `css`. The position slot
   * follows the popover's actual position through the preceding arrow's
   * `data-popover-arrow` (upstream reads it from `onPositionChange`).
   */
  @cached
  get beaconCss(): EuiCss {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTourBeaconStyles);
    const positions = Object.fromEntries(
      POSITIONS.map((position) => [
        `[data-popover-arrow='${position}'] ~ &`,
        styles[position]
      ])
    );

    return [styles.euiTourBeacon, this.isOpen && styles.isOpen, positions];
  }

  @cached
  get stepListClass(): string {
    return `euiTourFooter__stepList ${euiClass(
      getEuiThemeContext(this),
      STEP_LIST_RESET
    )}`;
  }

  get statuses(): { number: number; status: Status }[] {
    return Array.from({ length: this.stepsTotal }, (_, i) => ({
      number: i + 1,
      status: this.step === i + 1 ? 'active' : this.step <= i ? 'incomplete' : 'complete'
    }));
  }

  get finishLabel(): string {
    const t = (token: string, text: string) =>
      this.euiI18n.lookupToken(`euiTourFooter.${token}`, text);

    if (this.stepsTotal > 1) {
      return this.stepsTotal === this.step ? t('endTour', 'End tour') : t('skipTour', 'Skip tour');
    }

    return t('closeTour', 'Close tour');
  }

  finish = (): void => {
    (this.args.onFinish ?? this.args.tour?.finishTour)?.();
  };

  close = (): void => {
    this.args.closePopover?.();
  };

  @tracked anchorNode: HTMLElement | null = null;

  /**
   * Upstream finds the `@anchor` on the next tick, in case it is not in the
   * DOM yet.
   */
  resolveAnchor = modifier((_element: HTMLElement, [anchor]: [unknown]) => {
    const timeout = window.setTimeout(() => {
      this.anchorNode =
        typeof anchor === 'string'
          ? document.querySelector<HTMLElement>(anchor)
          : typeof anchor === 'function'
            ? ((anchor() as HTMLElement | null | undefined) ?? null)
            : ((anchor as HTMLElement | null) ?? null);
    });

    return () => window.clearTimeout(timeout);
  });

  /** `@footerAction` as a list of components. */
  get footerActions(): ComponentLike[] {
    const action = this.args.footerAction;

    if (!action) return [];

    return Array.isArray(action) ? action : [action];
  }

  get hasFooterActionList(): boolean {
    return Array.isArray(this.args.footerAction);
  }

  <template>
    {{#let
      (has-block "content")
      (has-block "footerAction")
      (has-block "arrowChildren")
      as |hasContent hasFooterAction hasArrowChildren|
    }}
      {{#if @anchor}}
        <span hidden class="euiTourAnchor__resolver" {{this.resolveAnchor @anchor}}></span>
        {{#if this.anchorNode}}
          <EuiWrappingPopover
            class="euiTourAnchor"
            @button={{this.anchorNode}}
            @isOpen={{this.popoverIsOpen}}
            @closePopover={{this.close}}
            @anchorPosition={{this.anchorPosition}}
            @ownFocus={{this.ownFocus}}
            @panelClassName={{this.panelClassName}}
            @panelCss={{this.panelCss}}
            @panelProps={{@panelProps}}
            @hasArrow={{this.hasArrow}}
            @offset={{this.offset}}
            @zIndex={{@zIndex}}
            @ariaLabelledBy={{this.titleId}}
            @attachToAnchor={{@attachToAnchor}}
            @buffer={{@buffer}}
            @container={{@container}}
            @display={{@display}}
            @focusTrapProps={{@focusTrapProps}}
            @initialFocus={{@initialFocus}}
            @onPositionChange={{@onPositionChange}}
            @panelPaddingSize={{@panelPaddingSize}}
            @panelStyle={{@panelStyle}}
            @popoverScreenReaderText={{@popoverScreenReaderText}}
            @repositionOnScroll={{@repositionOnScroll}}
            @repositionToCrossAxis={{@repositionToCrossAxis}}
            ...attributes
          >
            <:arrowChildren>
              {{#if hasArrowChildren}}
                {{yield to="arrowChildren"}}
              {{else if this.hasBeacon}}
                <EuiBeacon class="euiTour__beacon" @css={{this.beaconCss}} />
              {{/if}}
            </:arrowChildren>
            <:default>
              <StepContent
                @step={{this}}
                @hasContent={{hasContent}}
                @hasFooterAction={{hasFooterAction}}
              >
                <:content>{{yield to="content"}}</:content>
                <:footerAction>{{yield to="footerAction"}}</:footerAction>
              </StepContent>
            </:default>
          </EuiWrappingPopover>
        {{/if}}
      {{else}}
        <EuiPopover
          class="euiTourAnchor"
          @isOpen={{this.popoverIsOpen}}
          @closePopover={{this.close}}
          @anchorPosition={{this.anchorPosition}}
          @ownFocus={{this.ownFocus}}
          @panelClassName={{this.panelClassName}}
          @panelCss={{this.panelCss}}
          @panelProps={{@panelProps}}
          @hasArrow={{this.hasArrow}}
          @offset={{this.offset}}
          @zIndex={{@zIndex}}
          @ariaLabelledBy={{this.titleId}}
          @attachToAnchor={{@attachToAnchor}}
          @buffer={{@buffer}}
          @container={{@container}}
          @display={{@display}}
          @focusTrapProps={{@focusTrapProps}}
          @initialFocus={{@initialFocus}}
          @onPositionChange={{@onPositionChange}}
          @panelPaddingSize={{@panelPaddingSize}}
          @panelStyle={{@panelStyle}}
          @popoverScreenReaderText={{@popoverScreenReaderText}}
          @repositionOnScroll={{@repositionOnScroll}}
          @repositionToCrossAxis={{@repositionToCrossAxis}}
          @insert={{@insert}}
          ...attributes
        >
          <:button>{{yield}}</:button>
          <:arrowChildren>
            {{#if hasArrowChildren}}
              {{yield to="arrowChildren"}}
            {{else if this.hasBeacon}}
              <EuiBeacon class="euiTour__beacon" @css={{this.beaconCss}} />
            {{/if}}
          </:arrowChildren>
          <:content>
            <StepContent
              @step={{this}}
              @hasContent={{hasContent}}
              @hasFooterAction={{hasFooterAction}}
            >
              <:content>{{yield to="content"}}</:content>
              <:footerAction>{{yield to="footerAction"}}</:footerAction>
            </StepContent>
          </:content>
        </EuiPopover>
      {{/if}}
    {{/let}}
  </template>
}

interface StepContentSignature {
  Args: {
    step: EuiTourStep;
    hasContent: boolean;
    hasFooterAction: boolean;
  };
  Blocks: { content: []; footerAction: [] };
}

/** The title, content and footer of a step, shared by both popover kinds. */
const StepContent: TemplateOnlyComponent<StepContentSignature> = <template>
  <div style={{@step.widthStyle}}>
    <EuiTourHeader
      id={{@step.titleId}}
      @title={{@step.title}}
      @subtitle={{@step.subtitle}}
    />
    <div class="euiTour__content">
      {{#if @hasContent}}
        {{yield to="content"}}
      {{else}}
        {{@step.content}}
      {{/if}}
    </div>
    <EuiTourFooter>
      <EuiFlexGroup
        @responsive={{false}}
        @alignItems="center"
        @justifyContent={{if
          (isMany @step.stepsTotal)
          "spaceBetween"
          "flexEnd"
        }}
      >
        {{#if (isMany @step.stepsTotal)}}
          <EuiFlexItem @grow={{false}}>
            <ul class={{@step.stepListClass}}>
              {{~#each @step.statuses as |indicator|~}}
                <EuiTourStepIndicator
                  @number={{indicator.number}}
                  @status={{indicator.status}}
                />
              {{~/each~}}
            </ul>
          </EuiFlexItem>
        {{/if}}
        {{#if @hasFooterAction}}
          <EuiFlexItem @grow={{false}}>
            {{yield to="footerAction"}}
          </EuiFlexItem>
        {{else if @step.hasFooterActionList}}
          <EuiFlexGroup
            @gutterSize="s"
            @alignItems="center"
            @justifyContent="flexEnd"
            @responsive={{false}}
            @wrap={{true}}
          >
            {{#each @step.footerActions as |Action|}}
              <EuiFlexItem @grow={{false}}><Action /></EuiFlexItem>
            {{/each}}
          </EuiFlexGroup>
        {{else if @step.footerActions.length}}
          {{#each @step.footerActions as |Action|}}
            <EuiFlexItem @grow={{false}}><Action /></EuiFlexItem>
          {{/each}}
        {{else}}
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty
              @color="text"
              @flush="right"
              @size="xs"
              {{on "click" @step.finish}}
            >{{@step.finishLabel}}</EuiButtonEmpty>
          </EuiFlexItem>
        {{/if}}
      </EuiFlexGroup>
    </EuiTourFooter>
  </div>
</template>;

function isMany(count: number): boolean {
  return count > 1;
}
