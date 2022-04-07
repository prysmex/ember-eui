//@ts-ignore
import { registerLibrary } from '@ember-eui/core/version';
// import 'ember-basic-dropdown/vendor/ember-basic-dropdown.css';
// import '@elastic/eui/dist/eui_theme_amsterdam_light.css';

export function initialize(): void {
  registerLibrary();
}

export default {
  initialize
};
