import { getContext } from 'ember-provide-consume-context';

/** Upstream horizontal step sizes. */
export type EuiStepsHorizontalSize = 'xs' | 's' | 'm';

/** What an EuiStepsHorizontal shares with its steps. */
export interface EuiStepsHorizontalContext {
  readonly size: EuiStepsHorizontalSize;
}

export const EUI_STEPS_HORIZONTAL_CONTEXT =
  '@ember-eui/core/steps-horizontal' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_STEPS_HORIZONTAL_CONTEXT]: EuiStepsHorizontalContext;
  }
}

/** The step's own size, else the nearest EuiStepsHorizontal's, else `m`. */
export function euiStepsHorizontalSize(
  component: object,
  size: EuiStepsHorizontalSize | undefined
): EuiStepsHorizontalSize {
  return (
    size ?? getContext(component, EUI_STEPS_HORIZONTAL_CONTEXT)?.size ?? 'm'
  );
}
