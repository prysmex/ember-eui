import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import cssStyle from '../-private/css-style.ts';
import { EuiTourFooter, EuiTourHeader } from '../-private/eui-tour-parts.gts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTourBeaconStyles,
  euiTourStyles
} from '../utils/eui/styles.generated.ts';
import EuiBeacon from './eui-beacon.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPopover from './eui-popover.gts';
import EuiTourStepIndicator from './eui-tour-step-indicator.gts';

import type EuiI18n from '../services/eui-i18n';
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
    /** `'beacon'` (a pulsing dot on the arrow) or `'none'`. Defaults to `'beacon'`. */
    decoration?: 'beacon' | 'none';
    /** @private Set by `EuiTour`. */
    tour?: EuiTourContext;
  };
  Blocks: {
    /** The element the step points at. */
    default: [];
    /** Markup for the step's content, instead of `@content`. */
    content: [];
    /** Replaces the "Skip tour" button, e.g. with "Next" / "Back" buttons. */
    footerAction: [];
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
   * Upstream `euiTourStyles` (arrow background matching the footer). It only
   * holds a rule for the arrow inside the panel, so it never competes with
   * the panel's own class.
   */
  @cached
  get panelClassName(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTourStyles);

    return `euiTour ${euiClass(context, styles.euiTour)}`;
  }

  /**
   * Upstream `euiTourBeaconStyles` on a wrapper around EuiBeacon (no
   * `@css` on it yet). The position slot follows the popover's actual
   * position through the preceding arrow's `data-popover-arrow` (upstream
   * reads it from `onPositionChange`).
   */
  @cached
  get beaconClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTourBeaconStyles);
    const positions = Object.fromEntries(
      POSITIONS.map((position) => [
        `[data-popover-arrow='${position}'] ~ &`,
        styles[position]
      ])
    );

    return `euiTour__beaconWrapper ${euiClass(
      context,
      styles.euiTourBeacon,
      this.isOpen && styles.isOpen,
      positions
    )}`;
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

  <template>
    <EuiPopover
      class="euiTourAnchor"
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition={{this.anchorPosition}}
      @ownFocus={{false}}
      @panelClassName={{this.panelClassName}}
      @hasArrow={{this.hasBeacon}}
      @offset={{if this.hasBeacon 10}}
      @ariaLabelledBy={{this.titleId}}
      ...attributes
    >
      <:button>{{yield}}</:button>
      <:arrowChildren>
        {{#if this.hasBeacon}}
          <div class={{this.beaconClasses}}>
            <EuiBeacon class="euiTour__beacon" />
          </div>
        {{/if}}
      </:arrowChildren>
      <:content>
        <div style={{this.widthStyle}}>
          <EuiTourHeader
            id={{this.titleId}}
            @title={{this.title}}
            @subtitle={{this.subtitle}}
          />
          <div class="euiTour__content">
            {{#if (has-block "content")}}
              {{yield to="content"}}
            {{else}}
              {{this.content}}
            {{/if}}
          </div>
          <EuiTourFooter>
            <EuiFlexGroup
              @responsive={{false}}
              @alignItems="center"
              @justifyContent={{if
                (isMany this.stepsTotal)
                "spaceBetween"
                "flexEnd"
              }}
            >
              {{#if (isMany this.stepsTotal)}}
                <EuiFlexItem @grow={{false}}>
                  <ul class={{this.stepListClass}}>
                    {{~#each this.statuses as |indicator|~}}
                      <EuiTourStepIndicator
                        @number={{indicator.number}}
                        @status={{indicator.status}}
                      />
                    {{~/each~}}
                  </ul>
                </EuiFlexItem>
              {{/if}}
              <EuiFlexItem @grow={{false}}>
                {{#if (has-block "footerAction")}}
                  {{yield to="footerAction"}}
                {{else}}
                  <EuiButtonEmpty
                    @color="text"
                    @flush="right"
                    @size="xs"
                    {{on "click" this.finish}}
                  >{{this.finishLabel}}</EuiButtonEmpty>
                {{/if}}
              </EuiFlexItem>
            </EuiFlexGroup>
          </EuiTourFooter>
        </div>
      </:content>
    </EuiPopover>
  </template>
}

function isMany(count: number): boolean {
  return count > 1;
}

