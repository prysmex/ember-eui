import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoModalController extends Controller {
	@tracked modalActive = false;

	@action
	activateModal() {
		this.modalActive = true;
  }

  @action
  deactivateModal() {
    this.modalActive = false;
  }

}