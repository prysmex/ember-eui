import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { registerDestructor } from '@ember/destroyable';
import { cancel, later } from '@ember/runloop';

import type Owner from '@ember/owner';

/**
 * Renders its content only after a delay, e.g. a loading indicator that
 * should not flash when loading is fast.
 */
export interface EuiDelayRenderSignature {
  Args: {
    /** Milliseconds to wait before rendering. Defaults to `500`. */
    delay?: number;
  };
  Blocks: {
    /** Rendered once the delay has passed. */
    default: [];
  };
}

export default class EuiDelayRender extends Component<EuiDelayRenderSignature> {
  @tracked isVisible = false;

  constructor(owner: Owner, args: EuiDelayRenderSignature['Args']) {
    super(owner, args);

    const timer = later(() => (this.isVisible = true), this.args.delay ?? 500);

    registerDestructor(this, () => cancel(timer));
  }

  <template>
    {{#if this.isVisible}}
      {{yield}}
    {{/if}}
  </template>
}
