import { deprecate } from '@ember/debug';

/**
 * Reports a component that Elastic UI removed upstream (it is absent from
 * EUI 123). Call it from the component's constructor: it fires once per
 * rendered instance, in development builds only.
 *
 * @param fileName the component's file name, e.g. `eui-suggest`; the
 *   deprecation id is `ember-eui.<fileName>.removed-upstream`.
 * @param name the component's name, e.g. `EuiSuggest`.
 * @param alternative what to use instead, as a sentence.
 */
export function deprecateRemovedUpstream(
  fileName: string,
  name: string,
  alternative?: string
): void {
  deprecate(
    `${name} was removed from Elastic UI (EUI) upstream and will be removed from @ember-eui/core in the next major version.${
      alternative ? ` ${alternative}` : ''
    }`,
    false,
    {
      id: `ember-eui.${fileName}.removed-upstream`,
      for: '@ember-eui/core',
      since: { available: '14.2.0', enabled: '14.2.0' },
      until: '15.0.0'
    }
  );
}
