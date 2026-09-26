import darkTheme from '@ember-eui/core/themes/dark.css?url';
import lightTheme from '@ember-eui/core/themes/light.css?url';

const THEMES: Record<string, string> = {
  dark: darkTheme,
  light: lightTheme,
};

const LINK_ID = 'eui-theme';

/**
 * Loads the EUI theme stylesheet for `theme` ("light" or "dark") by pointing a
 * single <link> at the theme's built CSS file, so switching themes swaps the
 * stylesheet instead of stacking both.
 */
export function changeTheme(theme: string): void {
  const key = theme in THEMES ? theme : 'light';
  const href = THEMES[key]!;
  let link = document.getElementById(LINK_ID) as HTMLLinkElement | null;

  if (!link) {
    link = document.createElement('link');
    link.id = LINK_ID;
    link.rel = 'stylesheet';
    // before the app's own styles so site overrides keep winning
    document.head.prepend(link);
  }

  if (link.getAttribute('href') !== href) {
    link.href = href;
  }

  link.dataset['theme'] = key;

  try {
    window.localStorage?.setItem('theme', key);
  } catch {
    // storage can be unavailable (private mode); the theme still applies
  }
}
