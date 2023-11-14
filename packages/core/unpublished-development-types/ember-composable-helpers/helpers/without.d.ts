declare module 'ember-composable-helpers/helpers/without' {
  import Helper from '@ember/component/helper';

  export default class WithoutHelper<T> extends Helper<{
    Args: {
      Positional: [ele: unknown, eles: T[]];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: T[];
  }> {}
}
