import Helper from '@ember/component/helper';
import type ThemeManager from 'site/services/theme-manager';
import { inject as service } from '@ember/service';

export default class GetCurrentTheme extends Helper {
  @service declare themeManager: ThemeManager;

  compute() {
    return this.themeManager.currentTheme;
  }
}
