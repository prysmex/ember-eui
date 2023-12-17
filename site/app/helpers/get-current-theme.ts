import Helper from '@ember/component/helper';
import { inject as service } from '@ember/service';

import type ThemeManager from 'site/services/theme-manager';

export default class GetCurrentTheme extends Helper {
  @service declare themeManager: ThemeManager;

  compute() {
    return this.themeManager.currentTheme;
  }
}
