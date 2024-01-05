import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import Service from '@ember/service';

import type { IEuiToast } from '../components/eui-toast';

export interface EuiToastProps extends IEuiToast {
  id?: string;
  toastLifeTimeMs?: number;
}

export default class EuiToasterService extends Service {
  @tracked toasts: (EuiToastProps & { id: string })[] = [];

  @action
  show(props: EuiToastProps): void {
    if (!props.id) {
      props.id = guidFor(props);
    }

    this.toasts = [...this.toasts, props as EuiToastProps & { id: string }];
  }

  @action
  remove(toastToRemove: EuiToastProps): void {
    this.toasts = this.toasts.filter((toast) => toast !== toastToRemove);
  }
}
