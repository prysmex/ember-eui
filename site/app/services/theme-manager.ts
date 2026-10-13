import { tracked } from '@glimmer/tracking';
import Service from '@ember/service';

import type Owner from '@ember/owner';

type ThemeShape = {
  name: string;
  key: string;
};

export default class ThemeManager extends Service {
  @tracked currentTheme?: ThemeShape;
  /**
   * `true` forces high contrast; `undefined` follows the OS preference
   * (`prefers-contrast: more`, Windows forced colors), as the root
   * provider does when `@highContrastMode` is unset.
   */
  @tracked highContrast?: true;

  themes: ThemeShape[] = [
    {
      name: 'Light',
      key: 'light',
    },
    {
      name: 'Dark',
      key: 'dark',
    },
  ];

  constructor(owner?: Owner) {
    super(owner);

    const params = new URL(document.location.href).searchParams;
    const theme = params.get('theme');
    const currentTheme = theme || window?.localStorage?.getItem('theme');

    this.currentTheme =
      this.themes.find((theme) => theme.key === currentTheme) || this.themes[0];

    let contrast = params.get('highContrast');
    try {
      contrast ??= window.localStorage?.getItem('highContrast') ?? null;
    } catch {
      // storage can be unavailable (private mode)
    }
    this.highContrast = contrast === 'true' ? true : undefined;
  }

  toggleHighContrast = () => {
    this.highContrast = this.highContrast ? undefined : true;
    try {
      if (this.highContrast)
        window.localStorage?.setItem('highContrast', 'true');
      else window.localStorage?.removeItem('highContrast');
    } catch {
      // storage can be unavailable (private mode); the mode still applies
    }
  };

  /** The root Borealis provider follows `currentTheme`; no stylesheet swap. */
  changeTheme = (theme: ThemeShape) => {
    if (theme.key !== this.currentTheme?.key) {
      this.currentTheme = theme;
      try {
        window.localStorage?.setItem('theme', theme.key);
      } catch {
        // storage can be unavailable (private mode); the theme still applies
      }
    }
  };
}

// DO NOT DELETE: this is how TypeScript knows how to look up your services.
declare module '@ember/service' {
  interface Registry {
    'theme-manager': ThemeManager;
  }
}
