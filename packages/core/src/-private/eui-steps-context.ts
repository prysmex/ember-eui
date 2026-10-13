import { getContext } from 'ember-provide-consume-context';

/** What an EuiSteps shares with its steps. */
export interface EuiStepsContext {
  /** The number the first step starts from (upstream `firstStepNumber`). */
  readonly firstStepNumber: number;
  /** Default title size of the steps. */
  readonly titleSize: 'xxs' | 'xs' | 's' | 'm' | undefined;
  /** Default tag of the step titles. */
  readonly headingElement: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'p' | undefined;
}

export const EUI_STEPS_CONTEXT = '@ember-eui/core/steps' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_STEPS_CONTEXT]: EuiStepsContext;
  }
}

/** The nearest EuiSteps' context, if the step is inside one. */
export function euiStepsContext(component: object): EuiStepsContext | undefined {
  return getContext(component, EUI_STEPS_CONTEXT);
}
