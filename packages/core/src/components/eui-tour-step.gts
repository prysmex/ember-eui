import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { inject as service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
import EuiBeacon from './eui-beacon.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiPopover from './eui-popover.gts';
import EuiPopoverFooter from './eui-popover-footer.gts';
import EuiPopoverTitle from './eui-popover-title.gts';
import EuiTitle from './eui-title.gts';
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

  get panelStyle(): Record<string, string> {
    const minWidth = this.args.minWidth ?? this.args.tour?.tourPopoverWidth ?? 300;

    return { minWidth: `${minWidth}px`, maxWidth: `${this.args.maxWidth ?? 600}px` };
  }

  get statuses(): { number: number; status: Status }[] {
    return Array.from({ length: this.stepsTotal }, (_, i) => ({
      number: i + 1,
      status: this.step === i + 1 ? 'active' : this.step <= i ? 'incomplete' : 'complete'
    }));
  }

  get finishLabel(): string {
    const t = (token: string, text: string) => this.euiI18n.lookupToken(`euiTourStep.${token}`, text);

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
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition={{this.anchorPosition}}
      @ownFocus={{false}}
      @panelClassName="euiTour"
      @panelStyle={{this.panelStyle}}
      @offset={{if this.hasBeacon 10 0}}
      @ariaLabelledBy={{this.titleId}}
      ...attributes
    >
      <:button>{{yield}}</:button>
      <:arrowChildren>
        {{#if this.hasBeacon}}
          <EuiBeacon class="euiTour__beacon" />
        {{/if}}
      </:arrowChildren>
      <:content>
        <EuiPopoverTitle class="euiTourHeader" id={{this.titleId}}>
          {{#if this.subtitle}}
            <EuiTitle class="euiTourHeader__subtitle" @size="xxxs" @tagName="h2">{{this.subtitle}}</EuiTitle>
            <EuiTitle class="euiTourHeader__title" @size="xxs" @tagName="h3">{{this.title}}</EuiTitle>
          {{else}}
            <EuiTitle class="euiTourHeader__title" @size="xxs" @tagName="h2">{{this.title}}</EuiTitle>
          {{/if}}
        </EuiPopoverTitle>
        <div class="euiTour__content">
          {{#if (has-block "content")}}
            {{yield to="content"}}
          {{else}}
            {{this.content}}
          {{/if}}
        </div>
        <EuiPopoverFooter class="euiTourFooter">
          <EuiFlexGroup
            @responsive={{false}}
            @justifyContent={{if (isMany this.stepsTotal) "spaceBetween" "flexEnd"}}
          >
            {{#if (isMany this.stepsTotal)}}
              <EuiFlexItem @grow={{false}}>
                <ul class="euiTourFooter__stepList">
                  {{#each this.statuses as |indicator|}}
                    <EuiTourStepIndicator @number={{indicator.number}} @status={{indicator.status}} />
                  {{/each}}
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
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </template>
}

function isMany(count: number): boolean {
  return count > 1;
}

