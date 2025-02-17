declare module '@nullvoxpopuli/ember-composable-helpers/helpers/pipe' {
  import Helper from '@ember/component/helper';

  export default class PipeHelper extends Helper<{
    Args: {
      Positional: [func?: Function];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: any;
  }> {}
}
