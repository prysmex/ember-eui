import { tracked } from '@glimmer/tracking';

import type { EuiColorMode } from './theme.ts';
import type { EuiBorealisHighContrastMode } from '../eui/theme.ts';

/**
 * The OS/browser preferences upstream's `EuiSystemDefaultsProvider` reads
 * (`components/provider/system_defaults`), tracked so a root provider whose
 * `@colorMode`/`@highContrastMode` are undefined follows them live:
 *
 * - `(prefers-color-scheme: dark)` → `'dark'`, else `'light'`;
 * - `(forced-colors: active)` (Windows high contrast) → `'forced'`, which
 *   supersedes app settings, else `(prefers-contrast: more)` → `'preferred'`,
 *   else `false`.
 *
 * Safe without `window`/`matchMedia` (SSR, FastBoot, tests): everything
 * stays at its default. Call `destroy()` to remove the change listeners.
 */
export class EuiSystemPreferences {
  @tracked prefersDark = false;
  @tracked forcedColors = false;
  @tracked prefersMoreContrast = false;

  private cleanups: Array<() => void> = [];

  constructor() {
    this.watch('(prefers-color-scheme: dark)', (v) => (this.prefersDark = v));
    this.watch('(forced-colors: active)', (v) => (this.forcedColors = v));
    this.watch('(prefers-contrast: more)', (v) => (this.prefersMoreContrast = v));
  }

  get colorMode(): EuiColorMode {
    return this.prefersDark ? 'dark' : 'light';
  }

  get highContrastMode(): EuiBorealisHighContrastMode {
    if (this.forcedColors) return 'forced';
    return this.prefersMoreContrast ? 'preferred' : false;
  }

  private watch(query: string, set: (matches: boolean) => void) {
    if (typeof window === 'undefined' || typeof window.matchMedia !== 'function')
      return;
    const list = window.matchMedia(query);
    if (!list) return;
    set(Boolean(list.matches));
    const listener = (event: MediaQueryListEvent) => set(event.matches);
    if (typeof list.addEventListener === 'function') {
      list.addEventListener('change', listener);
      this.cleanups.push(() => list.removeEventListener('change', listener));
    }
  }

  destroy() {
    for (const cleanup of this.cleanups) cleanup();
    this.cleanups = [];
  }
}
