import Service from '@ember/service';
import { changeTheme } from '../utils/change-theme';
import { tracked } from '@glimmer/tracking';

type ThemeShape = {
  name: string;
  key: string;
};

export default class ThemeManager extends Service {
  @tracked currentTheme?: ThemeShape;

  themes: ThemeShape[] = [
    {
      name: 'Light',
      key: 'light'
    },
    {
      name: 'Dark',
      key: 'dark'
    }
  ];

  constructor(properties: Record<string, unknown>) {
    super(properties);
    const params = new URL(document.location.href).searchParams;
    const theme = params.get('theme');
    const currentTheme = theme || window?.localStorage?.getItem('theme');
    this.currentTheme =
      this.themes.findBy('key', currentTheme) || this.themes[0];
  }

  changeTheme = (theme: ThemeShape) => {
    if (theme.key !== this.currentTheme?.key) {
      this.currentTheme = theme;
      changeTheme(theme.key);
    }
  };
}

// DO NOT DELETE: this is how TypeScript knows how to look up your services.
declare module '@ember/service' {
  interface Registry {
    'theme-manager': ThemeManager;
  }
}
