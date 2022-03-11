import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class EuiPikadayComponent extends Component {
  field = null;

  get format() {
    return this.args.format || 'DD.MM.YYYY';
  }

  get value() {
    return this.args.value;
  }

  get yearRange() {
    const yearRange = this.args.yearRange;
    if (!yearRange) {
      return 10;
    }
    if (yearRange.indexOf(',') > -1) {
      const yearArray = yearRange.split(',');
      if (yearArray[1] === 'currentYear') {
        yearArray[1] = new Date().getFullYear();
      }
      return yearArray;
    } else {
      return yearRange;
    }
  }

  get i18n() {
    let i18n = this.args.i18n;
    if (!i18n) {
      return undefined;
    }
    if (!i18n.t) {
      return i18n;
    }
    return {
      previousMonth: i18n.t('previousMonth').toString(),
      nextMonth: i18n.t('nextMonth').toString(),
      months: i18n.t('months').toString().split(','),
      weekdays: i18n.t('weekdays').toString().split(','),
      weekdaysShort: i18n.t('weekdaysShort').toString().split(',')
    };
  }

  get firstDay() {
    return this.args.firstDay == null ? 1 : parseInt(this.args.firstDay, 10);
  }

  @action
  registerField(field) {
    this.field = field;
  }

  @action
  registerPikaday(pikaday) {
    this.pikaday = pikaday;
    this.args.register?.(pikaday);
  }

  @action
  onClose() {
    if (this.isDestroying) {
      return;
    }
    if (!this.#heardValue) {
      this.onSelect(null);
    }
    this.args.onClose?.();
  }

  @action
  onOpen() {
    if (this.isDestroying) {
      return;
    }
    this.args.onOpen?.();
  }

  #heardValue;

  @action
  onDraw() {
    // this is here because apparently the classic behavior is to pass no
    // arguments to the onDraw callback, but Pikaday's own ownDraw has an
    // argument.
    this.args.onDraw?.();
  }

  @action
  didChange(event) {
    this.#heardValue = event.target.value;
  }

  @action
  onSelect(date) {
    this.args.onSelection?.(date);
  }
}
