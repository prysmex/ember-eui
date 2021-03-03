import Controller from "@ember/controller";
import {
  validatePresence,
  validateLength,
  validateConfirmation,
  validateFormat,
  validateNumber,
} from "ember-changeset-validations/validators";
import { action } from "@ember/object";

export const Validations = {
  firstName: [validatePresence(true), validateLength({ min: 4 })],
  lastName: validatePresence(true),
  rangeSlider1: validateNumber({ gte: 150 }),
  country: validatePresence(true),
  radioGroup: validatePresence(true),
  checkboxGroup: validatePresence(true),
  email: validateFormat({ type: "email" }),
  password: [validateLength({ min: 8 })],
  passwordConfirmation: validateConfirmation({ on: "password" }),
};

export default class ApplicationController extends Controller {
  Validations = Validations;

  model = {
    firstName: "Alberto",
    country: "",
    rangeSlider1: 150,
    lastName: "",
    checkboxGroup: ["checkbox-1"],
    email: "",
    password: "",
    passwordConfirmation: "",
  };

  @action
  validate({ newValue }: { newValue: string }) {
    return newValue?.length < 5 ? ["Value is too small "] : true;
  }
}
