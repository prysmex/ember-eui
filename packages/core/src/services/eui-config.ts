import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { merge } from 'lodash-es';
import type { EuiButtonIconSignature } from '../components/eui-button-icon';

export interface EuiConfig {
  'euiIcon.useSvg'?: boolean;
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
