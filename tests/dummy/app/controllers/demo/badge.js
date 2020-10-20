import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconController extends Controller {
	@tracked disabled = false;

	@action
	toggleDisabled() {
		this.disabled = !this.disabled;
  }

  @action
  clickIcon() {
		console.log("ICON clicked!")
  }

  @action
  clickBadge() {
		console.log("BADGE TEXT clicked!")
	}

}