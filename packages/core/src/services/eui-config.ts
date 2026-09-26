import { tracked } from '@glimmer/tracking';
import Service from '@ember/service';

import { merge } from 'lodash-es';

import type { EuiButtonIconSignature } from '../components/eui-button-icon';
import type { ComponentLike } from '@glint/template';

export interface EuiConfig {
  /**
   * Extra icons usable by name, e.g. `<EuiIcon @type="myLogo" />` or
   * `<EuiButton @iconType="myLogo">`. Values are components rendering an
   * `<svg>` with `...attributes`, for example svgs imported with
   * @svg-jar/plugin: `import MyLogo from './my-logo.svg';`
   */
  'euiIcon.icons'?: Record<
    string,
    ComponentLike<{ Element: SVGSVGElement; Blocks: { default: [] } }>
  >;
  /** @deprecated no longer has any effect, see `euiIcon.icons` */
  'euiIcon.useSvg'?: boolean;
  /** @deprecated no longer has any effect, see `euiIcon.icons` */
  euiIconUseSvg?: boolean;
  'euiButtonIcon.size'?: EuiButtonIconSignature['Args']['iconSize'];
  euiComboBoxOptionsHeight?: number;
}

const DEFAULT_CONFIG: EuiConfig = {
  'euiIcon.useSvg': true,
  euiIconUseSvg: true,
  euiComboBoxOptionsHeight: 33
};

export default class EuiConfigService extends Service {
  @tracked private _config: EuiConfig = DEFAULT_CONFIG;

  getConfig<T extends keyof EuiConfig>(key: T): EuiConfig[T] | undefined {
    return this._config[key];
  }

  updateConfig(config: Partial<EuiConfig>) {
    this._config = merge<Partial<EuiConfig>, EuiConfig, Partial<EuiConfig>>(
      {},
      this._config,
      config
    );
  }

  setConfig(config: EuiConfig) {
    this._config = config;
  }
}
