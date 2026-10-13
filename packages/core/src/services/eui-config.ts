import { tracked } from '@glimmer/tracking';
import Service from '@ember/service';

import { merge } from 'lodash-es';

import type { EuiButtonIconSignature } from '../components/eui-button-icon';
import type { ComponentLike } from '@glint/template';

/**
 * Defaults for components' props, like upstream `EuiProvider`'s
 * `componentDefaults` (app-wide here). Args passed to a component win.
 */
export interface EuiComponentDefaults {
  /**
   * Page size settings inherited by `EuiTablePagination` and every table
   * and grid built on it (`EuiBasicTable`, `EuiInMemoryTable`,
   * `EuiDataGrid`).
   */
  EuiTablePagination?: {
    itemsPerPage?: number;
    itemsPerPageOptions?: number[];
    showPerPageOptions?: boolean;
  };
}

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
  /**
   * Upstream `EuiProvider componentDefaults`, e.g.
   * `{ EuiTablePagination: { itemsPerPage: 25, itemsPerPageOptions: [25, 50, 100] } }`.
   * Set it with `setConfig` or a single `updateConfig` call: `updateConfig`
   * merges arrays by index into earlier values.
   */
  componentDefaults?: EuiComponentDefaults;
}

const DEFAULT_CONFIG: EuiConfig = {
  'euiIcon.useSvg': true,
  euiIconUseSvg: true,
  euiComboBoxOptionsHeight: 29
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
