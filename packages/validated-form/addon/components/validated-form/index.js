import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { A } from '@ember/array';
import { schedule, next } from '@ember/runloop';

export default class ValidatedForm extends Component {
  @tracked childComponents = A([]);
  //cache to only notify if changed
  lastIsValid;
  lastIsTouched;

  get isValid() {
    return !this.isInvalid;
  }

  get isTouched() {
    return this.childComponents.isAny('isTouched');
  }

  get isInvalid() {
    return this.childComponents.isAny('isInvalid');
  }

  get isInvalidAndTouched() {
    return this.isInvalid && this.isTouched;
  }

  addChild(child) {
    this.childComponents.pushObject(child);
  }

  removeChild(child) {
    this.childComponents.removeObject(child);
  }

  @action
  handleSubmit(e) {
    e.preventDefault();
    if (this.isInvalid) {
      this.childComponents.setEach('isTouched', true);
      this.args.onInvalid?.();
    } else {
      this.childComponents.setEach('isTouched', false);
      this.args.onSubmit?.();
    }
  }

  @action
  handleReset(e) {
    e.preventDefault();
    this.args.onReset?.(e);
  }

  @action
  register(child) {
    if (!this.isDestroyed) {
      schedule('afterRender', this, this.addChild, child);
    }
  }

  @action
  unregister(child) {
    if (!this.isDestroyed) {
      schedule('afterRender', this, this.removeChild, child);
    }
  }

  @action
  updateValidity() {
    this.triggerValidityChange();
  }

  getIsValid() {
    return this.childComponents.isEvery('isValid');
  }

  getIsTouched() {
    return this.childComponents.isAny('isTouched');
  }

  triggerValidityChange() {
    const lastIsValid = this.isValid;
    const lastIsTouched = this.isTouched;

    if (
      lastIsValid !== this.getIsValid() ||
      lastIsTouched !== this.getIsTouched()
    ) {
      this.setNewValidity();
    }
  }

  @action
  setNewValidity() {
    next(() => {
      if (!this.isDestroying) {
        this.args.onValidityChange?.(
          this.isValid,
          this.isTouched,
          this.isInvalidAndTouched
        );
      }
    });
  }

  @action
  onChildValidityChange({ child, isValid, isTouched, isInvalidAndTouched }) {
    if (!this.isDestroying) {
      this.updateValidity({
        child,
        isValid,
        isTouched,
        isInvalidAndTouched
      });
    }
  }
}
