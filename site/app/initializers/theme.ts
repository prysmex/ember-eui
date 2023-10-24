import { changeTheme } from '../utils/change-theme';

const DEFAULT_THEME = 'light';

export function initialize(): void {
  if (window?.localStorage) {
    const params = new URL(document.location.href).searchParams;
    const theme = params.get('theme');
    const currentTheme = theme || window.localStorage.getItem('theme');
    changeTheme(currentTheme ? currentTheme : DEFAULT_THEME);
  }
}

export default {
  initialize
};
