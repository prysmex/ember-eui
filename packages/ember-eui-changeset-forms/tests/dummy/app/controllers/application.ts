import Controller from "@ember/controller";
import {
  validatePresence,
  validateLength,
  validateConfirmation,
  validateFormat,
} from "ember-changeset-validations/validators";
import { action } from "@ember/object";

export const Validations = {
  firstName: [validatePresence(true), validateLength({ min: 4 })],
  lastName: validatePresence(true),
  email: validateFormat({ type: "email" }),
  password: [validateLength({ min: 8 })],
  passwordConfirmation: validateConfirmation({ on: "password" })
};

export default class ApplicationController extends Controller {
	Validations = Validations;

	model = {
		firstName: 'Alberto',
		lastName: '',
		email: '',
		password: '',
		passwordConfirmation: ''
	}
	
  @action
  validate({ key, newValue, oldValue, changes, content }) {
    return newValue?.length < 5 ? ["Value is too small "] : true;
  }
}
