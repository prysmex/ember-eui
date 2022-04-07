import { changeTheme } from '../utils/change-theme';

const DEFAULT_THEME = 'amsterdam_light';

export function initialize(): void {
  if (window?.localStorage) {
    const currentTheme = window.localStorage.getItem('theme');
    changeTheme(currentTheme ? currentTheme : DEFAULT_THEME);
  }
}

export default {
  initialize
};
