import { helper } from '@ember/component/helper';

import { merge } from 'lodash-es';

export default helper(function (
  hashes: Array<Record<string, unknown>>,
  hash: Record<string, unknown> = {}
) {
  return merge({}, ...hashes, hash);
});
