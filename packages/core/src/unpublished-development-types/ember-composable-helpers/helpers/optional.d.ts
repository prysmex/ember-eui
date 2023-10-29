declare module 'ember-composable-helpers/helpers/optional' {
  import Helper from '@ember/component/helper';

  export default class OptionalHelper extends Helper<{
    Args: {
      Positional: [func?: Function];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: any;
  }> {}
}
