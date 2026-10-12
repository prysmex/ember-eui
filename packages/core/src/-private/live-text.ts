import { buildWaiter } from '@ember/test-waiters';

import { modifier } from 'ember-modifier';

const waiter = buildWaiter('@ember-eui/core:live-text');

/** Collapses whitespace from template formatting, like a screen reader. */
export function normalizeLiveText(text: string | null | undefined): string {
  return (text ?? '').replace(/\s+/g, ' ').trim();
}

/**
 * Reports the (whitespace-normalized) text of the element now and every
 * time it changes. EuiLiveAnnouncer and EuiScreenReaderLive render their
 * block into a `hidden` source element with this modifier and announce its
 * text: upstream reacts to new `children`, which a Glimmer block cannot
 * signal. Extra positional arguments re-run the modifier (and report the
 * text again) when they change, like the dependencies of a React effect.
 */
export const observeLiveText = modifier(
  (element: HTMLElement, [onChange]: [(text: string) => void, ...unknown[]]) => {
    let active = true;
    const report = () => {
      if (active) onChange(normalizeLiveText(element.textContent));
    };
    // The first report updates state the render just read, so it waits
    // for the render to finish (a test waiter keeps `settled()` aware).
    const token = waiter.beginAsync();
    void Promise.resolve().then(() => {
      waiter.endAsync(token);
      report();
    });
    const observer =
      typeof MutationObserver === 'undefined'
        ? undefined
        : new MutationObserver(report);
    observer?.observe(element, {
      childList: true,
      characterData: true,
      subtree: true
    });
    return () => {
      active = false;
      observer?.disconnect();
    };
  }
);
