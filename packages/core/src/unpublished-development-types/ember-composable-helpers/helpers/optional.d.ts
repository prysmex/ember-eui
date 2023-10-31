declare module 'ember-composable-helpers/helpers/optional' {
  import Helper from '@ember/component/helper';

  export default class OptionalHelper<T extends Function> extends Helper<{
    Args: {
      Positional: [func?: T];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: T | (() => void);
  }> {}
}
