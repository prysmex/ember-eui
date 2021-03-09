import Service from '@ember/service';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { tracked } from '@glimmer/tracking';

type ToastColor = 'primary' | 'success' | 'warning' | 'danger';

export interface EuiToastProps {
  id: string;
  title: string;
  color?: ToastColor;
  iconType?: string;
  toastLifeTimeMs?: number;
  onClose?: () => void;
}

export default class EuiToasterService extends Service {
  @tracked toasts: EuiToastProps[] = [];

  @action
  show(props: EuiToastProps) {
    if (!props.id) {
      props.id = guidFor(props);
    }
    this.toasts = [
      ...this.toasts,
      props
    ]
  }

  @action
  remove(toastToRemove: EuiToastProps) {
    this.toasts = this.toasts.filter((toast) => toast !== toastToRemove);
  }
}
