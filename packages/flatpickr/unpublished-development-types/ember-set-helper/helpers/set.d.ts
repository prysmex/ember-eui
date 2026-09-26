declare module 'ember-set-helper/helpers/set' {
  import Helper from '@ember/component/helper';
  import { set } from '@ember/object';

  export default class SetHelper<
    T,
    K extends keyof T,
    V
  > extends Helper<{
    Args: {
      Positional: [ctx: T, str: K, value?: V];
    };
    Return: () => ReturnType<typeof set<T, K>> ;
  }> {}
}
