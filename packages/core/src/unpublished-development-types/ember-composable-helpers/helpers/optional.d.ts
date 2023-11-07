declare module 'ember-composable-helpers/helpers/optional' {
  import Helper from '@ember/component/helper';

  export default class OptionalHelper<T> extends Helper<{
    Args: {
      Positional: [func?: T];
    };
    Return: T | (() => void);
  }> {}
}
