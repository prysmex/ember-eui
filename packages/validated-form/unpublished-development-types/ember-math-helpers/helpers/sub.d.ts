declare module 'ember-math-helpers/helpers/sub' {
  import Helper from '@ember/component/helper';

  export default class SubHelper extends Helper<{
    Args: {
      Positional: [a: number, b: number];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: number;
  }> {}
}
