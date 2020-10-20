import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from 'ember-eui/utils/css-mappings/eui-icon';

const iconKeys = Object.keys(typeToPathMap);

export default class DemoIconController extends Controller {
	@tracked icon = 'tokenNumber';
	icons = iconKeys;

	@action
	update() {
		this.icon = this.icons[Math.floor(Math.random() * this.icons.length)]
	}

}