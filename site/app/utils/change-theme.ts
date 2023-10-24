let hasLoaded = false;

export async function changeTheme(theme: string) {
  if (hasLoaded) {
    window.location.href = `?theme=${theme}`;
  }

  const currentStylesheet = document.getElementById(
    'current-ember-eui-theme'
  ) as HTMLStyleElement;

  if (currentStylesheet?.dataset?.theme === theme) {
    return;
  }

  if (theme === 'dark') {
    //@ts-expect-error
    await import('@ember-eui/core/themes/dark.css');
  } else {
    //@ts-expect-error
    await import('@ember-eui/core/themes/light.css');
  }

  const styleSheet = document.querySelector(
    'style:last-of-type'
  ) as HTMLStyleElement;

  styleSheet.id = 'current-ember-eui-theme';
  styleSheet.dataset.theme = theme;
  styleSheet.disabled = false;

  if (window?.localStorage) {
    window.localStorage.setItem('theme', theme);
  }
  hasLoaded = true;
}
