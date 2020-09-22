import { helper } from '@ember/component/helper';
import { guidFor } from '@ember/object/internals';
import { isPresent } from '@ember/utils';

interface Identifiable {
  ref: number | string | Element | object;
};

/**
 * Returns a guid for the passed `ref`.
 * If no parameter was passed it will generate a random string and create a guid for it.
 *
 * @param { any } ref
 */
export function uniqueId ([], { ref }: { ref: Identifiable }): string {
  return isPresent(ref) ? guidFor(ref) : guidFor({});
}

export default helper(uniqueId);
