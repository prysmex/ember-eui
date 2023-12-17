import Helper from '@ember/component/helper';
import { inject as service } from '@ember/service';

import type EuiConfigService from '../services/eui-config';
import type { EuiConfig } from '../services/eui-config';

export interface GetEuiConfigSignature<T extends keyof EuiConfig> {
  Args: {
    Positional: [T];
  };
  Returns: EuiConfig[T];
}

export default class GetEuiConfig<T extends keyof EuiConfig> extends Helper<
  GetEuiConfigSignature<T>
> {
  @service declare euiConfig: EuiConfigService;

  compute([key]: [T]) {
    return this.euiConfig.getConfig(key);
  }
}
