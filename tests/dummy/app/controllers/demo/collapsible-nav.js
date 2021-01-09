import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCollapsibleNavController extends Controller {

  @tracked collNavIsOpen = false;

  @action
  openCollapsibleNav() {
    this.collNavIsOpen = true;
  }

  @action
  closeCollapsibleNav() {
    this.collNavIsOpen = false;
  }
}