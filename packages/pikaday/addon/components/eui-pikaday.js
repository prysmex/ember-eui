import Component from '@ember/component';
// eslint-disable-next-line
import PikadayMixin from 'ember-pikaday/mixins/pikaday';
import { isEmpty } from '@ember/utils';
import { action } from '@ember/object';
import { tagName, layout } from '@ember-decorators/component';
import template from '../templates/components/eui-pikaday';

const defaultFormat = 'YYYY-MM-DD';

@tagName('')
@layout(template)
export default class EuiPikaday extends Component.extend(PikadayMixin) {
  useUtc = false;
  yearRange = '1930,currentYear';
  useISODate = false;
  format = defaultFormat;

  init() {
    this.set('format', this.getDateFormat());
    super.init(...arguments);
  }

  getDateFormat() {
    return this.format || defaultFormat;
  }

  @action
  didInsertInput(input) {
    if (this.isDestroyed) {
      return;
    }
    this.set('field', input);
    this.setupPikaday();
  }

  /*
    destroy component and set the field to null
  */
  willDestroyElement() {
    if (this.isDestroyed) {
      return;
    }
    super.willDestroyElement(...arguments);
    this.pikaday.destroy();
    this.set('field', null);
  }

  /*
    We convert selected date to correct format
  */
  getSelectedDate() {
    var selectedDate = this.pikaday.getDate();

    if (this.useUTC) {
      selectedDate = this.moment
        .utc([
          selectedDate.getFullYear(),
          selectedDate.getMonth(),
          selectedDate.getDate()
        ])
        .toDate();
    }
    return selectedDate;
  }

  userSelectedDate() {
    let selectedDate = this.getSelectedDate();
    this.onSelection?.(selectedDate);
  }

  onPikadayOpen() {
    this.onOpen();
  }

  onPikadayClose() {
    if (this.isDestroyed || this.isDestroying) {
      return;
    }

    if (this.pikaday.getDate() === null || isEmpty(this.field.value)) {
      this.onSelection(null);
    }

    this.onClose();
  }
}
