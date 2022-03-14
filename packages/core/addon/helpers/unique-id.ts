import { helper } from '@ember/component/helper';
import { guidFor } from '@ember/object/internals';
import { isPresent } from '@ember/utils';

interface Identifiable {
  ref: number | string | Element | Record<string, unknown>;
}

/**
 * Returns a guid for the passed `ref`.
 * The guid is stable, meaning that passing the same `ref` will yield the same guid.
 * If no parameter is passed it will generate the next available guid.
 *
 * @param { any } ref
 */
export function uniqueId(
  _?: any[],
  { ref }: { ref?: Identifiable } = {}
): string {
  return isPresent(ref) ? guidFor(ref) : guidFor({});
}

export default helper(uniqueId);
