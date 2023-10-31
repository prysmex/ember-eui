import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import Service from '@ember/service';

type ToastColor = 'primary' | 'success' | 'warning' | 'danger';

export interface EuiToastProps {
  id: string;
  title: string;
  color?: ToastColor;
  body?: string;
  iconType?: string;
  toastLifeTimeMs?: number;
  useMarkdownFormat?: boolean;
  onClose?: () => void;
}

export default class EuiToasterService extends Service {
  @tracked toasts: EuiToastProps[] = [];

  @action
  show(props: EuiToastProps): void {
    if (!props.id) {
      props.id = guidFor(props);
    }

    this.toasts = [...this.toasts, props];
  }

  @action
  remove(toastToRemove: EuiToastProps): void {
    this.toasts = this.toasts.filter((toast) => toast !== toastToRemove);
  }
}
