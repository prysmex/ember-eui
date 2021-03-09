import Service from '@ember/service';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';

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
  toasts: EuiToastProps[] = A();

  @action
  show(props: EuiToastProps) {
    if (!props.id) {
      props.id = guidFor(props);
    }
    this.toasts.pushObject(props);
  }
}