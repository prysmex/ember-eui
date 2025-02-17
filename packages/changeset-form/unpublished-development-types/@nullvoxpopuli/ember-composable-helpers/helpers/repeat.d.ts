declare module '@nullvoxpopuli/ember-composable-helpers/helpers/repeat' {
  import Helper from '@ember/component/helper';

  export default class RepeatHelper extends Helper<{
    Args: {
      Positional: [num?: number];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: Array<any>;
  }> {}
}
