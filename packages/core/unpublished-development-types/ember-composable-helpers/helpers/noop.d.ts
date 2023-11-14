declare module 'ember-composable-helpers/helpers/noop' {
  import Helper from '@ember/component/helper';

  export default class NoopHelper extends Helper<{
    Args: {
      Positional: [func?: Function];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: any;
  }> {}
}
