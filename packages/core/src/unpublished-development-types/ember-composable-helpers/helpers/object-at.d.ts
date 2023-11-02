declare module 'ember-composable-helpers/helpers/object-at' {
  import Helper from '@ember/component/helper';

  export default class ObjectAtHelper<T> extends Helper<{
    Args: {
      Positional: [idx: number, obj: T[]];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: T
  }> {}
}
