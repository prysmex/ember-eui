import Component from '@glimmer/component';
import { defineProperty } from '@ember/object';
import { localCopy } from 'tracked-toolbox';

interface EuiStateProviderArgs {
  [property: string]: unknown;
}

export default class EuiStateProvider extends Component<EuiStateProviderArgs> {
  [prop: string]: unknown;

  constructor (owner: unknown, args: EuiStateProviderArgs) {
    super(owner, args);

    Object.keys(args).forEach(prop => {
      let baseDescriptor = {
        writable: true,
        enumerable: true,
        value: args[prop]
      }
      let decoratedDescriptor = localCopy(`args.${prop}`)(baseDescriptor, prop);
      defineProperty(this, prop, decoratedDescriptor);

      this[`set${prop[0].toUpperCase() + prop.slice(1)}`] = (value: unknown): void => {
        this[prop] = value;
      }
    });
  }
}
