import { getOwner } from '@ember/owner';
import { getContext } from 'ember-provide-consume-context';
import type EuiEmotionService from '../../services/eui-emotion.ts';
import type { EuiThemeContext } from './context.ts';

export const EUI_EMOTION_CONTEXT = '@ember-eui/core/emotion-theme' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_EMOTION_CONTEXT]: EuiThemeContext;
  }
}

/** Read in a component getter so provider and service changes remain tracked. */
export function getEuiThemeContext(component: object): EuiThemeContext {
  const provided = getContext(component, EUI_EMOTION_CONTEXT);
  if (provided) return provided;
  const defaults = getOwner(component)?.lookup('service:eui-emotion') as
    EuiEmotionService | undefined;
  if (!defaults)
    throw new Error('Emotion theme consumers require an Ember component owner');
  return defaults.context;
}
