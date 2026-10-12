import { deprecate } from '@ember/debug';

/**
 * Reports a public export that nothing in @ember-eui/core uses since the
 * Borealis (EUI 123) migration. It keeps working until it is removed in
 * 16.0.0. Fires at use, in development builds only.
 *
 * @param name the export's file name, e.g. `get-range-tick`; the
 *   deprecation id is `ember-eui.<name>.unused-after-borealis`.
 * @param message what is deprecated and what to use instead.
 * @param test passing `true` skips the deprecation (as `deprecate()`).
 */
export function deprecateUnusedAfterBorealis(
  name: string,
  message: string,
  test = false
): void {
  deprecate(
    `${message} It is unused since the Borealis migration and will be removed from @ember-eui/core in the next major (16.0.0).`,
    test,
    {
      id: `ember-eui.${name}.unused-after-borealis`,
      for: '@ember-eui/core',
      since: { available: '15.0.0', enabled: '15.0.0' },
      until: '16.0.0'
    }
  );
}
