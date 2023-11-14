declare module 'ember-math-helpers/helpers/add' {
  import Helper from '@ember/component/helper';

  export default class AddHelper extends Helper<{
    Args: {
      Positional: [
        a: number | string | undefined,
        b: number | string | undefined
      ];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: number;
  }> {}
}
