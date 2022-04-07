export function changeTheme(theme: string) {
  const currentStylesheet = document.getElementById('current-ember-eui-theme');
  if (currentStylesheet) {
    currentStylesheet.parentNode?.removeChild(currentStylesheet);
  }
  const head = document.head;
  const link = document.createElement('link');

  link.type = 'text/css';
  link.rel = 'stylesheet';
  link.href = `/@ember-eui/themes/eui_theme_${theme}.css`;
  link.id = 'current-ember-eui-theme';
  link.dataset.theme = theme;

  if (window?.localStorage) {
    window.localStorage.setItem('theme', theme);
  }
  head.appendChild(link);
}
