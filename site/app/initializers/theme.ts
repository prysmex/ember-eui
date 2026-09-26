import { changeTheme } from '../utils/change-theme';

const DEFAULT_THEME = 'light';

export function initialize(): void {
  const params = new URL(document.location.href).searchParams;
  let stored: string | null = null;

  try {
    stored = window.localStorage?.getItem('theme') ?? null;
  } catch {
    // ignore unavailable storage
  }

  changeTheme(params.get('theme') || stored || DEFAULT_THEME);
}

export default {
  initialize,
};
