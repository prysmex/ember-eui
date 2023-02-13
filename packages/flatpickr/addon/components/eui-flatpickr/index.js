import EmberFlatpickr from 'ember-flatpickr/components/ember-flatpickr';
import { action } from '@ember/object';

export default class EuiFlatpickrComponent extends EmberFlatpickr {
  @action
  onClear() {
    this.args.clear(null);
  }
}
