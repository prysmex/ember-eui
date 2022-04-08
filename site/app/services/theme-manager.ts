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
      name: 'Amsterdam Light',
      key: 'amsterdam_light'
    },
    {
      name: 'Amsterdam Dark',
      key: 'amsterdam_dark'
    },
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
    this.currentTheme =
      this.themes.findBy('key', window?.localStorage?.getItem('theme')) ||
      this.themes[0];
  }

  changeTheme = (theme: ThemeShape) => {
    if (theme.key !== this.currentTheme?.key) {
      changeTheme(theme.key);
      this.currentTheme = theme;
    }
  };
}

// DO NOT DELETE: this is how TypeScript knows how to look up your services.
declare module '@ember/service' {
  interface Registry {
    'theme-manager': ThemeManager;
  }
}
