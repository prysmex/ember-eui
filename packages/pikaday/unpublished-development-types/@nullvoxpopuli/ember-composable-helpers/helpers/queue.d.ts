declare module '@nullvoxpopuli/ember-composable-helpers/helpers/queue' {
  import Helper from '@ember/component/helper';

  export default class QueueHelper extends Helper<{
    Args: {
      Positional: [...((...args: any[]) => unknown)[]];
    };
     
    Return: any;
  }> {}
}
