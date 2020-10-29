import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconController extends Controller {
	@tracked disabled = false;
	@tracked lightsaberDisabled = true;

	@action
	toggleDisabled() {
		this.disabled = !this.disabled;
	}

	@action
	toggleLightsaber() {
		this.lightsaberDisabled = !this.lightsaberDisabled;
  }

  @action
  clickIcon() {
		alert('ICON clicked!');
  }

  @action
  clickBadge() {
		alert('BADGE TEXT clicked!');
	}

}