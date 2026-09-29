import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { action } from '@ember/object';

import EuiTourStep from './eui-tour-step.gts';

import type { EuiTourContext, EuiTourStepConfig } from './eui-tour-step';
import type { EuiTourStepSignature } from './eui-tour-step';
import type Owner from '@ember/owner';
import type { ComponentLike } from '@glint/template';

export type { EuiTourStepConfig };

export interface EuiTourState {
  /** The step shown (1-based). */
  currentTourStep: number;
  /** Whether the tour runs. */
  isTourActive: boolean;
  /** Minimum width of the steps' popovers, in px. */
  tourPopoverWidth?: number;
  /** Subtitle of every step, e.g. the tour's name. */
  tourSubtitle?: string;
}

export interface EuiTourActions {
  /** Ends the tour; `resetTour` (default `true`) goes back to step 1. */
  finishTour: (resetTour?: boolean) => void;
  /** Starts again from step 1. */
  resetTour: () => void;
  /** Goes to the next step. */
  incrementStep: () => void;
  /** Goes to the previous step. */
  decrementStep: () => void;
  /** Goes to a step, and starts or stops the tour with `isTourActive`. */
  goToStep: (step: number, isTourActive?: boolean) => void;
}

/**
 * A guided tour: a series of `EuiTourStep` popovers shown one at a time.
 * It keeps the tour's state and yields `{ Step, actions, state }`: render
 * a `<tour.Step @step={{n}}>` around each element the tour points at, and
 * move with `tour.actions`.
 */
export interface EuiTourSignature {
  Args: {
    /** Where the tour starts (and whether it runs at first). */
    initialState: EuiTourState;
    /**
     * The steps' titles and contents: `[{ step, title, content }]`. Each
     * `<tour.Step @step={{n}}>` uses the entry with its number. Optional
     * when the steps get their text directly.
     */
    steps?: EuiTourStepConfig[];
    /** Number of steps, when `@steps` is not given. */
    stepsTotal?: number;
  };
  Blocks: {
    default: [
      {
        /** An `EuiTourStep` wired to this tour. */
        Step: ComponentLike<{
          Element: HTMLDivElement;
          Args: Omit<EuiTourStepSignature['Args'], 'tour'>;
          Blocks: EuiTourStepSignature['Blocks'];
        }>;
        actions: EuiTourActions;
        state: EuiTourState;
      }
    ];
  };
}

export default class EuiTour extends Component<EuiTourSignature> {
  @tracked currentTourStep: number;
  @tracked isTourActive: boolean;

  constructor(owner: Owner, args: EuiTourSignature['Args']) {
    super(owner, args);
    // only the starting point: the actions then change it
    this.currentTourStep = args.initialState.currentTourStep;
    this.isTourActive = args.initialState.isTourActive;
  }

  get stepsTotal(): number {
    return this.args.steps?.length ?? this.args.stepsTotal ?? 1;
  }

  get state(): EuiTourState {
    return {
      ...this.args.initialState,
      currentTourStep: this.currentTourStep,
      isTourActive: this.isTourActive
    };
  }

  get context(): EuiTourContext {
    return {
      currentTourStep: this.currentTourStep,
      isTourActive: this.isTourActive,
      stepsTotal: this.stepsTotal,
      tourPopoverWidth: this.args.initialState.tourPopoverWidth,
      tourSubtitle: this.args.initialState.tourSubtitle,
      finishTour: () => this.finishTour(),
      stepConfig: (step: number) => this.args.steps?.find((config) => config.step === step)
    };
  }

  @action
  finishTour(resetTour = true): void {
    if (resetTour) this.currentTourStep = 1;
    this.isTourActive = false;
  }

  @action
  resetTour(): void {
    this.currentTourStep = 1;
    this.isTourActive = true;
  }

  @action
  incrementStep(): void {
    if (this.currentTourStep < this.stepsTotal) this.currentTourStep++;
  }

  @action
  decrementStep(): void {
    if (this.currentTourStep > 1) this.currentTourStep--;
  }

  @action
  goToStep(step: number, isTourActive?: boolean): void {
    if (step > 0 && step <= this.stepsTotal) this.currentTourStep = step;
    if (isTourActive !== undefined) this.isTourActive = isTourActive;
  }

  get actions(): EuiTourActions {
    return {
      finishTour: this.finishTour,
      resetTour: this.resetTour,
      incrementStep: this.incrementStep,
      decrementStep: this.decrementStep,
      goToStep: this.goToStep
    };
  }

  <template>
    {{yield
      (hash
        Step=(component EuiTourStep tour=this.context)
        actions=this.actions
        state=this.state
      )
    }}
  </template>
}
