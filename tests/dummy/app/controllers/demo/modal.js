import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalController extends Controller {
  @tracked basicModalActive = false;
  @tracked overflowModalActive = false;
  @tracked confirmModalActive = false;

	@action
	activateModal(modal) {
		this.set(modal, true)
  }

  @action
  deactivateModal(modal) {
    this.set(modal, false)
  }

}