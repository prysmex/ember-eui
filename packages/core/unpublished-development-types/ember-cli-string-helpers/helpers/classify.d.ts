declare module "ember-cli-string-helpers/helpers/classify" {
  import Helper from "@ember/component/helper";

  export default class ClassifyHelper extends Helper<{
    Args: {
      Positional: [str: string];
    };
    Return: string;
  }> {}
}
