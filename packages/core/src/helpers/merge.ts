import { helper } from '@ember/component/helper';

import { merge } from 'lodash-es';

/** Deep-merges objects (later ones win); `undefined` ones are skipped. */
export default helper(function (
  hashes: Array<object | undefined>,
  hash: object = {}
): Record<string, unknown> {
  return [...hashes, hash].reduce<Record<string, unknown>>(
    (merged, next) => (next ? merge(merged, next) : merged),
    {}
  );
});
