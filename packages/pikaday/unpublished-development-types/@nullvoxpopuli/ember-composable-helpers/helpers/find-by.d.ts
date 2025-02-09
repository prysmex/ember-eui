declare module '@nullvoxpopuli/ember-composable-helpers/helpers/find-by' {
  import Helper from '@ember/component/helper';

  export default class FindByHelper extends Helper<{
    Args: {
      Positional: [property: string, value: unknown, array?: unknown[]];
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Return: any;
  }> {}
}
