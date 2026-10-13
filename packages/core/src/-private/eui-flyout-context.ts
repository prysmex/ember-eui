import { getOwner } from '@ember/owner';

import { getContext } from 'ember-provide-consume-context';

import EuiFlyoutManagerService from '../services/eui-flyout-manager.ts';

import type { EuiFlyoutCloseMeta } from '../utils/eui/flyout-manager/types.ts';

/**
 * What an EuiFlyout shares with its content: upstream's
 * `EuiFlyoutParentContext` (a nested flyout is inside a parent flyout) and
 * `EuiFlyoutMenuContext` (an `EuiFlyoutMenu` inside closes its flyout).
 */
export interface EuiFlyoutContext {
  /** Closes the flyout, as its close button does. */
  close(event?: Event, meta?: EuiFlyoutCloseMeta): void;
}

export const EUI_FLYOUT_CONTEXT = '@ember-eui/core/flyout' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_FLYOUT_CONTEXT]: EuiFlyoutContext;
  }
}

/** The nearest EuiFlyout around a component, if any. */
export function euiFlyoutContext(
  component: object
): EuiFlyoutContext | undefined {
  return getContext(component, EUI_FLYOUT_CONTEXT) ?? undefined;
}

/**
 * The owner's `eui-flyout-manager` service. Registered on first use when
 * the app does not resolve it (e.g. strict resolvers in tests).
 */
export function euiFlyoutManager(component: object): EuiFlyoutManagerService {
  const owner = getOwner(component);
  if (!owner)
    throw new Error('EuiFlyout session management requires an Ember owner');

  if (!owner.factoryFor('service:eui-flyout-manager')) {
    owner.register('service:eui-flyout-manager', EuiFlyoutManagerService);
  }

  return owner.lookup('service:eui-flyout-manager') as EuiFlyoutManagerService;
}
