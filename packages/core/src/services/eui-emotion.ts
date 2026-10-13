import type {
  EuiBorealisOverrides,
  EuiHighContrastModeArg
} from '../utils/eui/theme.ts';
import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { EuiThemeContext } from '../utils/emotion/context.ts';

import type Owner from '@ember/owner';
import type {
  EuiColorMode,
  EuiThemeOverrides
} from '../utils/emotion/theme.ts';

/**
 * Owner-scoped defaults. Components rendered without any provider resolve
 * `colorMode` (`'light'` when unset) and `highContrastMode` (`false` when
 * unset) from here. A root `EuiEmotionProvider` whose own args are unset
 * uses these when set, and otherwise follows the OS preferences
 * (`prefers-color-scheme`, `prefers-contrast`, `forced-colors`).
 */
export default class EuiEmotionService extends Service {
  @tracked colorMode?: EuiColorMode;
  @tracked borealisOverrides: EuiBorealisOverrides = {};
  @tracked highContrastMode?: EuiHighContrastModeArg;
  @tracked overrides: EuiThemeOverrides = {};

  readonly context = new EuiThemeContext(() => ({
    colorMode: this.colorMode,
    overrides: this.overrides,
    borealisOverrides: this.borealisOverrides,
    highContrastMode: this.highContrastMode
  }));

  constructor(owner?: Owner) {
    super(owner);
    registerDestructor(this, () => this.context.destroy());
  }
}
