import Component from '@glimmer/component';

import type { ComponentLike } from '@glint/template';

/**
 * What a React `ReactNode` arg becomes in an arg that cannot take a block
 * (e.g. a field of an item in an array): text, or a component to render.
 */
export type EuiNodeValue = string | number | ComponentLike<any> | null | undefined;

interface EuiNodeSignature {
  Args: { value: EuiNodeValue };
}

/** @private Renders a string, a number or a component passed as data. */
export default class EuiNode extends Component<EuiNodeSignature> {
  get text(): string | number | undefined {
    const { value } = this.args;
    return typeof value === 'string' || typeof value === 'number'
      ? value
      : undefined;
  }

  get component(): ComponentLike<any> | undefined {
    const { value } = this.args;
    return typeof value === 'string' || typeof value === 'number'
      ? undefined
      : (value ?? undefined);
  }

  <template>
    {{#if this.component}}<this.component />{{else}}{{this.text}}{{/if}}
  </template>
}
