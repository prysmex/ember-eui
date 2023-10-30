declare module "ember-set-helper/helpers/set" {
  import Helper from "@ember/component/helper";

  export default class SetHelper extends Helper<{
    Args: {
      Positional: [ctx: any, str: string, value?: unknown];
    };
    Return: unknown;
  }> {}
}
