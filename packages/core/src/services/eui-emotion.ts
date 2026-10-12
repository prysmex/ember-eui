import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
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

/** Owner-scoped defaults for the experimental Emotion components. */
export default class EuiEmotionService extends Service {
  @tracked colorMode: EuiColorMode = 'light';
  @tracked borealisOverrides: EuiBorealisOverrides = {};
  @tracked highContrastMode: EuiBorealisHighContrastMode = false;
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
