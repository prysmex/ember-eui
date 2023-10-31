declare module "ember-set-helper/helpers/set" {
  import Helper from "@ember/component/helper";

  export default class SetHelper<T extends unknown> extends Helper<{
    Args: {
      Positional: [ctx: T, str: string, value?: unknown];
    };
    Return: unknown;
  }> {}
}
